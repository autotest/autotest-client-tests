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
## File :       libmnl.sh                                                                 ##
##                                                                                        ##
## Description: Test for libmnl package                                                   ##
##                                                                                        ##
## Author:      Abhishek Sharma < abhisshm@in.ibm.com >                                   ##
##                                                                                        ##
###########################################################################################


#=============================================
# Global variables used in this script
#=============================================
#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libmnl
source $LTPBIN/tc_utils.source
PKG_NAME="libmnl"
TESTS_DIR="${LTPBIN%/shared}/libmnl/tests"


#=====================================================
# Function to check prerequisites to run this test
#=====================================================
function tc_local_setup()
{
	rpm -q $PKG_NAME >$stdout 2>$stderr
        tc_break_if_bad $? "$PKG_NAME is not installed"
}

#==================================================================
# Run the test suites which are available on tests/t directory
#==================================================================
function run_test()
{
        pushd $TESTS_DIR >$stdout 2>$stderr
        TESTS="genl-family-get rtnl-link-dump rtnl-link-dump2 rtnl-link-dump3 rtnl-link-set rtnl-route-dump"
        TST_TOTAL=`echo $TESTS | wc -w`
        # One of test is having two possibilities to test it,so testing both the possibilities, increased count as 1
        TST_TOTAL=`expr $TST_TOTAL + 1`
        for test in $TESTS; do
		# rtnl-link-set test has two possibilities to test it, i.e <eth_type> [ up / down ]
                if [ $test = "rtnl-link-set" ]; then
                        # Test for down
                        tc_register "Test $test-DOWN"
                        ./$test lo down >$stdout 2>$stderr
                        tc_pass_or_fail $? "$test failed"
                        # Test for UP
                        tc_register "Test $test-UP"
                        ./$test lo up >$stdout 2>$stderr
                        tc_pass_or_fail $? "$test failed"
                        continue
                fi
                tc_register "Test $test"
                ./$test  >$stdout 2>$stderr
                tc_pass_or_fail $? "$test failed"
        done
        popd >$stdout 2>$stderr

}


#===================
# Main script
#===================
tc_setup        #Calling setup function
run_test	# Calling test functions
