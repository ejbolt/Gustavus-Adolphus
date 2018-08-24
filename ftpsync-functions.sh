function installFtpsync () {
	local USERPATH
	USERPATH=$1
	sudo git clone https://salsa.debian.org/mirror-team/archvsync.git/ "/home/${MIRRORUSER}/archvsync"
	sudo cp -r "/home/${MIRRORUSER}/archvsync/{bin,etc}" "/home/${MIRRORUSER}/."
}

