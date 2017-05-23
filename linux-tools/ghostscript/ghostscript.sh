#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
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
### File :       ghostscript.sh                                           ##
##
### Description: Test for ghostscript package                             ##
##
### Author:      Basheer Khadarsabgari<bkhadars@in.ibm.com>                     ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/ghostscript
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/ghostscript/tiff/test"
REQUIRED="bash"

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return 
}

function install_check()
{
      tc_check_package ghostscript
	tc_break_if_bad $? "ghostscript not installed"
	sed -i -e 's/^TOOLS/#TOOLS/' $TESTS_DIR/common.sh
	export TOOLS="/usr/bin"
}

function tc_local_cleanup()
{
	unset TOOLS
}

function run_test()
{
	pushd $TESTS_DIR >$stdout 2>$stderr
	TEST_SCRIPTS=`ls *.sh`
	TEST_BINARIES=`find . -type f  -executable -exec file -i '{}' \; | grep 'x-executable; charset=binary' | cut -d':' -f1`
	TOTAL_SCRIPTS=`ls *.sh | wc -w`
	TOTAL_BIN=`echo $TEST_BINARIES | wc -w`
	TST_TOTAL=`expr $TOTAL_SCRIPTS + $TOTAL_BIN` 
	for test in $TEST_SCRIPTS; do
		tc_register "Test $test" 
		if [ "$test" == "tiffcp-thumbnail.sh" ];then
			./$test >$stdout 2>$stderr
			RC=$?
			grep -iq "fail" $stderr
			RC1=$?
			if [ $RC -eq 1 ] || [ $RC1 -eq 0 ];then
				RC=1
			else
				tc_ignore_warnings "^$\|^bpr=20\|"
			fi
		else
			./$test >$stdout 2>$stderr
			RC=$?
                fi
		tc_pass_or_fail $RC "$test failed"
	done
        for test in $TEST_BINARIES; do
                tc_register "Test $test"
                ./$test >$stdout 2>$stderr
                tc_pass_or_fail $? "$test failed"
        done
	popd >$stdout 2>$stderr
}

#
# main
#
tc_setup
install_check && run_test 
