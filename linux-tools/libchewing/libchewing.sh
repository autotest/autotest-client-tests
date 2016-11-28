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
## File :       libchewing.sh                                                             ##
##                                                                                        ##
## Description: Test for libchewing package                                               ##
##                                                                                        ##
## Author:      Abhishek Sharma < abhisshm@in.ibm.com >                                   ##
##                                                                                        ##
###########################################################################################


#=============================================
# Global variables used in this script
#=============================================
#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libchewing
source $LTPBIN/tc_utils.source
PKG_NAME="libchewing"
TESTS_DIR="${LTPBIN%/shared}/libchewing/tests"


#=====================================================
# Function to check prerequisites to run this test
#=====================================================
function tc_local_setup()
{
        rpm -q $PKG_NAME >$stdout 2>$stderr
        tc_break_if_bad $? "$PKG_NAME is not installed"
	# Creating a input file for simulate test.
	touch $TESTS_DIR/materials.txt
}


#==================================================================
# Run the test suites which are available on test/t directory
#==================================================================
function run_test()
{
        pushd $TESTS_DIR >$stdout 2>$stderr
	# tests directory will contail ".c" and ".o" files too, to avoid this I am only putting binary file name.
        TESTS="testchewing simulate randkeystroke test-config test-easy-symbol test-fullshape test-key2pho test-keyboard test-mmap test-path test-reset test-regression test-symbol test-special-symbol test-utf8"
        TST_TOTAL=`echo $TESTS | wc -w`
        for test in $TESTS; do
                tc_register "Test $test"
                if [ $test = "testchewing" ];
		then
			cat materials.txt|./testchewing >$stdout 2>$stderr
			tc_pass_or_fail $? "$test failed"
			continue
		fi
                ./$test >$stdout 2>$stderr
                tc_pass_or_fail $? "$test failed"
        done
        popd >$stdout 2>$stderr

}


#===================
# Main script
#===================
tc_setup        #Calling setup function
run_test	# Calling test functions
