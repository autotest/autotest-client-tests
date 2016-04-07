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
## File :        rsync.sh
##
## Description:  Test rsync package using tests from the source
##
## Author:       Athira Rajeev <atrajeev@in.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
TESTDIR=${LTPBIN%/shared}/rsync

source $LTPBIN/tc_utils.source
################################################################################
# the testcase functions
################################################################################

#
#Installation check
#
function installation_check()
{
  tc_exec_or_break rsync  getenforce || return
}
 
#
# runtests
#
function runtests()
{
  tc_register "rsync tests"
  
  #The rsync path in runtests.sh is
  #path from build directory
  #Replace it with installed path of the binary
  sed -i 's:rsync_bin="$TOOLDIR/rsync":rsync_bin=/usr/bin/rsync:g' $TESTDIR/runtests.sh
  tc_fail_if_bad $? "sed failed to replace rsync path" || return

  pushd $TESTDIR &>/dev/null

  # Some tests use file names like
  # rsync.c, configure.in to check for different rsync
  # options. Replace with other files being used
  # by the test already.
  sed -i 's/rsync.c/tls.c/g' $TESTDIR/testsuite/fuzzy.test
  sed -i 's/configure.in/shconfig/g' $TESTDIR/testsuite/itemize.test
  sed -i 's/config.h.in/config.h/g' $TESTDIR/testsuite/itemize.test
  sed -i 's/rsync.h/shconfig/g' $TESTDIR/testsuite/itemize.test

  $TESTDIR/runtests.sh 1> $stdout 2>$stderr 
  tc_pass_or_fail $? "Test Failed"
  popd &>/dev/null

}

################################################################################
# main
################################################################################

# standard tc_setup
tc_setup

TST_TOTAL=1
installation_check && runtests
