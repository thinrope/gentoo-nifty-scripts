#!/bin/bash
VERSION="0.1.0"

trap 'echo -ne "\n:::\n:::\tCaught signal, exiting at line $LINENO, while running :${BASH_COMMAND}:\n:::\n"; exit' SIGINT SIGQUIT

# device_confirm_blank.sh: Tool to make sure a block device is blank / empty
#
# Copyright © 2015-2024 Kalin KOZHUHAROV <kalin@thinrope.net>


NUMBER_OF_ARGUMENTS=1
DEVICE_TO_CHECK=$1

# {{{ external dependencies
declare -A COMMANDS

## GENTOO_DEP: sys-apps/util-linux-2.39.3-r7
COMMANDS[blockdev]="/sbin/blockdev"

## GENTOO_DEP: sys-apps/coreutils-9.4-r1
COMMANDS[shuf]="/usr/bin/shuf"
COMMANDS[dd]="/bin/dd"
COMMANDS[md5sum]="/usr/bin/md5sum"
COMMANDS[numfmt]="/usr/bin/numfmt"

## GENTOO_DEP: sys-devel/bc-1.07.1-r6
COMMANDS[bc]="/usr/bin/bc"

# external dependencies }}}
# {{{ standard error checking
function usage()
{
	echo -ne "\n"
	echo -ne "==================== $0-${VERSION} ====================\n"
	echo -ne "Usage: $0 <DEVICE_TO_CHECK>\n"
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

# FIXME: does not work with VERBOSE
VERBOSE=0
# FIXME: calculate based on % of size
NUMBER_OF_CHECKS=1024
# in bytes, 1MiB
CHECK_SIZE=1048576
CHECK_MD5=$(${COMMANDS[dd]} if=/dev/zero bs=1048576 count=1 2>/dev/null|md5sum)

if [ ! -r "${DEVICE_TO_CHECK}" ]
then
	echo "$0: Cannot read ${DEVICE_TO_CHECK} !!! Login as root or use sudo?"
	exit -4
fi

function exit_on_end()
{
	echo
	echo "Device ${DEVICE_TO_CHECK} is NOT blank, it DOES contain non-zero bytes!"
	exit 10
}

TOTAL_BYTES=$(${COMMANDS[blockdev]} --getsize64 ${DEVICE_TO_CHECK})
TOTAL_BYTES_IECI=$(echo "${TOTAL_BYTES}" |${COMMANDS[numfmt]} --suffix=B --to=iec-i)
echo "|Verifying that ${DEVICE_TO_CHECK} (size:${TOTAL_BYTES_IECI}) contains only 0s..."

FIRST_OFFSET=0
echo -ne "|\t1. Verifying ${CHECK_SIZE}B at the beginning (at offset ${FIRST_OFFSET})..."
TEST_RUN=1
${COMMANDS[dd]} if=${DEVICE_TO_CHECK} bs=${CHECK_SIZE} count=1 iflag=skip_bytes skip=0 2>/dev/null| ${COMMANDS[md5sum]} --status --quiet -c <(echo "${CHECK_MD5}") 2>/dev/null 1>&2
if [ $? -ne 0 ]
then
	echo -ne "\b\b\b: FAILED!\n"
	exit_on_end
else
	echo -ne "\b\b\b: OK.\n"
fi

LAST_OFFSET=$(( ${TOTAL_BYTES} - ${CHECK_SIZE} ))
echo -ne "|\t2. Verifying ${CHECK_SIZE}B at the end (at offset ${LAST_OFFSET})..."
TEST_RUN=2
${COMMANDS[dd]} if=${DEVICE_TO_CHECK} bs=${CHECK_SIZE} count=1 iflag=skip_bytes skip=${LAST_OFFSET} 2>/dev/null| ${COMMANDS[md5sum]} --status --quiet -c <(echo "${CHECK_MD5}") 2>/dev/null 1>&2
if [ $? -ne 0 ]
then
	echo -ne "\b\b\b: FAILED!\n"
	exit_on_end
else
	echo -ne "\b\b\b: OK.\n"
fi

echo -ne "|\t3. Verifying some (max. ${NUMBER_OF_CHECKS}) random runs of size ${CHECK_SIZE}B in the middle..."
# exclude first/last
TOTAL_CHECKS=$(echo "scale=0; (${TOTAL_BYTES} - 2 * ${CHECK_SIZE})/${CHECK_SIZE}" |${COMMANDS[bc]} -l)
RUNS_TO_CHECK=$(${COMMANDS[shuf]} --head-count=${NUMBER_OF_CHECKS} --input-range="1-${TOTAL_CHECKS}")
for CURRENT_RUN in ${RUNS_TO_CHECK}
do
	((TEST_RUN+=1)) 
	${COMMANDS[dd]} if=${DEVICE_TO_CHECK} bs=${CHECK_SIZE} count=1 skip=${CURRENT_RUN} 2>/dev/null| ${COMMANDS[md5sum]} --status --quiet -c <(echo "${CHECK_MD5}") 2>/dev/null 1>&2
	if [ $? -ne 0 ]
	then
		echo -ne "\b\b\b: Failed run ${CURRENT_RUN} at offset $(( ${CURRENT_RUN} * ${CHECK_SIZE}))!\n"
		exit_on_end
	else
		[ ${VERBOSE} -ge 1 ] && echo -ne "\r\t[${TEST_RUN}/${NUMBER_OF_CHECKS}]:\tchecked run ${CURRENT_RUN}: OK"
	fi
done
echo -ne "\b\b\b: OK.\n"

echo -ne "|All ${TEST_RUN} runs of size ${CHECK_SIZE}B were verified to contain only 0s.\n"
echo
VERIFIED_SIZE=$(echo "scale=2; ${TEST_RUN} * ${CHECK_SIZE}" |${COMMANDS[bc]} -l)
VERIFIED_SIZE_IECI=$(echo "${VERIFIED_SIZE}" |${COMMANDS[numfmt]} --suffix=B --to=iec-i)
PERCENT=$(echo "scale=2; 100.0 * ${VERIFIED_SIZE} / ${TOTAL_BYTES}" |${COMMANDS[bc]} -l)
echo "${VERIFIED_SIZE_IECI} of ${TOTAL_BYTES_IECI} (or about ${PERCENT}%) of ${DEVICE_TO_CHECK} were verified to be 0s."
exit 0

# -------------------------------------------------------------------------------------------------
# YYYY-mm-dd	ver	Changes
# -------------------------------------------------------------------------------------------------
# 2017-11-27	0.0.12	refactor to include Changes and better UI
# 2023-04-17	0.0.13	refactor comments, update package versions
# 2024-04-15	0.1.0	use GENTOO_DEP
#

# vim: foldmethod=marker
