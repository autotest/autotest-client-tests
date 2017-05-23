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
### File : pyxattr.sh                                                          ##
##
### Description: This testcase tests the pyxattr package                       ##
##
### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/pyxattr
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/pyxattr/tests"

function tc_local_setup()
{
	# check installation and environment 
      tc_check_package pyxattr
	tc_break_if_bad $? "pyxattr not properly installed"
}

function run_test()
{
	pushd $TESTS_DIR &>/dev/null
	tc_register "Test $test"
	getenforce | grep -iv "Disabled" &>$stdout 2>$stderr
	if [ $? -eq 0 ]; then
		test="test_xattr.py"
	else
		test="test_xattr_selin_disabled.py"
	fi

	python $test &>$stdout 2>$stderr
	if [ $? -eq 0 ]; then
	  grep -q "OK" $stderr
	    if [ $? -eq 0 ]; then
	      cat /dev/null > $stderr
	      tc_pass
	    else
	      tc_fail "Test pyxattr fails" 
	    fi
	else
	  tc_fail "Test pyxattr fails"
	fi
	popd &>/dev/null
}

#
# main
#
TST_TOTAL=1
tc_setup
run_test 
