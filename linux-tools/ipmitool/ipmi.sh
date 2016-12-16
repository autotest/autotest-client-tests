#!/bin/bash

#############################################################################
# File : ipmi.sh 
#
# Description: This program tests ipmitool
#
# Author:      Kumuda G - kumuda.govind@in.ibm.com
#
# History:     Oct 31 2011 - created - Kumuda G
#############################################################################
 
# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/ipmitool
source $LTPBIN/tc_utils.source

tc_get_os_arch
if [ $TC_OS_ARCH == ppc -o $TC_OS_ARCH == ppc64 -o $TC_OS_ARCH == ppc64le ];then
	REQUIRED="egrep cut ipmitool"
else
	REQUIRED="dmidecode egrep cut ipmitool"
fi

#############################################################################
# Test lists
#############################################################################

declare -a V9_TESTS
V9_TESTS=(
	"firewall info lun 0 netfn 0"
	"firewall info lun 0 netfn 1"
	"firewall info lun 0 netfn 4"
	"firewall info lun 0 netfn 0 command 0"
	"firewall info lun 0 netfn 0 command 1"
	"firewall info lun 0 netfn 0 command 2"
	"firewall info lun 0 netfn 1 command 0"
	"firewall info lun 0 netfn 1 command 1"
	"firewall info lun 0 netfn 1 command 2"
	"firewall info lun 0 netfn 4 command 0"
	"firewall info lun 0 netfn 4 command 1"
	"firewall info lun 0 netfn 4 command 2"
	"firewall disable lun 0 netfn 0 command 2"
	"firewall enable lun 0 netfn 0 command 2"
	"channel getciphers ipmi 1"
	"channel getciphers sol 1"
)
declare -a TESTS

if [ $TC_OS_ARCH == ppc -o $TC_OS_ARCH == ppc64 -o $TC_OS_ARCH == ppc64le ]; then
{
TESTS=(
	"lan print"
	"channel info 0"
	"channel info 1"
	"channel info 2"
	"channel info 14"
	"channel authcap 1 1"
	"channel authcap 1 2"
	"channel authcap 1 3"
	"channel authcap 1 4"
	"user set name 3 user1"
	"channel getaccess 0x1 3"
	"channel getaccess 0x2 3"
	"chassis status"
	"chassis power status"
	"sdr info"
	"sdr list all"
	"sdr list full"
	"sdr list compact"
	"sdr list event"
	"sdr list mcloc"
	"sdr list fru"
	"sdr list generic"
	"sdr type list"
	"sdr entity"
	"sdr dump file"
	"sel"
	"sel info"
	"sel list"
	"sel elist"
	"sel list 5"
	"sel time get"
	"sel writeraw testing"
	"sel readraw testing"
	"sel save file"
	"sensor list"
	"session info all"
	"session info active"
	"user summary 0x1"
	"user summary 0x2"
	"user list 0x1"
	"user list 0x2"
	"fru"
	"fru read 0 file"
)
}
else
{
TESTS=(
	"lan print"
	"bmc getenables"
	"channel info 0"
	"channel info 1"
	"channel info 2"
	"channel info 14"
	"channel info 15"
	"channel authcap 1 1"
	"channel authcap 1 2"
	"channel authcap 1 3"
	"channel authcap 1 4"
	"channel getaccess 0x1"
	"channel getaccess 0x2"
	"chassis status"
	"chassis identify"
	"chassis restart_cause"
	"chassis power status"
	"pef info"
	"pef status"
	"pef list"
	"sdr info"
	"sdr list all"
	"sdr list full"
	"sdr list compact"
	"sdr list event"
	"sdr list mcloc"
	"sdr list fru"
	"sdr list generic"
	"sdr type list"
	"sdr entity"
	"sel"
	"sel info"
	"sel list"
	"sel elist"
	"sel list 5"
	"sel time get"
	"sel writeraw testing"
	"sel readraw testing"
	"sel save file"
	"sensor list"
	"session info all"
	"session info active"
	"user summary 0x1"
	"user summary 0x2"
	"user list 0x1"
	"user list 0x2"
	"fru read 0 file"
)
}
fi

#############################################################################
# Utility function
#############################################################################

