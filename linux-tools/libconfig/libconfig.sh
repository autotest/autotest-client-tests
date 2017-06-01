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
### File :       libconfig.sh                                                  ##
##
### Description: Test for libconfig package                                    ##
##
### Author:      Athira Rajeev <atrajeev@in.ibm.com>                           ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libconfig
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libconfig/test"
FIV_DIR="${LTPBIN%/shared}/libconfig"

function tc_local_setup()
{
      tc_check_package libconfig
	tc_fail_if_bad $? "libconfig not installed" || return

	set `find /usr/lib* -name libconfig\* `
	[ -f $1 ] &&  tc_break_if_bad $? "libconfig C winding not properly installed" 

	set `find /usr/lib* -name libconfig++\* `
	[ -f $1 ] &&  tc_break_if_bad $? "libconfig C++ winding not properly installed"
}

function run_test()
{
	tc_register "libconfig-tests"
	# Execute the tests from the sources
	pushd $FIV_DIR/tests >$stdout 2>$stderr
	./libconfig_tests >$stdout 2>$stderr
	RC=$?
	[ `grep OK $stdout | wc -l` -eq 3 ] && [ `grep FAIL $stdout | wc -l` -eq 0 ] && [ `grep error $stdout | wc -l` -eq 0 ]
	if [ $? -eq 0 ]; then
		tc_pass_or_fail $RC "libconfig-tests failed"
	else
		tc_fail
	fi

	# Execute the tests for C and C++ 
	# From test/c and test/c++
	DIR="c c++"
	set $DIR
	while [ $1 ]; do
	pushd $TESTS_DIR/$1 >$stdout 2>$stderr
	tc_register "libconfig $1 winding tests - Print values"

	# Compare the test output with the exp file
	./example1 >$stdout 2>$stderr
	diff $FIV_DIR/example1-$1-exp $stdout
	tc_pass_or_fail $? "example1 failed"	

	tc_register "libconfig $1 winding tests - update config"

	# Compare the test output with the exp file
	./example2 >$stdout 2>$stderr
	RC=$?
	diff $FIV_DIR/example2-exp updated.cfg
	if [ $? -eq 0 ]; then
		if [ `grep -vc "Updated configuration successfully written" $stderr` -eq 0 ];then cat /dev/null > $stderr; fi 
		tc_pass_or_fail $RC "example2 failed"
	else
		tc_fail
	fi

	tc_register "libconfig $1 winding tests - write config"

	# Compare the test output with the exp file
	./example3 >$stdout 2>$stderr
	RC=$?
	diff $FIV_DIR/example3-$1-exp newconfig.cfg
	if [ $? -eq 0 ]; then
		if [ `grep -vc "New configuration successfully written" $stderr` -eq 0 ];then cat /dev/null > $stderr; fi
		tc_pass_or_fail $RC "example3 failed"
	else
		tc_fail
	fi

	popd >$stdout 2>$stderr
	shift;
	done
}

#
# main
#
tc_setup
TST_TOTAL=7
run_test 
