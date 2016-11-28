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
## File :        gamin.sh                                                     ##
##                                                                            ##
## Description:  Gamin is a monitoring system for files and directories that  ##
##               independently implements a subset of FAM                     ##
##                                                                            ##
## Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
##                                                                            ##
################################################################################

# source the utility functions
#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/gamin
source $LTPBIN/tc_utils.source
GAMIN_TEST_DIR="${LTPBIN%/shared}/gamin/tests"

function tc_local_setup()
{
    rpm -q gamin >$stdout 2>$stderr 
    tc_break_if_bad $? "gamin not installed" || return 
    rm -rf /tmp/test_gamin 
}

function run_test()
{
   pushd $GAMIN_TEST_DIR &> /dev/null
   TESTS=`ls scenario/*.tst`
  
   TST_TOTAL=`echo $TESTS | wc -w`  
   for test in $TESTS; do 
       tc_register "Testing $test"
       #In the loop if any of the testacse  fails, the presence of
       #/tmp/test_gamin make all the succeeding tests fail, as there
       # is no clean up. So removing.
       rm -rf /tmp/test_gamin
	
       ./testgam $test >$stdout 2>$stderr
       rc=$?
       if [ `grep -ivc "end from FAM server connection"  $stderr` -eq 0 ];
       then
            cat /dev/null > $stderr
       fi
       tc_pass_or_fail $rc "$test failed" 
   done
   popd &> /dev/null 
}

#################################################################################
#         main
#################################################################################

tc_setup
run_test

