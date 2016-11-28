#!/bin/sh
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
### File       : harfbuzz.sh                                                   ##
##
### Description: This testcase tests "harfbuzz" package                        ##
##
### Author     : Ramesh YR, rameshyr@linux.vnet.ibm.com                        ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/harfbuzz
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/harfbuzz/tests"
REQUIRED="rpm"

function tc_local_setup()
{
    ls /usr/lib*/libharfbuzz.so* &>/dev/null
    tc_break_if_bad $? "harfbuzz package is not installed" || return
    tc_exec_or_break $REQUIRED
}

function run_test()
{
    pushd $TESTS_DIR &>/dev/null
    TESTS=`ls | grep -v "test-unicode"`
    
    for test in $TESTS;do
    {
      tc_register "Test $test"
      ./$test >$stdout 2>$stderr
      tc_pass_or_fail $? "Test failed"
    }
    done

    tc_register "Test test-unicode"
    rpm -q harfbuzz-icu &>/dev/null
    if [ $? -eq 0 ];then
       ./test-unicode >$stdout 2>$stderr
       tc_pass_or_fail $? "Test failed"
    else
       tc_info "test-unicode: skipped as harfbuzz-icu is not installed !"
    fi
    popd &>/dev/null
}

#
# main
#
tc_setup && \
run_test
