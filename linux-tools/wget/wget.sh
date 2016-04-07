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
## File :        wget.sh
##
## Description:  Test wget package using tests from the source
##
## Author:       Athira Rajeev <atrajeev@in.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
TESTDIR=${LTPBIN%/shared}/wget

source $LTPBIN/tc_utils.source
################################################################################
# the testcase functions
################################################################################

#
#Installation check
#
function installation_check()
{
  tc_root_or_break || exit
  tc_exec_or_break wget || return
  env | grep no_proxy=localhost &>$stdout 2>stderr
  if [ $? -eq 1 ]; then
        export no_proxy=localhost,127.0.0.0/8
        echo "set no proxy from script"
  else
        setflag=1
  fi
}

function tc_local_cleanup()
{
  env | grep no_proxy=localhost &>$stdout 2>stderr
  if ( [[ $? -eq 0 ]] && [[ $setflag -ne 1 ]] ); then
        unset no_proxy
        echo "unset proxy from script"
  fi
}
 
#
# runtests
#
function runtests()
{
  tc_register "wget tests"
  
  # The wget path in tests/WgetTest.pm is
  # /builddir/build/BUILD/wget-*/src/wget
  # Replace it with installed path of the binary
  sed -i 's:/builddir/build/BUILD/wget-[0-9]*.[0-9]*/src/wget:/usr/bin/wget:' $TESTDIR/tests/WgetTest.pm
  tc_fail_if_bad $? "sed failed to replace wget path" || return

  $TESTDIR/tests/run-px $TESTDIR &>$stdout 2>stderr
  tc_pass_or_fail $? "Test Failed"
       
}

################################################################################
# main
################################################################################

# standard tc_setup
tc_setup

TST_TOTAL=1
installation_check && runtests
