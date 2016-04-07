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
##                                                                            ##
## File : checkpolicy.sh                                                      ##
##                                                                            ##
## Description: This testcase tests the checkpolicy package                   ##
##                                                                            ##
## Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
##                                                                            ##
################################################################################


# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
CHECKPOLICY_DIR="${LTPBIN%/shared}/checkpolicy"
REQUIRED="grep expect"

function tc_local_setup()
{
 tc_exec_or_break $REQUIRED
 rpm -q checkpolicy >$stdout 2>$stderr
 tc_fail_if_bad $? "checkpolicy not installed properly"
}

function tc_local_cleanup()
{
  rm -f policy.mod
}

function run_test()
{
   pushd $CHECKPOLICY_DIR >$stdout 2>$stderr
   tc_register "Checkmodule: Compiling the policy file"
   checkmodule -o policy.mod policy.conf >$stdout 2>$stderr
   tc_fail_if_bad $? "Compilation of the binary failed"
   ls policy.mod >$stdout 2>$stderr
   tc_pass_or_fail $? "Binary file not created"

   tc_register "Checkpolicy: Loading the source policy file"
   checkpolicy policy.conf >$stdout 2>$stderr
   tc_pass_or_fail $? "Source policy file not loaded"

   tc_register "Checkpolicy: Loading the binary policy file"
   checkpolicy -b policy.mod >$stdout 2>$stderr
   tc_pass_or_fail $? "Binary policy file not loaded"

   tc_register "sedismod"
   ./sedismod.exp >$stdout 2>$stderr
   tc_pass_or_fail $? "sedismod failed"

   tc_register "sedispol"
   ./sedispol.exp >$stdout 2>$stderr
   tc_pass_or_fail $? "sedispol failed"
   popd >$stdout 2>$stderr
}

#
#main
#

TST_TOTAL=5
tc_setup
run_test