#
# Local setup
#
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || exit

	if [ $TC_OS_ARCH != ppc -a $TC_OS_ARCH != ppc64 -a $TC_OS_ARCH != ppc64le ];then
		dmidecode | egrep 'Baseboard Management Controller|IPMI' >$stdout 2>$stderr
		tc_break_if_bad $? "BMC is not detected. Aborting." || exit
	fi
}

#############################################################################
# Test functions
#############################################################################

#
# Run one test as passed on command line
#
function run_test()
{
	tc_register "$*"

	[ "$*" ]
	tc_break_if_bad $? "Internal script error: $FUNCNAME called without arguments" || exit

	if [ $TC_OS_ARCH == ppc -o $TC_OS_ARCH == ppc64 -o $TC_OS_ARCH == ppc64le ];then
		ipmitool -I lanplus -H $FSP_IP -P $PASSWORD $* >$stdout 2>$stderr
		tc_pass_or_fail $? "Unexpected response from \"ipmitool -I lanplus -H $FSP_IP -P $PASSWORD $*\""
	else
		ipmitool $* >$stdout 2>$stderr
		tc_pass_or_fail $? "Unexpected response from \"ipmitool $*\""
	fi
	if [ "$*" == "channel getaccess 0x2"  ] || [ "$*" == "channel getaccess 0x1"  ] ; then
		tc_info "ipmi $* having base bug, https://bugzilla.linux.ibm.com/show_bug.cgi?id=89149"
	fi 
}

#
# Installation and startup check
#
function test00()
{
	tc_register "Check install and start IPMI"

	declare -A array
        array[CONFIG_IPMI_HANDLER]="ipmi_msghandler"
        array[CONFIG_IPMI_SI]="ipmi_si"
        array[CONFIG_IPMI_DEVICE_INTERFACE]="ipmi_devintf"
	if [ $TC_OS_ARCH != ppc -a $TC_OS_ARCH != ppc64 -a $TC_OS_ARCH != ppc64le ]; then
        	for mod in "${!array[@]}"
        	do
                	tc_check_kconfig $mod
                	if [ $? -eq 1 ]; then
                        	modprobe ${array[$mod]} >$stdout 2>$stderr
                        	tc_fail_if_bad $? "Module ${array[$mod]} is not installed properly or would not start" || return
                	fi
        	done
	fi

	VERSION="old"
	if [ $TC_OS_ARCH == ppc -o $TC_OS_ARCH == ppc64 -o $TC_OS_ARCH == ppc64le ]; then
		BMC2=$(ipmitool -I lanplus -H $FSP_IP -P $PASSWORD bmc info | grep "IPMI Version" | cut -b 29)
		VERSION=$(ipmitool -I lanplus -H $FSP_IP -P $PASSWORD -V | cut -b 22)
	else
		BMC2=$(ipmitool bmc info | grep "IPMI Version" | cut -b 29)
		VERSION=$(ipmitool -V | cut -b 22)
	fi
	((BMC2>=2)) && ((VERSION>=9)) && {
		((TST_TOTAL+=${#V9_TESTS[*]}))
		TESTS=( "${V9_TESTS[@]}" "${TESTS[@]}" )
	}
	TST_TOTAL=${#TESTS[*]}
	((++TST_TOTAL))		# to account for test00

	tc_info "ipmitool utility version: $(ipmitool -V)"
	tc_info "IPMI Driver version: $(dmesg |grep ipmi |grep -i -m 1 version) "
	
        if [ $TC_OS_ARCH != ppc -a $TC_OS_ARCH !=  ppc64 -a $TC_OS_ARCH != ppc64le ]; then
		ipmitool sel clear &>/dev/null;sleep 10
                ipmitool event 2 >$stdout 2>$stderr
		tc_pass_or_fail $? "Could not start system event"
	fi
}

#############################################################################
# Main
#############################################################################

tc_setup

if [ $TC_OS_ARCH == ppc -o $TC_OS_ARCH == ppc64 -o $TC_OS_ARCH == ppc64le ]; then
	if [ $1 ]; then
		FSP_IP=$1
		if [ $2 ]; then
			PASSWORD=$2
		else
			echo "Pass the ipmi session password"
			exit
		fi
	else
		echo "Pass the FSP IP"
		exit
	fi
fi

test00 || exit

((n=-1))
while ((++n < TST_TOTAL-1)) ; do
	run_test ${TESTS[n]}
done
