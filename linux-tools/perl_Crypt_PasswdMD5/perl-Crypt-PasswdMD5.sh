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
### File :        perl-Crypt-PasswdMD5                                         ##
##
### Description: This testcase tests perl-Crypt-PasswdMD                       ##
##
### Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/perl_Crypt_PasswdMD5/t"
REQUIRED="perl"

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return

	[ -f /usr/share/perl*/vendor_perl/Crypt/PasswdMD5.pm ]
	tc_break_if_bad $? "perl-Crypt-PasswdMD5 not installed"
}

function run_test()
{
	pushd $TESTS_DIR &>/dev/null
	all_tests=`ls *.t`
	TST_TOTAL=`echo $all_tests | wc -w`
	for test in $all_tests; do
		tc_register "${test%%.t} test"
		perl $test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	done
	popd &>/dev/null
}

#
# main
#
# set TST_TOTAL in run_test
tc_setup
run_test 
