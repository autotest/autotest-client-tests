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
### File :       gdisk.sh                                                     ##
##											  ##
### Description: Test for gdisk  package                             	  ##
##
### Author:      Basheer K<basheer@linux.in.ibm.com>                                      ##
############################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/gdisk
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/gdisk"
REQUIRED="rpm"
TESTCASE="gdisk_test.sh"

function tc_local_setup()
{
        tc_exec_or_break $REQUIRED || return
}

function install_check()
{
	rpm -q gdisk >$stdout 2>$stderr 
	tc_break_if_bad $? "gdisk not installed"

	sed -i  's:\./gdisk:/usr/sbin/gdisk:' ${TESTS_DIR}/${TESTCASE}
	sed -i  's:\./sgdisk:/usr/sbin/sgdisk:' ${TESTS_DIR}/${TESTCASE}
}

function run_test()
{
	pushd $TESTS_DIR >$stdout 2>$stderr
	TESTS=`ls gdisk_test.sh`
	TST_TOTAL=`echo $TESTS | wc -w` 
	for test in $TESTS; do
		tc_register "Test $test" 
		bash $test >$stdout 2>$stderr 
		RC=$?
		grep -iq "FAILED" $stdout
		RC1=$?
		if [ $RC -ne 0 ] || [ $RC1 -eq 0 ];then
			RC=1
		else
			tc_ignore_warnings "^$\|65536+0 records in\|65536+0 records out\|67108864 bytes (67 MB) copied, 0.162915 s, 412 MB\/s\|"
		fi
		tc_pass_or_fail $RC "$test failed"
	done
	popd >$stdout 2>$stderr
}

#
# main
#
tc_setup
install_check && run_test

