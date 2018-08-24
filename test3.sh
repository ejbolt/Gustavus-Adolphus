#!/usr/bin/env bash

function getArchIncExc () {
	local ARCH_OPT
	ARCH_OPT=$( whiptail --title "Architecture include/exclude" --radiolist \
			"Do you want to include or exclude certain architectures?" ${LINES} ${COLUMNS} $(( LINES -  8 )) \
			"include" "Architectures to include" ON "exclude" "Architectures to exclude" OFF 3>&1 1>&2 2>&3 )

	echo "${ARCH_OPT}"
}

function getArches () {
	local ARCHES MSG ARCHLIST OPTS ARCH_OPT CHOICES
	ARCH_OPT=$1
	MSG="Select architectures to ${ARCH_OPT} (NOTE: check that the mirror you are syncing from has the ones you want; If you want to be an official mirror, you should (must) sync source as well"
	ARCHLIST="source amd64 arm64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mips64 mipsel powerpc ppc64el s390 s390x sparc"
	OPTS=()
	ARCHES=()
	for i in $ARCHLIST
	do
		OPTS+=("$i" "" OFF)
	done

	eval "$(resize)"
	CHOICES=$( whiptail --title "Architectures" --checklist --separate-output \
			"${MSG}" ${LINES} ${COLUMNS} $(( LINES -  8 )) \
			"${OPTS[@]}" 3>&1 1>&2 2>&3 )

	for ARCH in $CHOICES
	do
		ARCHES+=("${ARCH}")
	done

	echo "${ARCHES[@]}"
}

function main () {

	local ARCH_OPT ARCHES
	eval "$(resize)"
	ARCH_OPT=$( getArchIncExc )

	ARCHES=$( getArches "${ARCH_OPT}" )
	if [[ "${ARCH_OPT}" == "include" ]]
	then
		echo "ARCH_INCLUDE=\"${ARCHES[*]}\""
		echo "#ARCH_EXCLUDE=\"\""
	elif [[ "${ARCH_OPT}" == "exclude" ]]
	then
		echo "#ARCH_INCLUDE=\"\""
		echo "#ARCH_EXCLUDE=\"${ARCHES[*]}\""
	fi
}

main