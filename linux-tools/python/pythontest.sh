#! /bin/bash
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
#
# File :        pythontest.sh
#
# Description:  Test suite to exhaustively test python
#		Exercises testcases shipped with python
#
# Author:       Robb Romans <robb@austin.ibm.com>
#
################################################################################
# source the standard utility functions
################################################################################
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/python
source $LTPBIN/tc_utils.source
fivtestdir=${LTPBIN%/shared}/python

################################################################################
# global variables
################################################################################
# required executables
REQUIRED="cat grep python"

TFAILCOUNT=0				# test failures
TSKIPCOUNT=0				# tests skipped by $TEST_CMD harness

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || exit

	# Tests are provided by the base python test package; run them from there.
	py_vers=python`python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))'`
	testdir=/usr/lib*/$py_vers/test

	TEST_CMD="$testdir/regrtest.py"	# name of test engine
	# Do away with a static test list in favor of generating one from the test that are installed.
	#WHICH_TESTS="$testdir/../tests.list"	# list of standard and extended module testcases, one per line
	WHICH_TESTS="/tmp/test.list.$$"
	EXCLUDE_TESTS="$fivtestdir/tests.exclude"

	# avoid interference from pyxml package, which will import wrong modules like minidom.py
	mv /usr/lib/$py_vers/site-packages/_xmlplus{,.orig} &>/dev/null
        mv /usr/lib64/$py_vers/site-packages/_xmlplus{,.orig} &>/dev/null

        USE_IPV6_HOST=""
        tc_ipv6_info && {
		[ "$TC_IPV6_host_ADDRS" ] && USE_IPV6_HOST=$TC_IPV6_host_ADDRS
		[ "$TC_IPV6_link_ADDRS" ] && USE_IPV6_HOST=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
		[ "$TC_IPV6_global_ADDRS" ] && USE_IPV6_HOST=$TC_IPV6_global_ADDRS
		export USE_IPV6_HOST=$(tc_ipv6_normalize $USE_IPV6_HOST)
	}
	[ "$USE_IPV6_HOST" = "" ] && sed -i '/^test_socket_ipv6.py/ d' $WHICH_TESTS

        tc_find_port
        USE_PORT=$TC_PORT
        tc_break_if_bad $? "Could not find available port" || exit
        export USE_PORT
	
	pushd $testdir &>/dev/null
	patch -p0 <$fivtestdir/mcpbug-96332-regrtest.diff
	popd &>/dev/null
}

#
# Parameters:	$1  tcname
#				$2	output file to check
#
function passfail()
{
	if [ "$(grep OK $2)" ] ; then
		tc_pass_or_fail 0 "$1"	# always passes
	elif [ "$(grep skipped $2)" ] ; then
		if [ "$(grep expected $2)" ] ; then
			let TSKIPPEDCOUNT+=1
			tc_info "$1 has been skipped on this platform (expected)."
		else
			let TFAILCOUNT+=1
			tc_pass_or_fail 1 "Failed"$'\n'"$(cat $2)"
		fi
	else
		let TFAILCOUNT+=1
		tc_pass_or_fail 1 "Failed"$'\n'"$(cat $2)"
	fi
}

# Function run_test
#
# Description	- run all python standard testcases
#
# Parameters:	- $1 testcase command
#				- $2 testcase to run
#
# Return	- zero on success
#		- return value from testcase on failure ($RC)

function run_test {
	pushd $testdir &>/dev/null
	tc_register $2
	$1 $2 &> $TCTMP/$2.out
	passfail $2 $TCTMP/$2.out
	popd &>/dev/null
}

function tc_local_cleanup()
{
	pushd $testdir &>/dev/null
	patch -p0 -R <$fivtestdir/mcpbug-96332-regrtest.diff
	popd &>/dev/null
}
################################################################################
# main
################################################################################
TST_TOTAL=1

tc_setup

for f in `find $testdir -type f -name 'test_*\.py'`; do basename $f; done > $WHICH_TESTS
# verfiy a single subpackage of python
if [ $# -eq 1 ]; then
	if [ $1 == "curses" ]; then
		tc_info "cannot run under PAN framwork, since it's tty related"
		tc_info "please run './regrtest.py -u curses test_curses.py' at shell prompt"
		exit
	elif [ $1 == "gdbm" ]; then
		run_test $TEST_CMD test_$1
	elif [ $1 == "xml" ]; then  # refer to xmltest.py
		run_test $TEST_CMD test_minidom
		run_test $TEST_CMD test_pyexpat
		run_test $TEST_CMD test_sax
		run_test $TEST_CMD test_xmllib
		run_test $TEST_CMD test_xmlrpc
		mv /usr/lib/$py_vers/site-packages/_xmlplus{.orig,} &>/dev/null
		mv /usr/lib64/$py_vers/site-packages/_xmlplus{.orig,} &>/dev/null
	else
		tc_fail_if_bad $? "Unknown argument: $1" 
	fi
	exit
fi

# now verify python standard modules and shipped extended modules
if [ $# -ne 0 ] ; then
	tc_fail_if_bad $? "Unknown argument: $@" 
	exit
fi

tc_info "$TCID: Starting standard and extended modules test."

while read line ; do
	[ "$line" ] && set $line && [ "$1" = "#" ] && continue # skip comment line
        # Check the list of tests to exclude and skip this test if its found.
        grep -q $line $EXCLUDE_TESTS && tc_info "$line found in $EXCLUDE_TESTS: skipping" && continue
	run_test $TEST_CMD $line
done <$WHICH_TESTS

mv /usr/lib/$py_vers/site-packages/_xmlplus{.orig,} &>/dev/null
mv /usr/lib64/$py_vers/site-packages/_xmlplus{.orig,} &>/dev/null

[ -f $WHICH_TESTS ] && rm $WHICH_TESTS
tc_info "$TFAILCOUNT tests failed"
tc_info "$TSKIPPEDCOUNT tests skipped (expected)."
