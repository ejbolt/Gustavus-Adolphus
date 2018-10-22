function installFtpsync () {
	local USERPATH
	USERPATH=$1
	sudo git clone https://salsa.debian.org/mirror-team/archvsync.git/ "/home/${MIRRORUSER}/archvsync"
	sudo cp -r "/home/${MIRRORUSER}/archvsync/bin" "/home/${MIRRORUSER}/."
	sudo cp -r "/home/${MIRRORUSER}/archvsync/etc" "/home/${MIRRORUSER}/."	
}

function ftpsyncGetRsyncSource () {
	local RSYNCSOURCE DISTRO
	DISTRO=$1
	RSYNCSOURCE=$( whiptail --backtitle "Distro = ${DISTRO}" --title "Set source url to rsync from" \
					--inputbox "Enter source rsync URL, without rsync://, ftpsync uses the format <url>::<path>" \
					${LINES} ${COLUMNS} 3>&1 1>&2 2>&3 )
	echo "${RSYNCSOURCE}"
}

function getArchIncExc () {
	local ARCH_OPT DISTRO
	DISTRO=$1
	ARCH_OPT=$( whiptail --backtitle "Distro = ${DISTRO}" --title "Architecture include/exclude" --radiolist \
			"Do you want to include or exclude certain architectures? for distro:${DISTRO}" ${LINES} ${COLUMNS} $(( LINES -  8 )) \
			"include" "Architectures to include" ON "exclude" "Architectures to exclude" OFF 3>&1 1>&2 2>&3 )

	echo "${ARCH_OPT}"
}

function getArches () {
	local ARCHES MSG ARCHLIST OPTS ARCH_OPT CHOICES DISTRO
	ARCH_OPT=$1
	DISTRO=$2
	MSG="Select architectures to ${ARCH_OPT} (NOTE: check that the mirror you are syncing from has the ones you want; If you want to be an official mirror, you should (must) sync source as well"
	ARCHLIST="source amd64 arm64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mips64 mipsel powerpc ppc64el s390 s390x sparc"
	
	OPTS=()
	ARCHES=()
	for i in $ARCHLIST
	do
		OPTS+=("$i" "" OFF)
	done

	eval "$(resize)"
	CHOICES=$( whiptail --backtitle "Distro = ${DISTRO}" --title "Architectures" --checklist --separate-output \
			"${MSG}" ${LINES} ${COLUMNS} $(( LINES -  8 )) \
			"${OPTS[@]}" 3>&1 1>&2 2>&3 )

	for ARCH in $CHOICES
	do
		ARCHES+=("${ARCH}")
	done

	echo "${ARCHES[@]}"
}

function getUipSleep () {
	local UIPSLEEP DEF_SLEEP DISTRO
	DISTRO=$1
	DEF_SLEEP=900
	UIPSLEEP=$( whiptail --backtitle "Distro = ${DISTRO}" --title "Set UIPSLEEP" \
					--inputbox "Enter value for UIPSLEEP (uses sleep command, value is in seconds... EX: 900 = 15 minutes" \
					${LINES} ${COLUMNS} ${DEF_SLEEP} 3>&1 1>&2 2>&3 )
	echo "${UIPSLEEP}"
}

function getUipRetries () {
	local UIPRETRIES DEF_RETRIES DISTRO
	DISTRO=$1
	DEF_RETRIES=10
	UIPRETRIES=$( whiptail  --backtitle "Distro = ${DISTRO}" --title "Set UIPRETRIES" \
					--inputbox "Enter number of times to retry syncing if first attempt fails" \
					${LINES} ${COLUMNS} ${DEF_RETRIES} 3>&1 1>&2 2>&3 )
	echo "${UIPSLEEP}"
}

function getLockTimeout () {
	local LOCKTIMEOUT DEF_LOCKTIMEOUT DISTRO
	DISTRO=$1
	DEF_LOCKTIMEOUT=3600
	LOCKTIMEOUT=$( whiptail --backtitle "Distro = ${DISTRO}" --title "Set LOCKTIMEOUT" \
					--inputbox "Enter time for how long your lock file will remain in place  for distro:${DISTRO}.  This prevents a sync from starting while one is already in progress." \
					${LINES} ${COLUMNS} ${DEF_LOCKTIMEOUT} 3>&1 1>&2 2>&3 )
	echo "${LOCKTIMEOUT}"
}

