#!/usr/bin/env bash

BACKTITLE="Deploying Mirrors"
TITLE="Choose Distros"
MENU="Choose which distros to mirror:"

function exitCheck () {
	local EXIT_CODE=$1
	if (( EXIT_CODE == 1 ))
	then
		echo "Setup Cancelled" > msg.txt
		whiptail --textbox --title "Cancelled" msg.txt $LINES $COLUMNS
		rm msg.txt
		exit 1
	elif (( EXIT_CODE != 0 ))
	then
		rm msg.txt
	fi
}
trap exitCheck EXIT

function successCleanup () {
	local EXIT_CODE=$?
	if (( EXIT_CODE == 0 ))
	then
		rm msg.txt
	fi
}
trap successCleanup EXIT

function createUser () {
	local USERNAME="archvsync"
	USERNAME=$(whiptail --backtitle "${BACKTITLE}" --title "Create Mirror User" --nocancel \
						--inputbox "Enter name of mirrorsync user, default is archvsync" \
						${LINES} ${COLUMNS} ${USERNAME} 3>&1 1>&2 2>&3)
	local USERCHECK=
	USERCHECK=$(grep -c "^${USERNAME}" /etc/passwd)
	if (( USERCHECK == 0 ))
	then
		(sudo useradd -m "${USERNAME}" > msg.txt) && echo "User created" >> msg.txt
		sudo passwd -d archvsync >> msg.txt
	fi

	echo "${USERNAME}"
}

function getMirrorDir () {
	local BASEDIR="/var/www/html"
	BASEDIR=$(whiptail --backtitle "${BACKTITLE}" --title "Set Base directory" --nocancel --inputbox "Enter base directory path (e.g. /var/www/html/)" \
				${LINES} ${COLUMNS} ${BASEDIR} 3>&1 1>&2 2>&3)
	if [ ! -d "$DIRECTORY" ]
	then
		sudo mkdir -p "$BASEDIR"
	fi

	echo "${BASEDIR}"
}

function getDistro () {
	local CDIST
	while true
	do
		CDIST=$(whiptail --backtitle "${BACKTITLE}" --title "Set Distro name" --nocancel --inputbox "Enter the name of the Linux Distribution" \
					${LINES} ${COLUMNS} "${CDIST}" 3>&1 1>&2 2>&3)
		if [ -z "${CDIST}" ]
		then
			echo "Distro unset, please enter distro name" >> custmirror.txt
		else
			echo "Distro set to ${CDIST}" >> custmirror.txt
			break
		fi
		whiptail --backtitle "${BACKTITLE}" --textbox --title "Actions" custmirror.txt ${LINES} ${COLUMNS} 3>&1 1>&2 2>&3
	done
	rm custmirror.txt
	echo "${CDIST}"
}

function installFtpsync () {
	local USERPATH
	USERPATH=$1
	sudo git clone https://salsa.debian.org/mirror-team/archvsync.git/ "/home/${MIRRORUSER}/archvsync"
	sudo cp -r "/home/${MIRRORUSER}/archvsync/{bin,etc}" "/home/${MIRRORUSER}/."
	#echo "sudo git clone https://salsa.debian.org/mirror-team/archvsync/ ${USERPATH}/archvsync"
	#echo "sudo cp -r ${USERPATH}/archvsync/{bin,etc} ${USERPATH}/."
}

function createDistroDirs () {
	local BASEDIR
	local DISTRO
	local USERPATH
	BASEDIR=$1
	DISTRO=$2
	USERPATH=$3

	sudo mkdir -p "${BASEDIR}/${DISTRO}"
	sudo mkdir -p "${USERPATH}/${DISTRO}"
	sudo mkdir -p "${USERPATH}/log/${DISTRO}"
}

function getRsyncSource () {
	local RSYNCSOURCE
	RSYNCSOURCE=$( whiptail --backtitle "${BACKTITLE}" --title "Set source url to rsync from" \
					--inputbox "Enter source rsync URL (either in the form rsync://<url>/<path> or <url>::<path>)" \
					${LINES} ${COLUMNS} 3>&1 1>&2 2>&3 )
	echo "${RSYNCSOURCE}"
}

