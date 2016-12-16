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
### File :        libart_lgpl.sh                                               ##
##
### Description: This testcase tests libart_lgpl  package                      ##
##
### Author:      Madhuri Appana <maappana@in.ibm.com>                          ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libart_lgpl
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libart_lgpl/Tests"

function tc_local_setup()
{
	tc_exec_or_break vncserver
        rpm -q "libart_lgpl" >$stdout 2>$stderr
        tc_break_if_bad $? "libart_lgpl package is not installed"
}

function run_test()
{
        pushd $TESTS_DIR &>/dev/null
	for arg in testpat gradient dash intersect
	do
        	tc_register "Test the functionality of libart api's using testart $arg"
        	./testart $arg >$stdout 2>$stderr
        	tc_pass_or_fail $? "testart with $arg failed"
	done
        tc_register "Test the functionality of testuta"
        ./testuta  >$stdout 2>$stderr
       	tc_pass_or_fail $? "testuta failed"
        popd &>/dev/null
}
#
# main
#
TST_TOTAL=5
tc_setup
run_test 
