#!/bin/bash
###########################################################################################
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
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/sysfsutils
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/sysfsutils/sysfsutils-tests/
## Author : Suzuki K P <suzuki@in.ibm.com>                                      #
###########################################################################################


function tc_local_setup()
{
	if [ ! -f $TESTDIR/libsysfs.conf ]; then
		tc_fail " Could not the conf file for libsysfs tests" || return
	else
		source  $TESTDIR/libsysfs.conf
	fi
	grep sysfs /proc/mounts &>/dev/null
	tc_fail_if_bad $? "sysfsutils: sysfs is not mounted" || return
}

function test_get_driver()
{
	if [ ! -f $TESTDIR/get_driver ];then
		tc_info "get_driver test is unavailable"
		return
	fi
	if [ "$VALID_DRIVER_DEVICE" == "not supported" ]; then
		tc_info "VALID_DRIVER_DEVICE environment variable not set by libsysfs.conf"
		return
	fi
	tc_register "get_driver"
	$TESTDIR/get_driver pci $VALID_DRIVER >$stdout 2>$stderr && 
		grep -q $VALID_DRIVER_DEVICE $stdout
	tc_pass_or_fail $? "get_driver pci $VALID_DRIVER should find $VALID_DRIVER_DEVICE"
}
	
function test_get_device()
{
	if [ ! -f $TESTDIR/get_device ];then
		tc_info "get_device test is unavailable"
		return
	fi
	if [ "$VALID_DRIVER_DEVICE" == "not supported" ]; then
		tc_info "VALID_DRIVER_DEVICE environment variable not set by libsysfs.conf"
		return
	fi
	tc_register "get_device"
	$TESTDIR/get_device pci  $VALID_DRIVER_DEVICE >$stdout 2>$stderr &&
		grep -q $VALID_DRIVER $stdout
	tc_pass_or_fail $? "get_device pci  $VALID_DRIVER_DEVICE should find $VALID_DRIVER"
}

function test_get_module()
{
	if [ "$VALID_MODULE" == "not supported" ]; then
		tc_info "VALID_MODULE is not set by libsysfs.conf"
		return
	fi
	if [ ! -f $TESTDIR/get_module ];then
		tc_info "get_module test is unavailable"
		return
	fi
	tc_register "get_module"
	$TESTDIR/get_module $VALID_MODULE >$stdout 2>$stderr
	grep -q $VALID_MODULE_PARAM $stdout &&
		grep -q $VALID_MODULE_SECTION $stdout
	tc_pass_or_fail $? "get_module $VALID_MODULE should be able to find the module" \
		"parameter $VALID_MODULE_PARA and section $VALID_MODUE_SECTION"
}

function test_libsysfs()
{
	local line
	if [ ! -f $TESTDIR/testlibsysfs ];then
		tc_info "testlibsysfs is not available"
		return
	fi
	tc_info "Running API test for libsysfs"
	$TESTDIR/testlibsysfs 1 $TCTMP/test.log
	(while read line;
	do
		[ "${line:0:7}" != "TESTING" ] && continue;
		set $line
		test=${2/,/}
		tc_register "$test"
		echo "$line" > $stdout
		while read line; do
	    	[ "${line:0:3}" == "***" ] && break;
	    	echo "$line" >> $stdout
        done
	grep -q "not supported" $stdout
	if [ $? -eq 0 ]; then
		tc_info "$test is skipped : Unable to set environment variables"
		continue;
	fi
	! grep -q -i FAILED $stdout
	tc_pass_or_fail $? "Unexpected failure"
	done ) <  <(cat $TCTMP/test.log)
}

# The test below stresses the dlist implementation.
# It runs for ever until failure ! So we run it for 5 secs to see
# if it runs fine.

function test_dlist_test()
{
	if [ ! -f $TESTDIR/dlist_test ];then
		tc_info "dlist_test test is unavailable"
		return
	fi

	tc_register "doubly linked list stress test"

	$TESTDIR/dlist_test >$stdout 2>$stderr &
	pid=$!

	# Run the test for 5 seconds
	sleep 5
	tc_wait_for_pid $pid
	if [ $? -ne 0 ]; then
		tc_fail "dlist_test died too soon"
	else
		tc_pass
	fi
	kill -9 $pid &>/dev/null
}
	
tc_setup

test_get_driver
test_get_device
test_get_module
test_dlist_test
test_libsysfs
