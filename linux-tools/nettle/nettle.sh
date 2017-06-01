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
### File : nettle                                                              ##
##
### Description: This testcase tests nettle package                            ##
##
### Author:      Athira Rajeev <atrajeev@in.ibm.com>   	                      ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/nettle
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/nettle/testsuite/"
EXDIR="${LTPBIN%/shared}/nettle/examples"
REQUIRED="pkcs1-conv sexp-conv nettle-hash"
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED
      tc_check_package nettle
	tc_fail_if_bad $? "nettle not installed" || return

	cp $TESTDIR/sexp-conv-test $TESTDIR/sexp-conv-test.org
	cp $TESTDIR/pkcs1-conv-test $TESTDIR/pkcs1-conv-test.org
	sed -i "s:../tools/sexp-conv:`which sexp-conv`:g" $TESTDIR/sexp-conv-test
	sed -i 's:../tools/pkcs1-conv:`which pkcs1-conv`:g' $TESTDIR/pkcs1-conv-test

	echo "Test File" >> $TCTMP/testfile
}

function tc_local_cleanup()
{
	mv $TESTDIR/sexp-conv-test.org $TESTDIR/sexp-conv-test
	mv $TESTDIR/pkcs1-conv-test.org $TESTDIR/pkcs1-conv-test 
}
function runtests()
{
	pushd $TESTDIR >$stdout 2>$stderr
	
	# sha1-huge-test takes more time. So
	# excluding the test from run-test
	TESTS=`ls *test| grep -vi sha1-huge-test`
	# Execute the testcase wrapper run-tests
	tc_register "Running nettle testsuite"
	../run-tests $TESTS>$stdout 2>$stderr
	RC=$?
	
	# check for FAILED msg in stderr to determine if test failed"
	grep -q FAIL $stderr
	if [ $? -eq 0 ]; then
		tc_fail "nettle tests failed"
	else
		cat /dev/null > $stderr
		tc_pass_or_fail $RC "nettle tests failed"
	fi
	popd >$stdout 2>$stderr

	pushd $EXDIR >$stdout 2>$stderr
	tc_register "Running nettle example tests"
	TESTS=`ls *test`
	# Execute the testcase wrapper run-tests
	../run-tests $TESTS>$stdout 2>$stderr
	RC=$?
	# check for FAILED msg in stderr to determine if test failed"
	grep -q FAIL $stderr
	if [ $? -eq 0 ]; then
		tc_fail "nettle tests failed"
	else
		cat /dev/null > $stderr
		tc_pass_or_fail $RC "nettle tests failed"
	fi

	tc_register "nettle-hash test"
	nettle-hash -a sha1 $TCTMP/testfile >$stdout 2>$stderr
	tc_fail_if_bad $? "nettle-hash failed"

	savedifs=$IFS ; IFS=" "
	result=`cat $stdout`
	set -- $result
	IFS=$savedifs
	file_name=$1
	while [ $1 ]; do alg=$1; shift; done
	[ $file_name == "$TCTMP/testfile:" ] && [ $alg == sha1 ]
	tc_pass_or_fail $? "nettle-hash failed"
	
}

#
#MAIN
#
TST_TOTAL=3
tc_setup
runtests
