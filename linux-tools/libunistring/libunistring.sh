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
### File : libunistring                                                        ##
##
### Description: This testcase tests libunistring package                      ##
##
### Author:      Athira Rajeev <atrajeev@in.ibm.com>                           ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libunistring
source $LTPBIN/tc_utils.source
FIV_DIR="${LTPBIN%/shared}/libunistring"
TESTDIR="${LTPBIN%/shared}/libunistring/tests"
function tc_local_setup()
{
	cp -r $TESTDIR $TESTDIR.org
	
	# Replace srcdir with current dir
	pushd $FIV_DIR >$stdout 2>$stderr
	TESTS_SH=`find $TESTDIR -type f -name test*.sh`
	set $TESTS_SH
	while [ $1 ]; do
		# set the path of srcdir to $TESTDIR/tests
		sed -i 's:$srcdir:$(pwd):' $1
		shift
	done
	popd >$stdout 2>$stderr
}
function tc_local_cleanup()
{
	rm -rf $TESTDIR
	mv $FIV_DIR/tests.org $FIV_DIR/tests
}
function install_check()
{
        tc_register "Installation check"
        rpm -q libunistring >$stdout 2>$stderr
        tc_pass_or_fail $? "libunistring not installed"
}


function runtests()
{
	pushd $FIV_DIR >$stdout 2>$stderr
	# find the tests which are to be called not from .libs
	TESTS_SH=`find $TESTDIR -type f -name test-*.sh`
	
	popd >$stdout 2>$stderr

	# Execute the tests
	pushd $TESTDIR >$stdout 2>$stderr

	# Ignore the test binaries used in .sh wrapper scripts
	TESTS=`find .libs -type f -not -name "lt-test*" \
	-not -name test-u32-nfd-big -not -name "test*vasnprintf2" \
	-not -name "test-*vasnprintf3" \
	-not -name test-ulc-wordbreaks -not -name "test-u32-*-big" \
	-not -name test-uninames -not -name libtest* -not -name test-xalloc-die \
	-not -name test-mbrtowc -not -name test-ulc-casecmp -not -name test-locale-language`
	
	# Execute the tests 
	TST_TOTAL=`echo $TESTS | wc -w`
	TST_TOTAL_SH=`echo $TESTS_SH | wc -w`
	TST_TOTAL=`expr $TST_TOTAL_SH+$TST_TOTAL`
	for test in $TESTS; do
		tc_register "Test $test"
		$test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	done
	
	# Execute the wrapper scripts
	for test in $TESTS_SH; do
		tc_register "Test $test"
		$test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	done 
	popd >$stdout 2>$stderr
}

#
#MAIN
#
tc_setup
install_check &&
runtests
