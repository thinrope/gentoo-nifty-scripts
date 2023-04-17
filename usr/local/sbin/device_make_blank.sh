#!/bin/bash
VERSION="0.0.1"

trap 'echo -ne "\n:::\n:::\tCaught signal, exiting at line $LINENO, while running :${BASH_COMMAND}:\n:::\n"; exit' SIGINT SIGQUIT

# device_make_blank.sh: Tool to wipe a block device by writing from /dev/zero to it
#
# Copyright © 2023 Kalin KOZHUHAROV <kalin@thinrope.net>


NUMBER_OF_ARGUMENTS=1
DEVICE_TO_WIPE=$1

# {{{ external dependencies
declare -A COMMANDS
## sys-apps/pv-1.6.20
COMMANDS[pv]="/usr/bin/pv"
# external dependencies }}}
# {{{ standard error checking
function usage()
{
	echo -ne "\n"
	echo -ne "==================== $0-${VERSION} ====================\n"
	echo -ne "Usage: $0 <DEVICE_TO_WIPE>\n"
}

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

if [ ! -r "${DEVICE_TO_WIPE}" ]
then
	echo "$0: Cannot read ${DEVICE_TO_WIPE} !!! Login as root or use sudo?"
	exit -4
fi

echo "Under development! For now try the following command:"
echo
echo "pv -petrab </dev/zero >/dev/sdb"
echo
exit 0

# -------------------------------------------------------------------------------------------------
# YYYY-mm-dd	ver	Changes
# -------------------------------------------------------------------------------------------------
# 2023-04-17	0.0.1	Initial commit
#

# vim: foldmethod=marker
