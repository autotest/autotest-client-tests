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
## File :	elfutils.sh
##
## Description:	test of elfutils package
##
## Author:	Suzuki K P
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/elfutils/elfutils-tests/

################################################################################
# utility functions
################################################################################

#
# Setup specific to this test
#
function tc_local_setup()
{
	[ -d $TESTDIR ]
	tc_fail_if_bad $? "Tests are not installed. Please install elfutils-tests rpm"
	# The tests expects srcdir to be set
	export srcdir=$TESTDIR
	Libpath=$(find /usr/lib/ /usr/lib64/ -name libelf.so.\* | head -n 1)
	if [ "$Libpath" == "" ]; then
		tc_fail "Unable to find libelf.so.* library"
		return
	fi
	# Following paths are needed for running the tests
	export libdir=$(dirname $Libpath)
	export bindir=/usr/bin
	# Change the shell to bash so that code can work on ubuntu too
	sed  -i "1s/.*/#\!\/bin\/bash/" $TESTDIR/test-wrapper.sh
}
 
#
# Cleanup specific to this program
#
function tc_local_cleanup()
{
	# have nothing to do
	return 0
}

function run_test()
{
	test=$1
	if [ ! -f $TESTDIR/$test ];then
		tc_info "$test is missing" || return
	fi
	tc_register "$test"
	( cd $TESTDIR; ./test-wrapper.sh installed ./$test >$stdout 2>$stderr )
	tc_pass_or_fail $? 
}	
################################################################################
# MAIN
################################################################################


tc_setup
# This can test several packages. so run only once
tc_run_me_only_once

# TESTS file has the individual tests to run
# The TESTS file was created from the "make check" output
# on the package.
for t in $(cat $TESTDIR/../TESTS)
do
	run_test $t
done
