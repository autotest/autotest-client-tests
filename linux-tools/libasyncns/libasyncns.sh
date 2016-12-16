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
### File : libasyncns.sh                                                       ##
##
### Description: This testcase tests the libasyncns package                    ##
##
### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libasyncns
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libasyncns/tests"
RESOLV_CONF=/etc/resolv.conf
REQUIRED="nslookup grep"
source $LTPBIN/domain_names.source

function tc_local_setup()
{
	# check installation and environment 
        [ -f /usr/lib*/libasyncns.so.0.3.1 ]
        tc_break_if_bad $? "libasyncns not installed"
	tc_exec_or_break $REQUIRED || return
	tc_exist_or_break $RESOLV_CONF || return
	grep -e nameserver -e search -e domain $RESOLV_CONF >$stdout 2>$stderr 
	tc_conf_if_bad $? "invalid DNS configuration" || return
	nslookup $KJHUB1 >$stdout 2>$stderr
	tc_conf_if_bad $? "DNS lookup for $KJHUB1 failed" || return
}

function run_test()
{
	pushd $TESTS_DIR &>/dev/null
        tc_register "Test libasyncns"
        ./asyncns-test >$stdout 2>$stderr
        tc_pass_or_fail $? "Test libasyncns failed"
	popd &>/dev/null
}

#
# main
#
tc_setup
run_test 
