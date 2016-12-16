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
## File :	libxml2-python.sh
##
## Description:	Tests the libxml2 binding for python
##
## Author:	Suzuki K P <suzukikp@in.ibm.com>
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libxml2
TESTDIR=${LTPBIN%/shared}/libxml2/libxml2-tests/python/tests/

source $LTPBIN/tc_utils.source

function tc_local_setup()
{
	tc_executes "python" || tc_break
}

function test_installation ()
{
	tc_register "Installation check"

	for file in drv_libxml2.py libxml2.py libxml2mod.so;
	do
		find /usr/lib /usr/lib64 -name $file 2>/dev/null >$stdout;
		grep -q $file $stdout
		tc_fail_if_bad $? "file : $file not found" || return
	done

#       For  future 
#
#	[ -d /usr/share/doc/packages/libxml2-python/tests/ ] && {
#		find /usr/share/doc/packages/libxml2-python/tests/ -name *.py &>/dev/null
#		if [ $? -eq 0 ];
#		then
#			#TESTDIR=/usr/share/doc/packages/libxml2-python/tests
#			tc_info "Using tests from $TESTDIR"
#		fi
#	}

	tc_pass
}

# Add the broken tests here 
BROKEN_TESTS="reader5.py"
#reader5.py requires a file not present in the package !

function run_tests()
{
	cd $TESTDIR

	for file in `find . -name \*.py`;
	do
		test=`basename $file`

		if [ "${BROKEN_TESTS/$test}" != "$BROKEN_TESTS" ];
		then
			tc_info "$test is skipped (broken)" && continue
		fi

		tc_register "`basename $test`"
		python $test >$stdout 2>$stderr && grep -q OK $stdout 
		tc_pass_or_fail $? "Unexpected failure. (Should see OK in stdout)" 
	done
}

tc_setup

test_installation &&
run_tests
