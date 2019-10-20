#!/usr/bin/env bash

BACKTITLE="Deploying Mirrors"
TITLE="Choose Distros"
MENU="Choose which distros to mirror:"

function main () {

	BINDIR=$( dirname $(readlink -f "$0")) 1>/dev/null
	source "${BINDIR}/common-functions.sh" 1>/dev/null
	source "${BINDIR}/ftpsync-functions.sh" 1>/dev/null
	source "${BINDIR}/customscript-functions.sh" 1>/dev/null

	# list of distros script covers
	local -r DISTROS="archlinux centos debian freebsd kali manjaro netbsd openbsd qubes raspbian ubuntu voidlinux custom"
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
		if [[ "${DIST}" == "debian" || "${DIST}" == "kali" || "${DIST}" == "raspbian" || "${DIST}" == "ubuntu" ]]
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
		genFtpSyncConfig "${MIRRORDIR}" "${DIST}" "${MIRRORUSER}" "${USERPATH}"
	done

        sudo chown -R "${MIRRORUSER}:${MIRRORUSER}" "${USERPATH}"
        for DIST in "${INST_DISTS[@]}"
    	do
        	sudo chown -R "${MIRRORUSER}:${MIRRORUSER}" "${MIRRORDIR}/${DIST}"
    	done

	whiptail --backtitle "${BACKTITLE}" --textbox --title "Actions" msg.txt ${LINES} ${COLUMNS} 3>&1 1>&2 2>&3
}

main
