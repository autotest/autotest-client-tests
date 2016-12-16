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
### File : python-decorator.sh                                                 ##
##
### Description: This testcase tests the libdrm package                        ##
##
### Author: Snehal Phule <snehal.phule@in.ibm.com>                             ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/python_decorator
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/python_decorator"

#Global Variables
oldline='from setup import VERSION'
python_decorator_ver=`rpm -q --info python-decorator | awk '/Version/ {print $NF}'`
newline="VERSION='$python_decorator_ver'"
test=0

function tc_local_setup()
{
        rpm -q python-decorator >$stdout 2>$stderr
        tc_break_if_bad $? "python-decorator package is not installed properly"

	# Check python version and run the test accordingly as per README
	python_version=`rpm -q --info python | awk '/Version/ {print $3}'`
	if [[ $python_version < 3 ]] 
	then
		test=documentation.py
	else
		test=documentation3.py
	fi
        sed -i "s%$oldline%$newline%g" $TESTS_DIR/$test

}

function tc_local_cleanup()
{
        sed -i "s%$newline%$oldline%g" $TESTS_DIR/$test
}

function run_test()
{
        pushd $TESTS_DIR >$stdout 2>$stderr
        tc_register "Test $test"
        python $test 1>$stdout 2>$stderr
        tc_pass_or_fail $? "$test failed"
        popd >$stdout 2>$stderr
}
#
#
TST_TOTAL=1
tc_setup
run_test
