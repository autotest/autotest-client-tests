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
## File :        libnfnetlink.sh                                                          ##
##                                                                                        ##
## Description: Test for libnfnetlink package                                             ##
##                                                                                        ##
## Author:      Abhishek Sharma < abhisshm@in.ibm.com >                                   ##
##                                                                                        ##
###########################################################################################


#=============================================
# Global variables used in this script
#=============================================
#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libnfnetlink
source $LTPBIN/tc_utils.source
PKG_NAME="libnfnetlink"
TESTS_DIR="${LTPBIN%/shared}/libnfnetlink/tests"


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
        tc_get_iface
        pushd $TESTS_DIR >$stdout 2>$stderr
        TESTS="`ls`"
        TST_TOTAL=`echo $TESTS | wc -w`
        # One of test is having two possibilities to test it,so testing both the possibilities, increased count as 1
        TST_TOTAL=`expr $TST_TOTAL + 1`
        test="iftest"
             # Test for down device
             tc_register "Test $test-DOWN"
             # Command to fetch only 1st inactive device.
             inactive_device=`ifconfig -a|grep flags|grep -v UP|head -1|awk -F":" '{print $1}'`
             if [ -z "$inactive_device" ];then
             tc_info "No inactive interface found,skipping this test"
             else
             ./$test $inactive_device |grep -wq "NOT RUNNING" >$stdout 2>$stderr
              tc_pass_or_fail $? "$test failed"
             fi
             # Test for UP device
             tc_register "Test $test-UP"
             ./$test $TC_IFACE >$stdout 2>$stderr
             tc_pass_or_fail $? "$test failed"
        popd >$stdout 2>$stderr

}

#===================
# Main script
#===================
tc_setup        #Calling setup function
run_test	# Calling test functions
