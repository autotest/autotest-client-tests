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
## File :	setserial.sh
##
## Description:	Test setserial -g /dev/ttyS0
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# the testcase functions
################################################################################

#
# test01	setserial -g /dev/ttyS0
#
function test01()
{
	tc_register "setserial -g"

	local device="/dev/ttyS0"
	tc_exist_or_break $device || return

	local command="setserial -g $device"
	$command >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected respones from $command"

	cat $stdout | grep "^$device.*Port.*IRQ" >/dev/null
	tc_pass_or_fail $? "Bad output from $command" \
		"expected to see \"$device\", \"Port\", and \"IRQ\" in stdout"
}

################################################################################
# main
################################################################################

TST_TOTAL=1

tc_setup

tc_root_or_break || exit

test01
