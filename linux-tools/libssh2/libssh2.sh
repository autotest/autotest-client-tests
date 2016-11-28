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
### File :        libssh2.sh                                                   ##
##
### Description: This testcase tests libssh2 package                           ##
##
### Author:      Ramesh YR, rameshyr@linux.vnet.ibm.com                        ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libssh2
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libssh2/tests"

function tc_local_setup()
{
	set `find /usr/lib* -name libssh2\* `
	[ -f $1 ] &&  tc_break_if_bad $? "libssh2 not properly installed"
        #arp table entries are messed up by the previous testcase which is
        #causing trouble (bug 99129), in running this test;
        #So restarti lo device. These lines can be removed once the bug
        #get fixed.
        tc_info "Bring down loopback device(bug 99129)"
        ip link set lo down > /dev/null 2>&1
        [ $? -ne 0 ] && tc_info "unable to bring down lo device. Continuing.."
        tc_info "Bring up loopback device (bug 99129)"
        ip link set lo up > /dev/null 2>&1
        tc_break_if_bad $? "Unable to bring up the lo device"

}

function run_test()
{
	pushd $TESTS_DIR &>/dev/null
	TESTS=`find . -maxdepth 1 -type f -not -name ssh2`
	TST_TOTAL=`echo $TESTS | wc -w`
	
	for test in $TESTS; do
		tc_register "Test $test" 
		./$test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	done
	popd &>/dev/null
}

#
# main
#
tc_setup && \
run_test 
