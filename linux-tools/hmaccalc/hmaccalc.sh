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
### File : hmaccalc                                                            ##
##
### Description: This testcase tests hmaccalc package                          ##
##
### Author:      Athira Rajeev <atrajeev@in.ibm.com>   	                      ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/hmaccalc
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/hmaccalc/test"
REQUIRED="sha1hmac sha256hmac sha384hmac sha512hmac prelink"
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED
      tc_check_package hmaccalc
	tc_fail_if_bad $? "hmaccalc not installed" || return

	set `find /usr/lib* -name hmaccalc\* `
	[ -f $1 ] &&  tc_break_if_bad $? "hmaccalc not properly installed"
	echo "test file for hmaccalc" >> $TCTMP/testfile
	chmod +x $TCTMP/testfile
}

function runtests()
{
	pushd $TESTDIR >$stdout 2>$stderr
	
	# Executing the testsuite
	# Execute the testcase wrapper run-tests
	tc_register "Running hmaccalc testsuite"
	./run-tests.sh >$stdout 2>$stderr
	RC=$?
	
	grep -q OK $stdout
	if [ $? -eq 0 ]; then
		tc_pass_or_fail $RC "hmaccalc tests failed"
	else
		tc_fail "hmaccalc tests failed"
	fi

	# Prelink the binaries and see if sha*hmac
	# locates the prelink at runtime
	sha1hmac_bin=`which sha1hmac`
	sha256hmac_bin=`which sha256hmac`
	sha384hmac_bin=`which sha384hmac`
	sha512hmac_bin=`which sha512hmac`
	tc_register "Running hmaccalc testsuite after prelinking sha*mac binaries"
	prelink $sha1hmac_bin $sha256hmac_bin $sha384hmac_bin $sha512hmac_bin >$stdout 2>$stderr
	tc_fail_if_bad $? "failed to prelink" || return
	./run-tests.sh >$stdout 2>$stderr
	RC=$?
	
	grep -q OK $stdout
	if [ $? -eq 0 ]; then
		tc_pass_or_fail $RC "hmaccalc tests failed"
	else
		tc_fail "hmaccalc tests failed"
	fi
	popd >$stdout 2>$stderr

	# unlink the binaries
	prelink -u $sha1hmac_bin $sha256hmac_bin $sha384hmac_bin $sha512hmac_bin >$stdout 2>$stderr
	tc_fail_if_bad $? "failed to unlink prelink" || return

	# Testing sha*hmac -P option
	# which will unprelink before computing.
	TESTS="sha1hmac sha256hmac sha384hmac sha512hmac"
	for t in $TESTS
	do
		# val_before_prelink has the HMAC value without prelink
		tc_register "$t -P $sha1hmac_bin"
		val_before_prelink=`$t $sha1hmac_bin`
		savedifs=$IFS ; IFS=" "
		set -- $val_before_prelink
		val_before_prelink=$1

		# now prelink the binary
		prelink $sha1hmac_bin >$stdout 2>$stderr
		tc_fail_if_bad $? "failed to prelink $sha1hmac_bin" || return

		# val_with_unlink has the HMAC calculated with
		# sha*hmac -P which should be same as val_before_prelink
		val_with_unlink=`$t -P $sha1hmac_bin`
		set -- $val_with_unlink
		val_with_unlink=$1

		# unlink the binary
		prelink -u  $sha1hmac_bin >$stdout 2>$stderr
		IFS=$savedifs
		tc_fail_if_bad $? "Failed to unlink" || return
		[ $val_with_unlink == $val_before_prelink ]
		tc_pass_or_fail $? "$t -P failed"
	done
	
	# Test for sha*hmac -S
	# This outputs self-test MAC on stdout
	# which will be same as contents
	# of /usr/lib*/hmaccalc/sha*hmac.hmac
	TESTS="sha1hmac sha256hmac sha384hmac sha512hmac"
	for t in $TESTS
	do
		lib_name=`find /usr/lib* -name $t.hmac`
		tc_register "$t -S - self test"
		$t -S >$stdout 2>$stderr
		RC=$?
		results=`cat $stdout`
		file_cont=`cat $lib_name`
		[ $results == $file_cont ]
		if [ $? -eq 0 ]; then
			tc_pass_or_fail $RC "$t self test failed"
		else
			tc_fail "$t self test failed"
		fi
	done

	# Test sha*hmac -h which uses 
	# the specified hash algorithm
	tc_register "sha1hmac -h"
	sha1hmac $TCTMP/testfile -h sha256 >$stdout 2>$stderr
	tc_fail_if_bad $? "sha1hmac -h failed"
	
	# compare the hash output with sha256 HMAC
	savedifs=$IFS ; IFS=" "
	result=`cat $stdout`
	set -- $result
	IFS=$savedifs
	hash=$1
	[ $hash == "d09203455acec8f40dadc07b4e3a350f9b96be88615a1f6d7b68fe935f4636bb" ]
	tc_pass_or_fail $? "sha1hmac -h failed"

	# Testing sha*hmac -u
	# which compute an unkeyed digest
	TESTS="sha1hmac sha256hmac sha384hmac sha512hmac"
	for t in $TESTS
	do
		tc_register "$t -u"
		$t -u $TCTMP/testfile >$stdout 2>$stderr
		tc_pass_or_fail $? "$t -u failed"
	done

}
#
#MAIN
#
TST_TOTAL=15
tc_setup
runtests