function getBandwidth () {
	local BW
	local DEF_BW=0
	BW=$( whiptail --backtitle "${BACKTITLE}" --title "Set Rsync Bandwidth Limit" \
			--inputbox "Enter BW limit (KB)" ${LINES} ${COLUMNS} ${DEF_BW} 3>&1 1>&2 2>&3 )
	echo "${BW}"
}

function getRsyncExtras () {
	local STAGE MSG RSYNC_DEFAULTS EXTRAS=""
	STAGE=$1
	RSYNC_DEFAULTS=$2

	MSG="Set Stage ${STAGE} Extra Options\nRemember, the following options are already default:\n ${RSYNC_DEFAULTS}"

	EXTRAS=$( whiptail --backtitle "${BACKTITLE}" --inputbox "${MSG}" \
				${LINES} ${COLUMNS} "${EXTRAS}" 3>&1 1>&2 2>&3 )
	echo "${EXTRAS}"
}

function genCustomConfig () {
	# Make sure variables are local
	local BASEDIR DISTRO USERNAME USERPATH
	local CONFIGFILE RSYNCSOURCE MIRRORNAME LOCKFILE LOCK
	local DAY LOGFILENAME LOGPATH BWLIMIT RSYNC_BW RSYNC_DEFAULTS
	local STAGEONE_DEFAULTS STAGEONE_EXTRA STAGEONE_OPTIONS
	local STAGETWO_DEFAULTS STAGETWO_EXTRA STAGETWO_OPTIONS

	# Assign variables that were passed to function
	BASEDIR=$1
	DISTRO=$2
	USERNAME=$3
	USERPATH=$4

	# Build out variable assignments to match what script expects,
	# still maintain configurability
	# source URL for rsync
	RSYNCSOURCE=$( getRsyncSource )

	MIRRORNAME="\$(hostname -f)"
	LOCKFILE="\"Archive-Update-in-Progress-\${MIRRORNAME}\""
	LOCK="\"\${BASEDIR}/\${DISTRO}\${LOCKFILE}\""

	DAY="\$(date | tr -s ' ' | tr ' ' '-' | cut -d '-' -f2,3,4)"
	LOGFILENAME="\"\${DISTRO}-rsync-\${DAY}.log\""
	LOGPATH="\"\${USERPATH}/log/\${DISTRO}/\${LOGFILENAME}\""

	BWLIMIT=$( getBandwidth )
	RSYNC_BW="\"--bwlimit=\${BWLIMIT}\""

	RSYNC_DEFAULTS="\"-prltvHSB8192 --safe-links --info=progress2 --chmod=D755,F644 --stats --no-human-readable --no-inc-recursive\""

	STAGEONE_DEFAULTS="\"\""
	STAGEONE_EXTRA="\"$( getRsyncExtras 1 "${RSYNC_DEFAULTS}" )\""
	STAGEONE_OPTIONS="\"\${RSYNC_DEFAULTS} \${STAGEONE_DEFAULTS} \${STAGEONE_EXTRA}\""

	STAGETWO_DEFAULTS="\"--delete --delete-after\""
	STAGETWO_EXTRA="\"$( getRsyncExtras 2 "${RSYNC_DEFAULTS}" )\""
	STAGETWO_OPTIONS="\"\${RSYNC_DEFAULTS} \${STAGETWO_DEFAULTS} \${STAGETWO_EXTRA}\""

	# config file name and path
	CONFIGFILE="${DISTRO}-rsync.conf"
	CONFIGPATH="${USERPATH}/${DISTRO}/${CONFIGFILE}"

	# script file name and path
	SCRIPTFILE="${DISTRO}-rsync.sh"
	SCRIPTPATH="${USERPATH}/${DISTRO}/${SCRIPTFILE}"

	# get script
	sudo wget -O "${SCRIPTPATH}" https://raw.githubusercontent.com/ejbolt/LinuxMirrorScripts/master/generic/mirror.sh

	# Set DISTRO variable in script.  This is needed to get the config file path.  Everything else will build off what is in the config file.
	sudo sed -i 's/DISTRO=/DISTRO='\""${DISTRO}"'\"/' "${SCRIPTPATH}"

	sudo touch "${CONFIGPATH}"
	{
		echo "#===================================================================================="
		echo "#Variables Needed for config file to have the right values"
		echo "#===================================================================================="
		echo -e "DISTRO=\"${DISTRO}\""
		echo "# Source and Destination of rsync"
		echo "# rsync host URL"
		echo -e "RSYNCSOURCE=\"${RSYNCSOURCE}\""
		echo "# Path to mirror directory, example: /var/www/html/${DISTRO}"
		echo -e "BASEDIR=\"${BASEDIR}\""
		echo "# mirror user and path to their home directory"
		echo -e "USERNAME=\"${USERNAME}\""
		echo -e "USERPATH=\"${USERPATH}\""
		echo "#===================================================================================="
		echo -e "\n"
		echo "#===================================================================================="
		echo "#Variables that come standard in the config, most shouldn't need to be adjusted"
		echo "#===================================================================================="
		echo "# use host name in Lockfile name, credit to Debian's ftpsync tool for the idea,"
		echo "# as they do the same thing"
		echo -e "MIRRORNAME=${MIRRORNAME}"
		echo -e "LOCKFILE=${LOCKFILE}"
		echo -e "LOCK=${LOCK}"
		echo ""
		echo "# variables for logging, if you want the script to just print to the screen, you can set LOGPATH=\"/dev/stdout\""
		echo -e "DAY=${DAY}"
		echo -e "LOGFILENAME=${LOGFILENAME}"
		echo -e "LOGPATH=${LOGPATH}"
		echo ""
		echo "# set rsync bandwidth in KB, 0 means unlimited"
		echo -e "BWLIMIT=${BWLIMIT}"
		echo -e "RSYNC_BW=${RSYNC_BW}"
		echo "#===================================================================================="
		echo -e "\n"
		echo "#===================================================================================="
		echo "# rsync options, advised to leave defaults, anything else add to EXTRA in the appropriate stage"
		echo "#===================================================================================="
		echo "# Options for both rsync stages.  Defaults are known to work and several are included in the Debian rsync tool defaults or ubuntu/centos scripts"
		echo -e "RSYNC_DEFAULTS=${RSYNC_DEFAULTS}"
		echo "# Options for first stage sync.  Defaults are known to work and several are included in the Debian rsync tool defaults or ubuntu/centos scripts"
		echo -e "STAGEONE_DEFAULTS=${STAGEONE_DEFAULTS}"
		echo -e "STAGEONE_EXTRA=${STAGEONE_EXTRA}"
		echo -e "STAGEONE_OPTIONS=${STAGEONE_OPTIONS}"
		echo "# Options for second stage sync.  Defaults are known to work and several are included in the Debian rsync tool defaults or ubuntu/centos scripts, deletions should happen here."
		echo -e "STAGETWO_DEFAULTS=${STAGETWO_DEFAULTS}"
		echo -e "STAGETWO_EXTRA=${STAGETWO_EXTRA}"
		echo -e "STAGETWO_OPTIONS=${STAGETWO_OPTIONS}"
		echo "#===================================================================================="
	} | sudo tee -a "${CONFIGPATH}" 1>/dev/null
	sudo chmod +x "${SCRIPTPATH}"
}

