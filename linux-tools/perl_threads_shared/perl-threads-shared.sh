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
### File : perl-threads-shared					     	      ##
##
### Description: This testcase tests perl-threads-shared package     	      ##
##
### Author:      Ravindran Arani <ravi@linux.vnet.ibm.com>                     ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_threads_shared
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/perl_threads_shared/"

function tc_local_setup()
{
       tc_check_package perl-threads-shared
	tc_break_if_bad $? "perl-threads-shared is not installed"
}

function runtests()
{
	pushd $TESTDIR >$stdout 2>$stderr
	TST_TOTAL=`ls -1 t/*.t|wc -l`
	for test in `ls t/*.t`
	do
	tc_register "Test ${test:2:-2}"
	PERL_DL_NONLAZY=1
	perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" $test >$stdout 2>$stderr
	RC=$?
	tc_ignore_warnings "Testing threads"
	tc_pass_or_fail $RC "${test:2:-2} failed"
	done
	popd >$stdout 2>$stderr
} 

#
#MAIN
#
tc_setup
runtests
