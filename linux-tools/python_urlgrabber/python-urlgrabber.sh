#!/bin/bash
###########################################################################################
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
##                                                                            ##
## File :        python-urlgrabber.sh                                         ##
##                                                                            ##
## Description: This testcase tests python-urlgrabber package                 ##
##                                                                            ##
## Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
##                                                                            ##
################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
URLGRABBER_TESTS_DIR="${LTPBIN%/shared}/python_urlgrabber/test"

required="urlgrabber python"

function tc_local_setup()
{
	# check installation and environment 
	tc_exec_or_break $required || return  
}

function run_test()
{
	tc_register "python-urlgrabber tests"
	pushd $URLGRABBER_TESTS_DIR &>/dev/null 
	python runtests.py >$stdout 2>$stderr
	grep -q FAILED $stdout || grep -q FAIL
	[ $? -eq 0 ] && {

        ## This is a workaround for https://bugzilla.linux.ibm.com/show_bug.cgi?id=78855#c12
        ## We get write callback error from pycurl in stderr while executing interrupt
        ## callback tests and our test framework catch that for which we get a FAIL.
        ## Workaround is to remove those write callback errors from stderr if any from the
        ## interrupt callback tests as it is not an issue with python-urlgrabber.
        ## To identify the callback error only from interrupt callback tests we are printing
        ## our custom message to stderr using the below patch
        ## ibmbug78855-print_to_stderr_in_interrupt_callback_tests.diff

	write_callback_error=`grep -c 'interrupt callback tests' $stderr`
	write_invalid_value=`grep -c 'invalid return value for write callback -1' $stderr` 
	count=`expr $write_callback_error + $write_invalid_value`             
	[ $count -ge 2 ] && \
             sed -i '/interrupt callback tests start/, /interrupt callback tests end/d' $stderr
    	}
    	tc_pass_or_fail $? "python-urlgrabber test failed" 
	popd &>/dev/null
}

#
# main
#
tc_setup
TST_TOTAL=1
run_test 
