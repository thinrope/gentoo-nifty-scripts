#!/bin/bash
VERSION="0.0.1"

trap 'echo -ne "\n:::\n:::\tCaught signal, exiting at line $LINENO, while running :${BASH_COMMAND}:\n:::\n"; exit' SIGINT SIGQUIT

# device_acquire.sh: Tool to acquire a physical block device to the current directory (must be empty)
#
# Copyright © 2015-2024 Kalin KOZHUHAROV <kalin@thinrope.net>


NUMBER_OF_ARGUMENTS=1;
DEVICE_TO_ACQUIRE="$1";	# e.g. sdc
DEVICE="/dev/${DEVICE_TO_ACQUIRE}";

DEBUG="echo ";
DEBUG="";

# {{{ external dependencies
declare -A COMMANDS

## GENTOO_DEP: sys-apps/coreutils-9.5
COMMANDS[head]="/usr/bin/head"
COMMANDS[cp]="/usr/bin/cp"
COMMANDS[md5sum]="/usr/bin/md5sum"
COMMANDS[tee]="/usr/bin/tee"

## GENTOO_DEP: sys-devel/bc-1.07.1-r6
COMMANDS[bc]="/usr/bin/bc"

## GENTOO_DEP: sys-apps/hdparm-9.65-r2
COMMANDS[hdparm]="/usr/bin/hdparm"

## GENTOO_DEP: sys-apps/util-linix-2.39.4-r1
COMMANDS[sfdisk]="/usr/bin/sfdisk"

## GENTOO_DEP: sys-apps/smartmontools-7.4-r1
COMMANDS[smartctl]="/usr/bin/smartctl"

## GENTOO_DEP: sys-apps/pv-1.8.12
COMMANDS[pv]="/usr/bin/pv"

## GENTOO_DEP: app-misc/colordiff-1.0.21
COMMANDS[colordiff]="/usr/bin/colordiff"

## GENTOO_DEP: app-crypt/md5deep-4.4
COMMANDS[md5deep]="/usr/bin/md5deep"

# external dependencies }}}
# {{{ standard error checking
function usage()
{
	echo -ne "\n"
	echo -ne "==================== $0-${VERSION} ====================\n"
	echo -ne "Usage: $0 <DEVICE>\n"
	echo -ne "Example: $0 sdc\n"
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

if [ ! -r "${DEVICE}" ]
then
	echo "$0: Cannot read ${DEVICE} !!! Login as root or use sudo?"
	exit -4
fi

if ! [ $(id -u) = 0 ]
then
	echo "$0: This script must be run as root (or via sudo), exitting."
	exit -5
fi

# FIXME: check that it is a block device

echo "|Acquiring ${DEVICE} ..."

#FIXME: check CWD is empty
if [ "x${DEBUG}x" != "xx" ];
then
	set -x
fi

echo -e "|\t1. Saving some metadata ..."
${DEBUG} ${COMMANDS[hdparm]} -I ${DEVICE} > ${DEVICE_TO_ACQUIRE}.hdparm_-I
${DEBUG} ${COMMANDS[sfdisk]} -d ${DEVICE} > ${DEVICE_TO_ACQUIRE}.sfdisk_-d
${DEBUG} ${COMMANDS[smartctl]} -a ${DEVICE} > ${DEVICE_TO_ACQUIRE}.smartctl_-a.before

echo -e "|\t2. Copying contents, please be patient ..."
${DEBUG} ${COMMANDS[pv]} -petrab ${DEVICE} \
	|${COMMANDS[tee]} >(${COMMANDS[md5deep]} -p 1G -d >${DEVICE_TO_ACQUIRE}.dd.dfxml) >( (${COMMANDS[md5sum]} - |${COMMANDS[head]} -c 32; echo "  ${DEVICE_TO_ACQUIRE}.dd") >${DEVICE_TO_ACQUIRE}.dd.md5sum) \
	|${COMMANDS[cp]} --sparse=always /proc/self/fd/0 ${DEVICE_TO_ACQUIRE}.dd

echo -e "|\t3. Confirming if S.M.A.R.T. values have changed ..."
${DEBUG} ${COMMANDS[smartctl]} -a ${DEVICE} > ${DEVICE_TO_ACQUIRE}.smartctl_-a.after
LC_ALL=C ${COMMANDS[colordiff]} -u ${DEVICE_TO_ACQUIRE}.smartctl_-a.{before,after}

echo -e "|${DEVICE} acquired."

exit 0

# -------------------------------------------------------------------------------------------------
# YYYY-mm-dd	ver	Changes
# -------------------------------------------------------------------------------------------------
# 2024-09-26	0.0.1	Initial refactoring and release
#

# vim: foldmethod=marker
