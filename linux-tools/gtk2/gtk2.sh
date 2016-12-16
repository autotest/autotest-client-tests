#!/bin/bash
## copyright 2003, 2015 IBM Corp                                                          ##
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
## File:         gtk2.sh
##
## Description:  This program tests gtk2
##
## Author:       Athira Rajeev<atrajeev@in.ibm.com>
###########################################################################################
# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/gtk2
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/gtk2"
REQUIRED="Xvfb"
################################################################################
# Testcase functions
################################################################################

function tc_local_setup()
{
    
    rpm -q gtk2 >$stdout 2>$stderr
    tc_break_if_bad $? "gtk2 package is not installed"

    tc_exec_or_break $REQUIRED
    #tests need X-window environment
    Xvfb -ac -noreset -screen 0 800x600x16 :12345 -screen 0 800x600x16 -nolisten tcp -auth & id=$!
    export DISPLAY=:12345
    if [ ! -d "/root/.local/share/" ]; then
    mkdir -p /root/.local/share/
    fi
}

function tc_local_cleanup()
{
    #Stop the Xvfb
    kill $id >$stdout 2>$stderr 

}

function run_test()
{

    pushd $TEST_DIR/tests >$stdout 2>$stderr
    TESTS=`ls`
    TST_TOTAL=`echo $TESTS | wc -w`
    for test in $TESTS; do
        tc_register "Testing $test"
	./$test >/dev/null
        tc_pass_or_fail $? "test failed"
    done
    popd >$stdout 2>$stderr
} 

function test-query-modules()
{
   tc_register "gtk-query-immodules-2.0-64 testing"
   gtk-query-immodules-2.0-64 >$stdout 2>$stderr
   tc_pass_or_fail $? "test failed"

   tc_register "gtk-update-icon-cache"
   gtk-update-icon-cache -v /usr/share/icons/hicolor/ >$stdout 2>$stderr
   tc_pass_or_fail $? "test for gtk-update-icon-cache failed"
}

################################################################################
# main
################################################################################
tc_setup 
run_test
test-query-modules
