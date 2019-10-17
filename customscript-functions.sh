function customGetRsyncSource () {
	local RSYNCSOURCE DISTRO
	DISTRO=$1
	RSYNCSOURCE=$( whiptail --backtitle "Distro = ${DISTRO}" --title "Set source url to rsync from" \
					--inputbox "Enter source rsync URL (in the form rsync://<url>, path is appended based on distro, so type accordingly :) )" \
					${LINES} ${COLUMNS} 3>&1 1>&2 2>&3 )
	echo "${RSYNCSOURCE}"
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
	RSYNCURL=$( customGetRsyncSource "${DISTRO}" )
	RSYNCPATH="${DISTRO}"
	RSYNCSOURCE="${RSYNCURL}/${RSYNCPATH}"

	MIRRORNAME="\$(hostname -f)"
	LOCKFILE="\"Archive-Update-in-Progress-\${MIRRORNAME}\""
	LOCK="\"\${BASEDIR}/\${DISTRO}\${LOCKFILE}\""

	DAY="\$(date | tr -s ' ' | tr ' ' '-' | cut -d '-' -f2,3,4,5)"
	LOGFILENAME="\"\${DISTRO}-rsync-\${DAY}.log\""
	LOGPATH="\"\${USERPATH}/log/\${DISTRO}/\${LOGFILENAME}\""

	BWLIMIT=$( getBandwidth "${DISTRO}" )
	RSYNC_BW="\"--bwlimit=\${BWLIMIT}\""

	RSYNC_DEFAULTS="\"-prltvHSB8192 --safe-links --info=progress2 --chmod=D755,F644 --stats --no-human-readable --no-inc-recursive\""

	STAGEONE_DEFAULTS="\"\""
	STAGEONE_EXTRA="\"$( getRsyncExtras 1 "${RSYNC_DEFAULTS}" "${DISTRO}" )\""
	STAGEONE_OPTIONS="\"\${RSYNC_DEFAULTS} \${STAGEONE_DEFAULTS} \${STAGEONE_EXTRA}\""

	STAGETWO_DEFAULTS="\"--delete --delete-after\""
	STAGETWO_EXTRA="\"$( getRsyncExtras 2 "${RSYNC_DEFAULTS}" "${DISTRO}" )\""
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
		echo -e "BASEDIR=\"${BASEDIR}/\${DISTRO}\""
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
