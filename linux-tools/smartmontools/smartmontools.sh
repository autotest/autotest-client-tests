#!/bin/bash
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##	1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##	2.Redistributions in binary form must reproduce the above copyright notice, this  ##
##        list of conditions and the following disclaimer in the documentation and/or     ##
##        other materials provided with the distribution.                                 ##
##                                                                                        ##
## THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS AND ANY EXPRESS       ##
## OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        ##
## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ##
## THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    ##
## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF     ##
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ##
## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  ##
## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS  ##
## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                           ##
############################################################################################
## File :   smartmontools.sh
##
## Description: This program tests basic functionality of smartmontools command.
##
## Author:   Gong Jie <gongjie@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
HD_DRIVE=""


#
# local setup
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break cut grep || return

	local hd
	for hd in sda hda
	do
		if grep "${hd}$" /proc/partitions &>/dev/null
		then
			HD_DRIVE="$hd"
			return
		fi
	done

	[ -n "$HD_DRIVE" ]
	tc_break_if_bad $? "hard disk not found" || return
}

#
# local cleanup
#
function tc_local_cleanup()
{
	[ "$HD_DRIVE" ] && smartctl -X /dev/$HD_DRIVE &>/dev/null
	killall smartd &>/dev/null
}

#
# test1:  installcheck  Installation check
#
function installcheck()
{
	tc_register "smartmontools installation check"
	tc_executes smartctl smartd
	tc_pass_or_fail $? "smartmontools not properly installed"
}

#
# test2: check_smart_capability
#
function check_smart_capability()
{
	tc_register "Checking SMART capability"
	
	## check if SMART support is: Enabled
	smartctl -i /dev/$HD_DRIVE | grep "SMART" | grep  "Enabled" &>/dev/null
	if [ $? -eq 1 ];then
		tc_conf "The drive /dev/$HD_DRIVE is not SMART enabled" 
		return 1
	fi
	
	### if we reach here the test PASS
	tc_pass_or_fail 0

}
# test3: enable_smart_test
#
function enable_smart_test()
{
	tc_register "enables SMART monitoring"
	smartctl -s on /dev/$HD_DRIVE -T permissive >$stdout 2>$stderr
	tc_pass_or_fail $? "smartctl -s on failed"
}

#
# test4: print_smart_info_test
#
function print_smart_info_test()
{
	tc_register "prints all SMART information"
	smartctl -a /dev/$HD_DRIVE >$stdout 2>$stderr
	tc_pass_or_fail $? "smartctl -a failed"
}

#
# test5: short_self_test
#
function short_self_test()
{
	local logstr

	tc_register "foreground short self test"
	tc_get_os_arch
	if  [ "$TC_OS_ARCH" = "x86_64" ] || [ "$TC_OS_ARCH" = "i686" ]; then
		if [ ! `egrep -c '("model name"|QEMU)' /proc/cpuinfo` ]; then
			tc_info "starting foreground short self test, this may take several minutes to complete."
	                smartctl -C -t short /dev/$HD_DRIVE >$stdout 2>$stderr
	                tc_fail_if_bad $? "run short self test failed"

			logstr=$(smartctl -l selftest /dev/$HD_DRIVE | grep "^# 1" | cut -d ' ' -f 4-5)
			[ "${HD_DRIVE:0:2}" = "sd" -a "$logstr" = "Foreground short" -o "$logstr" = "Short captive" ]
			tc_pass_or_fail $? "self test log not found"
		else
	                tc_conf "foreground short self test is not supported on QEMU/Guest"
		fi
	else
		tc_conf "foreground short self test is not supported on zVM/lpar"
	fi
}

#
# test6: smartd log test
#
function smartd_log_test()
{
	tc_register "smartd log test"

	smartd -d -i 10 -r ioctl >$stdout 2>$stderr &
	local pid="$!"
	tc_info "wait 1 minute for smartd to generate logs ..."
	sleep 60
	tc_fail_if_bad $? "sleep failed"

	kill $pid &>/dev/null
	tc_fail_if_bad $? "kill smartd failed"

	(grep -q "Command=SMART STATUS CHECK returned 0" $stdout &&
		grep -q "Command=SMART READ ATTRIBUTE VALUES returned 0" $stdout &&
		grep -q "Command=SMART READ ATTRIBUTE THRESHOLDS returned 0" $stdout) ||
	(grep -q "\[log sense: " $stdout &&
		grep -q "status=" $stdout)

	tc_pass_or_fail $? "smartd log test failed:" \
		"Missing expected information in log files"
}

#
# main
#
tc_setup

installcheck || exit
check_smart_capability || exit
TST_TOTAL=6
enable_smart_test || exit
print_smart_info_test
short_self_test
smartd_log_test
