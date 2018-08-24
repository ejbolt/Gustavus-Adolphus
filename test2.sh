#!/usr/bin/env bash

BACKTITLE="Deploying Mirrors"

function getBandwidth () {
	local BW
	local DEF_BW=0
	BW=$( whiptail --backtitle "${BACKTITLE}" --title "Set Rsync Bandwidth Limit" \
			--inputbox "Enter BW limit (KB)" ${LINES} ${COLUMNS} ${DEF_BW} 3>&1 1>&2 2>&3 )
	echo "${BW}"
}

function getRsyncSource () {
	local RSYNCSOURCE
	RSYNCSOURCE=$( whiptail --backtitle "${BACKTITLE}" --title "Set source url to rsync from" \
					--inputbox "Enter source rsync URL (either in the form rsync://<url>/<path> or <url>::<path>)" 
					${LINES} ${COLUMNS} 3>&1 1>&2 2>&3 )
	echo "${RSYNCSOURCE}"
}

function getArchIncExc () {
	local ARCH_OPT
	ARCH_OPT=$( whiptail --title "Architecture include/exclude" --radiolist \
			"Do you want to include or exclude certain architectures?" ${LINES} ${COLUMNS} $(( LINES -  8 )) \
			"Include" "Architectures to include" ON "Exclude" "Architectures to exclude" OFF 3>&1 1>&2 2>&3 )

	echo "${ARCH_OPT}"
}

function getArches () {
	local ARCHES MSG ARCHLIST OPTS ARCH_OPT
	ARCH_OPT=$1
	MSG="Select architectures to ${ARCH_OPT} (NOTE: check that the mirror you are syncing from has the ones you want; If you want to be an official mirror, you should (must) sync source as well"
	ARCHLIST="source amd64 arm64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mips64 mipsel powerpc ppc64el s390 s390x sparc"
	OPTS=()
	for i in $ARCHLIST
	do
		OPTS+=("$i" "" OFF)
	done

	ARCHES=$( whiptail --title "Architectures" --checklist \
			"${MSG}" ${LINES} ${COLUMNS} $(( LINES -  8 )) \
			"${OPTS[@]}" 3>&1 1>&2 2>&3 )

	echo "${ARCHES}"
}

function getUipSleep () {
	local UIPSLEEP
}

function getUipRetries () {
	local UIPRETRIES
}

function getLockTimeout () {
	local LOCKTIMEOUT
}

function genFtpSyncConfig () {
	# Make sure variables are local
	local BASEDIR DISTRO USERNAME USERPATH RSYNC_HOST
	local MIRRORNAME LOGDIR RSYNC_BW CONFIGFILE CONFIGPATH
	local ARCH_OPT ARCHES

	# Assign variables that were passed to function
	BASEDIR=$1
	DISTRO=$2
	USERNAME=$3
	USERPATH=$4

	# Build out variable assignments to match what script expects,
	# still maintain configurability
	MIRRORNAME="\$(hostname -f)"

	RSYNC_HOST=$( getRsyncSource )

	LOGDIR="${USERPATH}/log/${DISTRO}"

	RSYNC_BW=$( getBandwidth )

	ARCH_OPT=$( getArchIncExc )
	ARCHES=$( getArches "${ARCH_OPT}" )

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
		echo -e "TO=\"${BASEDIR}\""
		echo -e "# MAILTO=\"$LOGNAME\""
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
		echo -e "LOCK=\"${TO}/Archive-Update-in-Progress-${MIRRORNAME}\""
		echo "# how long before lock file expires"
		echo -e echo "LOCKTIMEOUT=${LOCKTIMEOUT}"
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

function main () {
	BASEDIR="/var/www/html"
	DISTRO="debian"
	USERNAME="archvsync"
	USERPATH="/home/${USERNAME}"

	eval "$(resize)"
	genFtpSyncConfig "${BASEDIR}" "${DISTRO}" "${USERNAME}" "${USERPATH}"
}

main