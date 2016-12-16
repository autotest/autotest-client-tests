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
# File :        libevent.sh
#
# Author:       Feng, MiaoTao      fengmt@cn.ibm.com
#
# Description:  Test libevent package
############################################################################################
# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libevent
source $LTPBIN/tc_utils.source


TEST_DIR="libevent-tests"

#
# tc_local_setup specific to this testcase.
#
function tc_local_setup()
{
        tc_root_or_break || return
}


################################################################################
# the testcase functions
################################################################################

#
#       Set up environment variables for the test.
#
function setup_env()
{
         export EVENT_NOPOLL=yes
         export EVENT_NOSELECT=yes
         export EVENT_NOEPOLL=yes
}

#
#       common test for every conditions
#
function common_test()
{
	setup_env	
	unset $1

        if ! $TEST_DIR/test-init 2>/dev/null; then
                tc_info "Skipping the common event test under $1."
                return 0
        fi

	tc_info "Run test-eof: "
	$TEST_DIR/test-eof &>$stdout || return 1 
	#$TEST_DIR/test-eof >/dev/null 2>$stderr || {tc_info "Run test-eof FAILED."; return 1; }

	tc_info "Run test-weof: "
	$TEST_DIR/test-weof &>$stdout || return 1
	#$TEST_DIR/test-weof >/dev/null 2>$stderr || {tc_info "Run test-weof FAILED."; return 1; }

	tc_info "Run test-time: "
	$TEST_DIR/test-time &>$stdout || return 1
	#$TEST_DIR/test-time >/dev/null 2>$stderr || {tc_info "Run test-time FAILED."; return 1; }

	tc_info "Run regress: "
	$TEST_DIR/regress &>$stdout || return 1 
	#$TEST_DIR/regress >/dev/null 2>$stderr || {tc_info "Run regress FAILED."; return 1; }

	return 0
}

#
#       Ensure libevent package is installed
#
function test01()
{
        tc_register "Is libevent installed?"
	ls /usr/lib*/libevent*.so* >$stdout 2>$stderr
        tc_pass_or_fail $? "libevent package is not installed"
}

#
#       Test event test under POLL 
#
function test02()
{
        tc_register "Test event test under POLL. "
	common_test "EVENT_NOPOLL"
        tc_pass_or_fail $? "Test event test under POLL FAILED."
}

#
#       Test event test under SELECT 
#
function test03()
{
        tc_register "Test event test under SELECT. "
	common_test "EVENT_NOSELECT"
        tc_pass_or_fail $? "Test event test under POLL FAILED."
	
}

#
#       Test event test under EPOLL 
#
function test04()
{
        tc_register "Test event test under EPOLL. "
	common_test "EVENT_NOEPOLL"
        tc_pass_or_fail $? "Test event test under POLL FAILED."
}

################################################################################
# main
################################################################################
cd ${LTPBIN%/shared}/libevent

TST_TOTAL=4

tc_setup                                # standard setup
test01 &&
test02 &&
test03 &&
test04
