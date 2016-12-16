#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##    1.Redistributions of source code must retain the above copyright notice,            ##
##        this list of conditions and the following disclaimer.                           ##
##    2.Redistributions in binary form must reproduce the above copyright notice, this    ##
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
## File :       libnetfilter_conntrack.sh                                                 ##
##                                                                                        ##
## Description: Test for libnetfilter_conntrack  package                                  ##
##                                                                                        ##
## Author:      Ramya BS  < ramyabs1@in.ibm.com >                                         ##
##                                                                                        ##
###########################################################################################


#=============================================
# Global variables used in this script
#=============================================
#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libnetfilter_conntrack
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/libnetfilter_conntrack/utils


#=====================================================
# Function to check prerequisites to run this test
#=====================================================
function tc_local_setup()
{
        rpm -q libnetfilter_conntrack >$stdout 2>$stderr
	tc_break_if_bad $? " libnetfilter_conntrack not installed"
}


#==================================================================
# Run the test suites which are available on utils directory
#==================================================================
function run_test()
{
	pushd $TESTS_DIR &>/dev/null
	TESTS="conntrack_create conntrack_get conntrack_update conntrack_dump conntrack_dump_filter conntrack_events conntrack_filter conntrack_flush conntrack_create_nat conntrack_delete conntrack_grp_create ctexp_events conntrack_master expect_create expect_get expect_dump expect_flush expect_create_nat expect_create_userspace expect_delete expect_events"
	TST_TOTAL=`echo $TESTS | wc -w`
	for test in $TESTS; do
	tc_register "Test $test"
	if [ "$test" = "expect_create_nat" ]; then
		./conntrack_flush >$stdout 2>stderr
		tc_fail_if_bad $? "conntrack_flush test failed"
		./$test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	elif [ "$test" = "expect_create_userspace" ]; then
		./conntrack_flush >$stdout 2>$stderr
		tc_fail_if_bad $? "conntrack_flush test failed"
		./$test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	elif [ "$test" = "conntrack_master" ]; then
                ./conntrack_flush >$stdout 2>$stderr
                tc_fail_if_bad_rc $? "conntrack_flush test failed"
                ./$test >$stdout 2>$stderr
                tc_pass_or_fail $? "$test failed"
	elif [ "$test" = "expect_events" ]; then
		./$test >out.txt  &
		for i in 1 2 3 4 5
		do
		./expect_create >$stdout 2>$stderr
		tc_fail_if_bad $? "expect_create test failed"
		./expect_delete >$stdout 2>$stderr
		tc_fail_if_bad $? "expect_delete test failed"
                ./conntrack_flush >$stdout 2>$stderr
		tc_fail_if_bad $? "conntrack_flush test failed"
                done
                grep -q  "TEST: expectation events (OK)" out.txt
                tc_pass_or_fail $? "$test failed"
		rm out.txt -f 
	else
		./$test >$stdout 2>$stderr
                tc_pass_or_fail $? "$test failed"
        fi
	done
	popd >$stdout 2>$stderr
}


#===================
# Main script
#===================
tc_setup && \
run_test

