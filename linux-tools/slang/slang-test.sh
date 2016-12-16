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
### File :       slang-test.sh                                                 ##
##
### Description: This testcase tests slang package                             ##
##
### Author:      Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                      ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/slang
source $LTPBIN/tc_utils.source
SLANG_TESTS_DIR="${LTPBIN%/shared}/slang/test"


function tc_local_setup()
{
    # check installation and environment
    [ -f /usr/lib*/libslang.so.2 ]
    tc_break_if_bad $? "slang not installed" || return
   
    # Modify some scripts to run from here 
    sed -i '\_../../slsh/lib_s_../__' $SLANG_TESTS_DIR/req.sl
    sed -i '\_../../doc/text_s_../__' $SLANG_TESTS_DIR/docfun.sl
}

function run_test()
{
    pushd $SLANG_TESTS_DIR &>/dev/null
    # Some .sl scripts are special purpose and not tests
    # strops.sl and utf8.sl failing beacuse of gcc 4.8 issue.
    EXCLUDE_LIST="reqfoo.sl inc.sl leak.sl strops.sl utf8.sl"
    TEST_SCRIPTS=`ls *.sl`
    for i in $EXCLUDE_LIST; do
	TEST_SCRIPTS=${TEST_SCRIPTS/$i}
    done
    TST_TOTAL=`echo $TEST_SCRIPTS | wc -w`
    for test in $TEST_SCRIPTS; do
        tc_register "Testing $test"
        ./sltest $test >$stdout 2>$stderr
        [ $? -ne 0 ] && [ $test == "bugs.sl" ]
                grep -q "Known Bugs or not yet implemented features" $stdout
                if [ $? -eq 0 ];
                then
                        tc_info "$test: Known Bugs or not yet implemented features"
                        continue
                fi
        grep -q "Ok" $stdout
        tc_fail_if_bad $? "$test fail" || continue
        ./sltest -utf8 $test >$stdout 2>$stderr
        grep -q "Ok" $stdout
        tc_pass_or_fail $? "$test with utf8 fail"
    done
    popd &>/dev/null
}

#
# main
#
tc_setup
TST_TOTAL=1
run_test 
