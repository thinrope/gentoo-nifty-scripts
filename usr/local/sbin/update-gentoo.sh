#!/bin/bash
VERSION="1.0.8"

trap 'echo -ne "\n:::\n:::\tCaught signal, exiting at line $LINENO, while running :${BASH_COMMAND}:\n:::\n"; exit' SIGINT SIGQUIT

# update-gentoo.sh: Script to update all possible things in Gentoo box
#
# Copyright © 2012-2017 Kalin KOZHUHAROV <kalin@thinrope.net>



# {{{ external dependencies
declare -A COMMANDS
## app-portage/eix-0.32.9
COMMANDS[eix-sync]="/usr/bin/eix-sync"

## app-admin/perl-cleaner-2.25
COMMANDS[perl-cleaner]="/usr/sbin/perl-cleaner"

## sys-apps/portage-2.3.13-r1
COMMANDS[emerge]="/usr/bin/emerge"
COMMANDS[emaint]="/usr/sbin/emaint"

## app-portage/gentoolkit-0.4.0
COMMANDS[revdep-rebuild]="/usr/bin/revdep-rebuild"
COMMANDS[eclean]="/usr/bin/eclean"
# external dependencies }}}

NUMBER_OF_ARGUMENTS=0
function usage()
{
	echo -ne "\n"
	echo -ne "==================== $0-${VERSION} ====================\n"
	echo -ne "Usage: $0\n"
}

# {{{ standard error checking
if [ "$#" -ne ${NUMBER_OF_ARGUMENTS} ]
then
	echo "$0: Illegal number of parameters: $# (should have been ${NUMBER_OF_ARGUMENTS}) !!!"
	usage
	exit -1
fi

for C in "${!COMMANDS[@]}"
do
	if [ ! -e "${COMMANDS[$C]}" ]
	then
		echo "$0: Cannot find ${C} command, tried ${COMMANDS[$C]} path..."
		echo "$0: Giving up, please fix the script."
		exit -2
	fi
	if [ ! -x "${COMMANDS[$C]}" ]
	then
		echo "$0: Cannot execute ${COMMANDS[$C]}, check your user permissions."
		echo "$0: Giving up, please use sudo as appropriate."
		exit -3
	fi
done
# standard error checking }}}


${COMMANDS[eix-sync]}

#${COMMANDS[demerge]} --record --comment "update-gentoo.sh-${VERSION} BEGIN"

${COMMANDS[emerge]} -Dtuv --newuse --keep-going @system $1
${COMMANDS[emerge]} -Dtuv --newuse --keep-going --with-bdeps=y @world $1
FEATURES="-ccache -distcc" MAKEOPTS="-j1" ${COMMANDS[emerge]} -Dtuv --newuse --keep-going --with-bdeps=y @world $1

${COMMANDS[perl-cleaner]} --all

${COMMANDS[revdep-rebuild]}
${COMMANDS[emaint]} -f all

${COMMANDS[eclean]} --destructive distfiles --fetch-restricted

#${COMMANDS[demerge]} --record --comment "update-gentoo.sh-${VERSION} END"

# -------------------------------------------------------------------------------------------------
# YYYY-mm-dd	ver	Changes
# -------------------------------------------------------------------------------------------------
# 2017-11-26	1.0.6	remove dependency on python-updater (handled by emerge -N or -U)
#			add COMMANDS dependencies and usage()
# 2017-11-27	1.0.7	refactor to unify Changes
# 2021-06-28	1.0.8	remove demerge (deprecated)
