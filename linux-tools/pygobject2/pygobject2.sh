#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##    1.Redistributions of source code must retain the above copyright notice,            ##
##        this list of conditions and the following disclaimer.                           ##
##    2.Redistributions in binary form must reproduce the above copyright notice, this    ##
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
## File : pygobject2                                                          
##                                                                            
## Description: This testcase tests pygobject2 package                                     
##                                                                            
## Author:      Athira Rajeev <atrajeev@in.ibm.com>   	                      
##                                                                            
############################################################################################
######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/pygobject2
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/pygobject2/tests"
REQUIRED="python"
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED
      tc_check_package pygobject2
	tc_fail_if_bad $? "pygobject2 not installed" || return
	
	#Excluding test_gi.py, test_overrides.py, test_gdbus.py, test_everything.py because
	#there tests "gi" which stands for ( GObject Introspection) and this feature is
	#provided by pygobject3 package.
	pushd $TESTDIR >$stdout 2>$stderr
	TESTS=`ls test_gi.py test_overrides.py test_gdbus.py test_everything.py`
	for test in $TESTS; do
		rm -rf $test
	done
	popd >$stdout 2>$stderr
}

function runtests()
{
	pushd $TESTDIR >$stdout 2>$stderr
	
	TESTS=`ls test_*.py`
	TST_TOTAL=`echo $TESTS | wc -w`
	for t in $TESTS; do
		tc_register "Running test $t"
		python runtests.py $t 1>$stdout 2>$stderr
		if [ $? -eq 0 ]; then
			grep -q FAILED $stderr
			if [ $? -eq 0 ]; then
				tc_fail "pygobject2 failed, check logs"
			else
				cat /dev/null > $stderr
				tc_pass
			fi
		else
			 tc_fail "pygobject2 failed"
		fi
		sleep 2
	done
	popd >$stdout 2>$stderr
}

#
#MAIN
#
tc_setup
runtests

