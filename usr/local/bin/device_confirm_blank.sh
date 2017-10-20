#!/bin/bash
VERSION="0.0.9"

trap 'echo -ne "\n:::\n:::\tCaught signal, exiting at line $LINENO, while running :${BASH_COMMAND}:\n:::\n"; exit' SIGINT SIGQUIT

# device_confirm_blank.sh: Tool to make sure a block device is blank / empty
#
# Copyright © 2015-2017 Kalin KOZHUHAROV <kalin@thinrope.net>



function usage()
{
	echo -ne "\n"
	echo -ne "==================== $0-${VERSION} ====================\n"
	echo -ne "Usage: $0 <DEVICE_TO_CHECK>\n"
}
# External dependencies
declare -A COMMANDS
## sys-apps/util-linux-2.28.2
COMMANDS[blockdev]="/sbin/blockdev"

## sys-apps/coreutils-8.26
COMMANDS[shuf]="/usr/bin/shuf"
COMMANDS[dd]="/bin/dd"
COMMANDS[md5sum]="/usr/bin/md5sum"
## sys-devel/bc-1.06.95-r1
COMMANDS[bc]="/usr/bin/bc"

if [ "$#" -ne 1 ]
then
	echo "$0: Illegal number of parameters: $# !!!"
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

DEVICE_TO_CHECK=$1
# FIXME: does not work with VERBOSE
VERBOSE=0
# FIXME: calculate based on % of size
NUMBER_OF_CHECKS=1024
# in bytes, 1MiB
CHECK_SIZE=1048576
CHECK_MD5=$(${COMMANDS[dd]} if=/dev/zero bs=1048576 count=1 2>/dev/null|md5sum)

if [ -r "${DEVICE_TO_CHECK}" ]
then
	echo "Processing ${DEVICE_TO_CHECK}..."
else
	echo "$0: Cannot access ${DEVICE_TO_CHECK} !!! (Try root?)"
	exit 1
fi

echo "Veryfying ${DEVICE_TO_CHECK} with random ${NUMBER_OF_CHECKS} runs (+1st/last) of ${CHECK_SIZE} bytes each for 0s..."
TOTAL_BYTES=$(${COMMANDS[blockdev]} --getsize64 ${DEVICE_TO_CHECK})

echo -ne "1. Checking ${CHECK_SIZE} bytes at the beginning..."
${COMMANDS[dd]} if=${DEVICE_TO_CHECK} bs=${CHECK_SIZE} count=1 iflag=skip_bytes skip=0 2>/dev/null| ${COMMANDS[md5sum]} --status --quiet -c <(echo "${CHECK_MD5}") 2>/dev/null 1>&2
if [ $? -ne 0 ]
then
	echo -ne "\b\b\b: FAILED!\n"
	exit 1
else
	echo -ne "\b\b\b: OK.\n"
fi

echo -ne "2. Checking ${CHECK_SIZE} bytes at the end..."
LAST_OFFSET=$(( ${TOTAL_BYTES} - ${CHECK_SIZE} ))
${COMMANDS[dd]} if=${DEVICE_TO_CHECK} bs=${CHECK_SIZE} count=1 iflag=skip_bytes skip=${LAST_OFFSET} 2>/dev/null| ${COMMANDS[md5sum]} --status --quiet -c <(echo "${CHECK_MD5}") 2>/dev/null 1>&2
if [ $? -ne 0 ]
then
	echo -ne "\b\b\b: FAILED!\n"
	exit 2
else
	echo -ne "\b\b\b: OK.\n"
fi

echo -ne "3. Checking random ${NUMBER_OF_CHECKS} runs in the middle..."
TOTAL_CHECKS=$(echo "scale=0; ${TOTAL_BYTES}/${CHECK_SIZE}" |${COMMANDS[bc]} -l)
RUNS_TO_CHECK=$(${COMMANDS[shuf]} --head-count=${NUMBER_OF_CHECKS} --input-range="0-${TOTAL_CHECKS}")
TEST_RUN=0
for CURRENT_RUN in ${RUNS_TO_CHECK}
do
	((TEST_RUN+=1)) 
	${COMMANDS[dd]} if=${DEVICE_TO_CHECK} bs=${CHECK_SIZE} count=1 skip=${CURRENT_RUN} 2>/dev/null| ${COMMANDS[md5sum]} --status --quiet -c <(echo "${CHECK_MD5}") 2>/dev/null 1>&2
	if [ $? -ne 0 ]
	then
		echo -ne "\nFailed run ${CURRENT_RUN} at offset $(( ${CURRENT_RUN} * ${CHECK_SIZE}))! Exitting.\n"
		exit 3
	else
		[ ${VERBOSE} -ge 1 ] && echo -ne "\r\t[${TEST_RUN}/${NUMBER_OF_CHECKS}]:\tchecked run ${CURRENT_RUN}: OK"
	fi
done
echo -ne "\b\b\b: OK.\n"

echo -ne "All checked runs were only 0s.\n"
PERCENT=$(echo "scale=2; 100.0 * ${NUMBER_OF_CHECKS} * ${CHECK_SIZE} / ${TOTAL_BYTES}" |${COMMANDS[bc]} -l)
echo "There is ${PERCENT}% certainty that ${DEVICE_TO_CHECK} is blank."

