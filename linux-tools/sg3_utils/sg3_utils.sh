#!/bin/sh
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
## File :   sg3_utils.sh
##
## Description: This program tests  functionality of sg3_utils commands.
##
## Author:   Xie Jue <xiejue@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

commands="sg_scan sg_map sg_inq sginfo sg_readcap sg_start sg_modes sg_logs sg_senddiag sg_read sg_dd sg_rbuf sg_test_rwbuf sg_turs sgm_dd sgp_dd "


#variable to track if the module is loaded explicitly
sg_module_load=0

function tc_local_setup()
{
        lsmod |grep -w sg
	if [ $? -ne 0 ]; then
		modprobe sg
		sg_module_load=1
	fi
}

function tc_local_cleanup()
{
        if [ $sg_module_load -eq 1 ]; then
                rmmod sg
	fi
}

#
# Not all hardware support all sg commands. This checks for messages indicating
# unsupported commands then aborts the testcase that used the command.
#
function is_supported()
{
	local supported=1
	local criteria
	criteria=$(cat $stdout $stderr | grep -i "not supported") && supported=0 ||
	criteria=$(cat $stdout $stderr | grep -i "illegal request") && supported=0 ||
	criteria=$(cat $stdout $stderr | grep -i "Invalid argument") && supported=0 ||
	criteria=$(cat $stdout $stderr | grep -i "probably a STANDARD INQUIRY response") && supported=0 ||
	criteria=$(cat $stdout $stderr | grep -i "Invalid command operation code") && supported=0 ||
	criteria=$(cat $stdout $stderr | grep -i "exceeds reported capacity") && supported=0

	((supported)) || {
		tc_info "**** NOT SUPPORTED ON THIS HARDWARE: $TCNAME"
		tc_info "**** BECAUSE:                        $(echo $criteria)"
		((--TST_TOTAL))
		return 1
	}
	return 0
}