function genFtpSyncConfig () {
	# Make sure variables are local
	local BASEDIR DISTRO USERNAME USERPATH RSYNC_HOST
	local MIRRORNAME LOGDIR RSYNC_BW CONFIGFILE CONFIGPATH
	local ARCH_OPT ARCHES
	local UIPSLEEP UIPRETRIES LOCKTIMEOUT

	# Assign variables that were passed to function
	BASEDIR=$1
	DISTRO=$2
	USERNAME=$3
	USERPATH=$4

	# Build out variable assignments to match what script expects,
	# still maintain configurability
	MIRRORNAME="\$(hostname -f)"

	RSYNC_HOST=$( ftpsyncGetRsyncSource "${DISTRO}" )

	LOGDIR="${USERPATH}/log/${DISTRO}"

	RSYNC_BW=$( getBandwidth "${DISTRO}" )

	ARCH_OPT=$( getArchIncExc "${DISTRO}" )
	ARCHES=$( getArches "${ARCH_OPT}" "${DISTRO}" )

	UIPSLEEP=$( getUipSleep "${DISTRO}" )
	UIPRETRIES=$( getUipRetries "${DISTRO}" )

	LOCKTIMEOUT=$( getLockTimeout "${DISTRO}" )

	CONFIGFILE="ftpsync-${DISTRO}.conf"
	CONFIGPATH="${USERPATH}/etc/${CONFIGFILE}"
	sudo touch "${CONFIGPATH}"
	{
		echo "########################################################################"
		echo "########################################################################"
		echo "## This is a sample configuration file for the ftpsync mirror script. ##"
		echo "## Only options most users may need are included.  For documentation  ##"
		echo "## and all available options see ftpsync.conf(5).                     ##"
		echo "########################################################################"
		echo "########################################################################"
		echo ""
		echo -e "MIRRORNAME=${MIRRORNAME}"
		echo -e "TO=\"${BASEDIR}/${DISTRO}\""
		echo -e "# MAILTO=\"$USERNAME\""
		echo "# HUB=false"
		echo ""
		echo "########################################################################"
		echo "##Connection options"
		echo "########################################################################"
		echo ""
		echo "# rsync mirror URL, for example: debian.csail.mit.edu"
		echo -e "RSYNC_HOST=\"${RSYNC_HOST}\""
		echo -e "RSYNC_PATH=\"${DISTRO}\""  # <-- should just be the distro name"
		echo "# RSYNC_USER="
		echo "# RSYNC_PASSWORD="
		echo ""
		echo "########################################################################"
		echo "## Mirror information options"
		echo "########################################################################"
		echo ""
		echo -e "# INFO_MAINTAINER=\"Admins <admins@example.com>, Person <person@example.com>\""
		echo -e "# INFO_SPONSOR=\"Example <https://example.com>\""
		echo -e "# INFO_COUNTRY=DE"
		echo -e "# INFO_LOCATION=\"Example\""
		echo -e "# INFO_THROUGHPUT=10Gb"
		echo ""
		echo "########################################################################"
		echo "## Include and exclude options"
		echo "########################################################################"
		echo "# architectures to include/exclude.  If you are official, you should include 'source'."
		echo "# Also, you should only use ONE, INCLUDE, or EXCLUDE, not both.  Think of"
		echo "# whitelist or blacklist, respectively"
		echo ""
		if [[ "${ARCH_OPT}" == "include" ]]
		then
			echo "ARCH_INCLUDE=\"${ARCHES}\""
			echo "#ARCH_EXCLUDE=\"\""
		elif [[ "${ARCH_OPT}" == "exclude" ]]
		then
			echo "#ARCH_INCLUDE=\"\""
			echo "#ARCH_EXCLUDE=\"${ARCHES}\""
		fi
		echo ""
		echo "########################################################################"
		echo "## Log option"
		echo "########################################################################"
		echo "# path to log file"
		echo -e "LOGDIR=\"${LOGDIR}\""
		echo "########################################################################"
		echo "## Options for redundancy"
		echo "## Most of these variables have different defaults if you don't specify otherwise"
		echo "########################################################################"
		echo "# time for ftpsync to sleep before retrying (in seconds)"
		echo -e "UIPSLEEP=\"${UIPSLEEP}\""
		echo "# number of times to retry after failure"
		echo -e "UIPRETRIES=\"${UIPRETRIES}\""
		echo "# bandwidth limit in KB"
		echo "RSYNC_BW=${RSYNC_BW}"
		echo "# path to lock file; ensures if a sync is already in progress, another does not start"
		echo -e "LOCK=\"\${TO}/Archive-Update-in-Progress-${MIRRORNAME}\""
		echo "# how long before lock file expires"
		echo -e "LOCKTIMEOUT=${LOCKTIMEOUT}"
		echo "#The debian mirror status page and ftpsync require the tracefile to be UTC time"
		echo -e "TZ=\"UTC\""
		echo ""
		echo "########################################################################"
		echo "########################################################################"
		echo "## This is a sample configuration file for the ftpsync mirror script. ##"
		echo "## Only options most users may need are included.  For documentation  ##"
		echo "## and all available options see ftpsync.conf(5).                     ##"
		echo "########################################################################"
		echo "########################################################################"
	} | sudo tee -a "${CONFIGPATH}" 1>/dev/null
#	sudo tee -a "${CONFIGPATH}" 1>/dev/null
#	sudo tee -a "configtest.txt"
}
