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
		CDIST=$(whiptail --backtitle "${BACKTITLE}" --title "Set Distro name" --nocancel --inputbox "Enter the name of the Linux Distribution for custom selection" \
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

function getBandwidth () {
	local BW DISTRO
	local DEF_BW=0
	DISTRO=$1
	BW=$( whiptail --backtitle "Distro = ${DISTRO}" --title "Set Rsync Bandwidth Limit" \
			--inputbox "Enter BW limit (KB)" ${LINES} ${COLUMNS} ${DEF_BW} 3>&1 1>&2 2>&3 )
	echo "${BW}"
}

function getRsyncExtras () {
	local STAGE MSG RSYNC_DEFAULTS DISTRO EXTRAS=""
	STAGE=$1
	RSYNC_DEFAULTS=$2
	DISTRO=$3

	MSG="Set Stage ${STAGE} Extra Options\nRemember, the following options are already default:\n ${RSYNC_DEFAULTS}"

	EXTRAS=$( whiptail  --backtitle "Distro = ${DISTRO}" --inputbox "${MSG}" \
				${LINES} ${COLUMNS} "${EXTRAS}" 3>&1 1>&2 2>&3 )
	echo "${EXTRAS}"
}
