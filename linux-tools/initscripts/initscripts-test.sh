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
## File :        initscripts-test.sh
##
## Description: This testcase tests the commands in the initscripts package
##
## Author:
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/initscripts
TESTDIR=${LTPBIN%/shared}/initscripts
source $LTPBIN/tc_utils.source
prog="dummy_service_initscripts"
log_file="/var/log/dummy_service_initscripts.log"

#############################################################################
# Utility functions
#############################################################################
function tc_local_setup()
{
        tc_root_or_break || return
	ifconfig lo | grep  -q "RUNNING"  &>/dev/null
	tc_break_if_bad $? "interface lo is not running" || exit
	cp $TESTDIR/$prog /etc/init.d/
	touch $log_file
}


function tc_local_cleanup()
{
	service network restart &>/dev/null
	sleep 10
	[[ ! `ifconfig lo | grep "RUNNING"` ]] || return 0
	ifup lo >$stdout 2>$stderr
	rm  -f /etc/init.d/dummy_service $log_file
	return
}


function test01()
{
        tc_register     "Installation check"
        [ -d /etc/sysconfig/network-scripts ]
	tc_pass_or_fail $? "Missing /etc/sysconfig/network-scripts"
}

function test02()
{
	tc_register	"Check ifdown"
	ifdown lo >$stdout 2>$stderr
	! ( ifconfig lo 2>$stderr |grep -q "RUNNING" )
	tc_pass_or_fail $? "ifdown failed"
}

function test03()
{	
	tc_register	"Check ifup"
	ifup lo >$stdout 2>$stderr
	ifconfig lo 2>$stderr |grep -q "RUNNING"  
	tc_pass_or_fail $? "ifup failed"
}

function test04()
{
	tc_register	"Check service"
	service $prog start >$stdout 2>$stderr
	tc_wait_for_file_text $log_file "dummy Service started" 10
	tc_fail_if_bad $? "dummy service entry not found in $log_file" || return

	service $prog stop >$stdout 2>$stderr
	tc_wait_for_file_text $log_file "dummy Service stopped" 10
        tc_fail_if_bad $? "dummy service entry not found in $log_file" || return

	service $prog status >$stdout 2>$stderr
	tc_wait_for_file_text $log_file "dummy_service is running ....." 10
        tc_fail_if_bad $? "dummy service entry not found in $log_file" || return

	service $prog restart >$stdout 2>$stderr
	tc_wait_for_file_text $log_file "dummy_service is restarted..." 10
	tc_pass_or_fail $? "service command failed" 
	
}		

#############################################################################
# main
#############################################################################

TST_TOTAL=3
tc_setup        # exits on failure

test01 && 
test02 &&
test03 &&
test04
