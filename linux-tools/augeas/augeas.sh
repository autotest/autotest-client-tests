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
## File :        augeas.sh             					      #
##
## Description:  This script tests basic functionality of augeas package       #
##
## Author:       Mithu Ganesan<miganesa@in.ibm.com> 			      #
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/augeas
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/augeas"
REQUIRED="augtool augparse"
pushd $TEST_DIR/tests >& /dev/null
LENSTESTS=`ls lens*.sh`
TOTAL1=`echo $LENSTESTS | wc -w`
AUGTESTS="`find test*.sh -not -name test-interpreter.sh` test-api test-run test-load test-save"
TOTAL2=`echo $AUGTESTS | wc -w`
TST_TOTAL=`expr $((TOTAL1 + TOTAL2)) + 2`
popd >& /dev/null
################################################################################
# Testcase functions
################################################################################

function tc_local_setup()
{
      tc_check_package "augeas"
	tc_break_if_bad $? "augeas package is not installed"
        tc_exec_or_break $REQUIRED
	export abs_top_srcdir=$TEST_DIR
	export abs_top_builddir="$TEST_DIR/tests"
}

function tc_local_cleanup()
{
	id tester &> $stdout 2>$stderr
        [ $? -eq 0 ] && userdel -r tester &> $stdout 2>$stderr
	sudo chown -R root:root ${LTPBIN%/shared}/augeas/tests
	sudo chown -R root:root /tmp
}
function test01()
{       
        echo "Testing augparse tool"
	pushd $TEST_DIR/tests/ >& /dev/null
	tc_register	"test-interpreter.sh"
        ./test-interpreter.sh &> $stdout 2>$stderr
        tc_pass_or_fail $? "test-interpreter.sh FAILED"
        for test in $LENSTESTS; 
	do
	tc_register	"$test"
	./$test &> $stdout 2>$stderr
	tc_pass_or_fail $? "$test FAILED" 
	done
	popd >& /dev/null
}

function test02()
{
	echo "Testing augtool"
	pushd $TEST_DIR/tests/ >& /dev/null
	for test in $AUGTESTS;
        do
        tc_register     "$test"
        ./$test &> $stdout 2>$stderr
	RC=$?
	# test-bug-1.sh test-put-mount-augsave.sh test-save-empty.sh test-save-mode.sh are negative testcases for augtool
	# and are expected to throw stderr, pushing them to /dev/null to prevent the test from failing
	if ( [ "$test" == "test-bug-1.sh" ] && [ $RC -eq 0 ] && [ `cat $stderr | grep -vc "No match for path expression"` -eq 0 ] )
        then
                cat /dev/null > $stderr
        elif ( [ "$test" == "test-put-mount-augsave.sh" ] || [ "$test" == "test-save-empty.sh" ] || [ "$test" == "test-save-mode.sh" ] \
	&& [ $RC -eq 0 ] && [ `cat $stderr | grep -v "Failed to execute command" | grep -vc "saving failed"` -eq 0 ] )
        then
                cat /dev/null > $stderr
        fi	
	tc_pass_or_fail $RC "$test failed"
        done
	popd >& /dev/null

} 
 
function test03()
{
        echo "Testing fadot tool"
        tc_register     "fatest"
        $TEST_DIR/tests/fatest &> $stdout 2>$stderr
        tc_pass_or_fail $? "fatest FAILED"
}

################################################################################
# main
################################################################################
tc_setup  

test01
test02
test03
