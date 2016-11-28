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
## File :	nss-tools.sh
##
## Description:	Tests for nss-tools package.
##
## Author:	Gowri Shankar <gowrishankar.m@in.ibm.com>
###########################################################################################
## source the utility functions

#######cd $(dirname $0)
#LTPBIN="${LTPBIN%/shared}/nss"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
installed="certutil cmsutil crlutil modutil pk12util signtool signver ssltap"
required="echo egrep perl ping"
testroot="${LTPBIN%/shared}/nss"
runtst="${testroot}/nss/tests/all.sh"

# To run individual or set of tests, set nss_tests_list variable.
# If empty, all nss tests will be run. We run tests individually
# for a better reporting and analysis purpose.
nss_tests_list=`grep "^tests=" $runtst | cut -d"=" -f2`
if [[ $nss_tests_list == *"ssl"* ]]
then
  nss_tests_list="ssl ${nss_tests_list/ssl /}"
fi

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return
	tc_find_port || return
}

#
#  run tests from source code to test nss
#
function test_nss()
{
	# environment variables for all the tests
	HOST=localhost
	DOMSUF=localdomain
	PORT=$TC_PORT
	BUILD_OPT=1
	TESTDIR=$TCTMP
	SOFTOKEN_LIB_DIR="/usr/lib"

	tc_get_os_arch 
	[ $TC_OS_ARCH = "x86_64" ] || [ $TC_OS_ARCH = "ppc64" ] || [ $TC_OS_ARCH = "s390x" ] && SOFTOKEN_LIB_DIR="/usr/lib64/"
	
	# do not export TESTDIR if you want to preserve test results.
	# then check tests_results in nss/ .
	export HOST DOMSUF PORT BUILD_OPT TESTDIR SOFTOKEN_LIB_DIR

	# check if platform is 64 bit arch.
	case "$TC_OS_ARCH" in
		x86_64|ppc64|s390x)
			USE_64=1
			;;
		i686|ppc|ppcnf)
			USE_64=0
			;;
		*)
			tc_break "unknown arch found!"
			;;
	esac
	export USE_64

	if [ "$nss_tests_list" = "" ]; then
		tc_register "all nss tests"
		# stderr is expected for few missing output dirs
		$runtst &>$stdout
		# last 25 lines are summary of pass/failure
		tail -25 $stdout >$TCTMP/summary
		cat $TCTMP/summary >$stdout
		cnt=$(egrep -rc '(Failed.*:.*0)' $stdout)
		[ "$cnt" = "2" ]
		tc_pass_or_fail $? "some tests fail"
		return
	fi

	# running tests one by one
	TST_TOTAL=$(echo $nss_tests_list|wc -w)
	for test in $nss_tests_list
	do
		tc_register "$test test"
		export NSS_TESTS="$test"
		# stderr is expected for few missing output dirs
		$runtst &>$stdout
		# last 25 lines are summary of pass/failure
		tail -25 $stdout >$TCTMP/summary
		cat $TCTMP/summary >$stdout
		cnt=$(egrep -rc '(Failed.*:.*0)' $stdout)
		[ "$cnt" = "2" ]
		tc_pass_or_fail $? "$test test fails"
	done
}

################################################################################
# main
################################################################################
TST_TOTAL=1 # plus some more tests
tc_setup 14400
tc_run_me_only_once    # for both nss and nss-tools
test_nss
