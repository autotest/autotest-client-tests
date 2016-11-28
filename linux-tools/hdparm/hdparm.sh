#!/bin/bash
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##      1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##      2.Redistributions in binary form must reproduce the above copyright notice, this  ##
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
## File :	hdparm.sh
##
## Description:	Test hdparm package
##
## Author:	Robb Romans <robb@austin.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/hdparm
source $LTPBIN/tc_utils.source

REQUIRED="cat grep mount"
device=""  # set by find_disk()

################################################################################
# testcase functions
################################################################################

function test01 {
	tc_register "Is hdparm installed?"
	tc_executes hdparm
	tc_pass_or_fail $? "Hdparm is not properly installed"
}

function find_disk {
	set $(mount | grep '^/.* / '); device=$1
	[ -b "$device" ]
	tc_fail_if_bad $? "Unable to determine root fs device. ($device)"
	tc_info "hdparm to run on $device"
}

function test02 {
	tc_register "Does hdparm execute properly?"
	hdparm -gr $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || exit
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test03 {
	tc_register "Get sector count for filesystem read-ahead"
	hdparm -a $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test04 {
	tc_register "Get bus state"
	hdparm -b $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test05 {
	tc_register "Display the drive geometry"
	hdparm -g $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test06 {
	tc_register "Request identification info directly"
	hdparm -I $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test07 {
	tc_register "Get the keep_settings_over_reset flag"
	hdparm -k $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test08 {
	tc_register "Get read-only flag for device"
	hdparm -r $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test09 {
	tc_register "Perform  timings  of  cache + device  reads (please wait)"
	hdparm -Tt $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test10 {
	tc_register "Query (E)IDE 32-bit I/O support"
	hdparm -c $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test11 {
	tc_register "Check the current IDE power mode status"
	hdparm -C $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}

function test12 {
	tc_register "Get sector count for multiple sector IDE I/O"
	hdparm -m $device >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from hdparm command" || return
	[ -s $stdout ]
	tc_pass_or_fail $? "Hdparm did not write anything to stdout"
}


####################################################################################
# MAIN
####################################################################################

# Function:	main
#

#
# Exit:		- zero on success
#		- non-zero on failure
#
TST_TOTAL=3
tc_setup
tc_exec_or_break $REQUIRED || exit
tc_root_or_break || exit
test01 &&
find_disk &&
test02 &&
test03

# IDE?
if echo $device | grep 'hd' &>/dev/null || \
	echo $device | grep 'ide' &>/dev/null ; then
	TST_TOTAL=12
	test04 &&
	test05 &&
	test06 &&
	test07 &&
	test08 &&
	test09 &&
	test10 &&
	test11 &&
	test12
else
	tc_info "hdparm does not support further operations on non-IDE systems"
fi