#function genFtpSyncConfig () {
#	#sudo touch "/home/${MIRRORUSER}/etc/ftpsync-${DISTRONAME}".conf
#}

function main () {

	# list of distros script covers
	local -r DISTROS="centos debian kali raspbian ubuntu custom"
	# Options for dialog menu list
	local OPTIONS=()

	# Load options
	for d in $DISTROS
	do
		OPTIONS+=("$d" "" off)
	done

	eval "$(resize)"
	CHOICES=$( whiptail --backtitle "${BACKTITLE}" --title "${TITLE}" \
					--checklist --separate-output "$MENU" ${LINES} ${COLUMNS} \
					$(( LINES -  8 )) "${OPTIONS[@]}" 3>&1 1>&2 2>&3 )

	# create mirror sync user
	local MIRRORUSER
	MIRRORUSER=$(createUser)
	# get user home dir path
	local USERPATH
	USERPATH=$(cat < /etc/passwd | grep "${MIRRORUSER}" | cut -d ':' -f 6)
	# get path where mirrors will live
	local MIRRORDIR
	MIRRORDIR=$(getMirrorDir)

	{
		echo "MIRRORUSER = ${MIRRORUSER}"
		echo "USERPATH = ${USERPATH}"
		echo "MIRRORDIR = ${MIRRORDIR}"
	} >> msg.txt


	local FTPSYNC_NEEDED=0
	local CUSTDIST_SET=0
	for i in $CHOICES
	do
		if [[ "$i" == "debian" || "$i" == "kali" || "$i" == "raspbian" ]]
		then
			FTPSYNC_NEEDED=1
		elif [[ "$i" == "custom" ]]
		then
			CUSTDIST_SET=1
		fi
	done

	# check if we need ftpsync
	if (( FTPSYNC_NEEDED == 1 ))
	then
		if [[ ! -f /home/${MIRRORUSER}/bin/ftpsync ]]
		then
			echo "ftpsync is not installed, but needed by one or more selected distros" >> msg.txt
			installFtpsync "${USERPATH}"
		fi
	fi

	# check if we need a name for the custom distro (only doing one custom distro at a time)
	if (( CUSTDIST_SET == 1 ))
	then
		CUSTOM_DIST=$(getDistro)
		echo "Custom Distro = $CUSTOM_DIST" >> msg.txt
	fi

	# array of selected distros to install
	local INST_DISTS=()
	for DIST in $CHOICES
	do
		if [[ "${DIST}" == "custom" ]]
		then
			INST_DISTS+=("${CUSTOM_DIST}")
		else
			INST_DISTS+=("${DIST}")
		fi
	done

	echo "Distros to install: " >> msg.txt
	for DIST in "${INST_DISTS[@]}"
	do
		echo "		${DIST}" >> msg.txt
	done

	for DIST in "${INST_DISTS[@]}"
	do
		createDistroDirs "${MIRRORDIR}" "${DIST}" "${USERPATH}"
	done

	local CUST_INST_DISTS=()
	local FS_INST_DISTS=()

	for DIST in "${INST_DISTS[@]}"
	do
		if [[ "${DIST}" == "debian" || "${DIST}" == "kali" || "${DIST}" == "raspbian" ]]
		then
			FS_INST_DISTS+=("${DIST}")
		elif [[ "${DIST}" == "custom" ]]
		then
			CUST_INST_DISTS+=("${CUSTOM_DIST}")
		else
			CUST_INST_DISTS+=("${DIST}")
		fi
	done

	for DIST in "${CUST_INST_DISTS[@]}"
	do
		genCustomConfig "${MIRRORDIR}" "${DIST}" "${MIRRORUSER}" "${USERPATH}"
	done

	for DIST in "${FS_INST_DISTS[@]}"
	do
		genFtpSyncConfig "${MIRRORDIR}" "${DIST}" "${USERPATH}"
	done

	sudo chown -R "${MIRRORUSER}:${MIRRORUSER}" "${USERPATH}"
	sudo chown -R "${MIRRORUSER}:${MIRRORUSER}" "${MIRRORDIR}"

	whiptail --backtitle "${BACKTITLE}" --textbox --title "Actions" msg.txt ${LINES} ${COLUMNS} 3>&1 1>&2 2>&3
}

main
