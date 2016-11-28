#!/bin/bash
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
### File :        xz.sh                                                        ##
##
### Description: This testcase tests xz package                                ##
##
### Author:      Ramesh YR, rameshyr@linux.vnet.ibm.com                        ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/xz
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/xz/tests"

function tc_local_setup()
{
        rpm -q "xz" >$stdout 2>$stderr
	tc_break_if_bad $? "xz package is not installed"

	#making test to use system installed binaries like xz,xzdec instead
	#of refering to binaries present in buildroot i,e xz-version/src/*	
	pushd $TESTS_DIR &>/dev/null
	sed -i 's/\"\$srcdir\"\///' test_files.sh test_compress.sh
	sed -i 's/\$srcdir\///' test_scripts.sh 
	sed -i  's/\.\.\/src\/xz[a-z^\]*\///g' test_files.sh test_compress.sh
	popd $TESTS_DIR &>/dev/null

}

function run_test()
{
        pushd $TESTS_DIR &>/dev/null
        TESTS=`ls test_*`
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