#
# TC_sg_scan rather simple but useful program scans the sg devices 
#
function TC_sg_scan()
{
	local cmd="sg_scan"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_fail_if_bad $? "unexpected response" || return
	grep -q "scsi" $stdout &&
	grep -q "channel=" $stdout &&
	grep -q "lun=" $stdout &&
	tc_pass_or_fail $? "expected to see scsi channel and lun in output" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_scan -i"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_scan -n"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_scan -x"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return

}
#
# TC_sg_map shows the mapping of the avialable sg device name 
# sg_map  [-n] [-x] [-sd] [-scd or -sr] [-st]'
#
function TC_sg_map()
{
	local cmd="sg_map -i"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_fail_if_bad $? "unexpected response" || return
	grep -q $device_sg $stdout  
	tc_pass_or_fail $? "expected to see $device_sg in stdout" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_map -n"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_map -x"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_map -sd"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return

	# messy!
	local  device_sd_old=`$cmd|grep sd 2>/dev/null| head -1`
	device_sd=${device_sd_old##* }
# If there is scsi disk mapped as SG device, we use the $device_sg
	if [ -n "$device_sd" ] ; then
		device_sg=`sg_map|grep "$device_sd" | head -1 | cut -d " " -f 1`
	fi

	###############################

	((++TST_TOTAL))
	cmd="sg_map -scd"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_map -st"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return
}

#
# TC_sg_inq sg_inq executes a SCSI INQUIRY command on the given device and interprets the results
#sg_inq [-e] [-h|-r] [-o=<opcode_page>] [-V] <sg_device>
#
function TC_sg_inq()
{
	local cmd="sg_inq -V"
	tc_register "$cmd"
	$cmd &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_inq -e $device_sg"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	local rc=$?
	is_supported || return
	tc_fail_if_bad $rc "unexpected response" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_inq -H $device_sg"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_inq -r $device_sg"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	tc_pass_or_fail $? "unexpected response" || return
}

#
#TC_sginfo
#
function TC_sginfo()
{
	local cmd="sginfo -l"
	tc_register    "$cmd"
	$cmd >$stdout 2>$stderr
	tc_pass_or_fail $? || return

	###############################

	cmd="sginfo -a $device_sg"
	((++TST_TOTAL))
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response" || return

	grep -qi "Caching mode" $stdout && {
		sginfo -c $device_sg >$stdout 2>$stderr
		tc_fail_if_bad $? "sginfo -c $device_sg"  || return
	}
	grep -qi "control mode" $stdout && {
		sginfo -C $device_sg >$stdout 2>$stderr
		tc_fail_if_bad $? "sginfo -C $device_sg"  || return
	}
	tc_pass
}

#
#TC_sg_readcap
#
function TC_sg_readcap()
{
	local cmd="sg_readcap $device_sg"
	tc_register    "$cmd"
	$cmd >$stdout 2>$stderr
	tc_pass_or_fail $? "unexpected response"
}
#
#TC_sg_start
#
function TC_sg_start()
{
	((--TST_TOTAL))
	tc_info "test_manually \"sg_start\""
	return 0
}
#
#TC_sg_modes Use -6 for best compatabuility
#
function TC_sg_modes()
{
	local cmd="sg_modes -6 -a $device_sg"
	tc_register    "$cmd"
	$cmd >$stdout 2>$stderr
	tc_pass_or_fail $? "unexpected response"
}
#
#TC_sg_logs
#
function TC_sg_logs()
{
	local cmd="sg_logs -l $device_sg"
	tc_register    "$cmd"
	$cmd >/dev/null 2>$stderr
	rc=$?
	is_supported || return
	tc_pass_or_fail $rc "unexpected response"
}

#
#TC_sg_senddiag
#
function TC_sg_senddiag()
{
	local cmd="sg_senddiag -l -vv $device_sg"
	tc_register "$cmd"
	$cmd &>$stdout
	local rc=$?
	is_supported || return
	tc_pass_or_fail $rc "unexpected response"
}

#
#TC_sg_reset
#
function TC_sg_reset()
{
	local cmd="sg_reset -d $device_sg"
	tc_register    "$cmd"
	$cmd >$stdout 2>$stderr
	tc_pass_or_fail $? "unexpected response" || return
	sleep 5

	###############################

	local cmd="sg_reset -h $device_sg"
	((++TST_TOTAL))
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	tc_pass_or_fail $? "unexpected response" || return
	sleep 5

	###############################

	cmd="sg_reset -b $device_sg"
	((++TST_TOTAL))
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	tc_pass_or_fail $? "unexpected response" || return
	sleep 5
}

#
#TC_sg_read
#
function TC_sg_read()
{
	if [ -z "$device_sd" ] ; then
		((--TST_TOTAL))
		tc_info "No SCSI DISK maps as SG deivce,SKIP sg_read test!"
		return
	fi

	local cmd="sg_read if=$device_sg bs=512 count=45"
	tc_register "$cmd"
	$cmd &>$stdout
	tc_pass_or_fail $? "unexpected response"
	local expected=""45+0 records in""
	grep -q "$expected" $stdout 
	tc_pass_or_fail $? "expected to see \"$expected\" in stdout"
}
#
#TC_sg_dd
#
function TC_sg_dd()
{
	if [ -z "$device_sd" ] ; then
		((--TST_TOTAL))
		tc_info "No SCSI DISK maps as SG deivce,SKIP sg_dd test!"
		return
	fi
	tc_executes sdparm || {
		((--TST_TOTAL))
		tc_info "No sdparm so sg_dd skipped"
		return
	}
	local cmd="sg_dd if=$device_sg of=$TCTMP/sg.dat bs=512 count=45"
	tc_register "$cmd"
	$cmd &>$stdout
	tc_fail_if_bad $? "Unexpected response"
	local expected=""45+0 records out""
	grep -q "$expected" $stdout 
	tc_pass_or_fail $? "expected to see \"$expected\" in stdout"
}
#
#TC_sg_rbuf
#
function TC_sg_rbuf()
{
	if [ -z "$device_sg" ] ; then
		((--TST_TOTAL))
		tc_info "No SCSI DISK maps as SG deivce,SKIP sg_rbuf test!"
		return
	fi

	###############################

	local cmd="sg_rbuf -q -b 10 --size=1024 $device_sg"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	local rc=$?
	is_supported || return
	grep -qi "exceeds reported capacity" $stdout && {
		tc_info "exceeds reported capacity"
		:>$stderr
		rc=0
	}
	tc_pass_or_fail $rc "rc=$rc"

	###############################

	((++TST_TOTAL))
	cmd="sg_rbuf -q -b 10 -t --size=1024 $device_sg"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr 
	local rc=$?
	is_supported || return
	tc_pass_or_fail $rc "rc=$rc"

	###############################

	[ "$sys_arch" != "ppc64" ] && {
		((++TST_TOTAL))
		cmd="sg_rbuf -m -b 10 --size=1024  $device_sg"
		tc_register "$cmd"
		$cmd >$stdout 2>$stderr 
		local rc=$?
		is_supported || return
		tc_pass_or_fail $rc "rc=$rc"
	}
}

#
#TC_sg_test_rwbuf
#
# NOTE: sg_test_rwbuf is tested with the --quick option because of the following warning
#
# WARNING: If you access the device at the same time, e.g. because it's a
#  mounted hard disk, the device's buffer may be used by the device itself
#  for other data at the same time, and overwriting it may or may not
#  cause data corruption!
#
function TC_sg_test_rwbuf()
{
	local cmd="sg_test_rwbuf --quick $device_sg"
	if [ -z "$device_sg" ] ; then
		((--TST_TOTAL))
		tc_info "No SCSI DISK maps as SG deivce, SKIP \"$cmd\" test!"
		return
	fi
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	local rc=$?
	is_supported || return
	tc_fail_if_bad $rc "unexpected results" || return
	local expected="read descriptor reports a buffer of"
	grep -qi "$expected" $stdout
	tc_pass_or_fail $? "Expected to see \"$expected\" in stdout"
}

#
#TC_sg_turs
#
function TC_sg_turs()
{
	if [ -z "$device_sg" ] ; then
		((--TST_TOTAL))
		tc_info "No SCSI DISK maps as SG deivce, SKIP sg_trus tests!"
		return
	fi

	###############################

	local cmd="sg_turs -n 1000 $device_sg"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	tc_pass_or_fail $? "unexpected results" || return

	###############################

	((++TST_TOTAL))
	cmd="sg_turs -n 1000 -t $device_sg"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpecgted results" || return
	local expected="time to perform commands was"
	grep -q "$expected" $stdout
	tc_pass_or_fail $? "expected to see \"$expected\" in stdout"
}

#
#
#TC_sgm_dd
#
function TC_sgm_dd()
{
	local cmd="sgm_dd if=$device_sg of=$TCTMP/sg.dat bs=512 count=45"
	if [ -z "$device_sg" ] ; then
		((--TST_TOTAL))
		tc_info "No SCSI DISK maps as SG deivce, SKIP \"$cmd\" test!"
		return
	fi
	tc_register "$cmd"
	$cmd &>$stdout
	local rc=$?
	is_supported || return
	tc_fail_if_bad $rc "unexpected response" || return
	local expected="45+0 records out"
	grep -q "$expected" $stdout 
	tc_pass_or_fail $? "expected to see \"$expected\" in stdout"
}

#
#
#TC_sgp_dd
#
function TC_sgp_dd()
{
	local cmd="sgp_dd if=$device_sg of=$TCTMP/sg.dat bs=512 count=45"
	if [ -z "$device_sg" ] ; then
		((--TST_TOTAL))
		tc_info "No SCSI DISK maps as SG deivce, SKIP \"$cmd\" test!"
		return
	fi
	tc_register "$cmd"
	$cmd &>$stdout
	local rc=$?
	is_supported || return
	tc_fail_if_bad $rc "unexpected response" || return
	local expected="45+0 records out"
	grep -q "$expected" $stdout 
	tc_pass_or_fail $? "expected to see \"$expected\" in stdout"
}


# 
# main
# 

2>&1 cat /proc/scsi/scsi | grep -q "Direct-Access" || {
	tc_info "there is no SCSI disk available so $TCID test skipped"
	exit 0
}

tc_setup
tc_root_or_break || exit
tc_exec_or_break head grep cut || exit

# if no sg driver exists, skip the test.
device_sg=`sg_scan -n | head -1 |cut -d ":" -f 1`
[ -n "$device_sg" ] 
tc_break_if_bad $? "No sg device to run the test!" || exit
tc_info "USE $device_sg as the test device!"

sys_arch=`uname -m`

set $commands
TST_TOTAL=$#

for cmd in $commands
do
	TC_$cmd
done
