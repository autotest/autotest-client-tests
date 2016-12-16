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
# File :        cups.sh
#
# Author:       Poornima Nayak      mpnayak@linux.vnet.ibm.com
#
# Description:  Test cups package.
#

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/cups
source $LTPBIN/tc_utils.source

TEST_DIR="cups-tests"

#
# tc_local_setup specific to this testcase.
#
function tc_local_setup()
{
        tc_root_or_break || return
        export CUPSD=`which cupsd`
        export LPADMIN=`which lpadmin`
        export LPC=`which lpc`
        export LPQ=`which lpq`
        export LPSTAT=`which lpstat`
        export LP=`which lp`
        export LPR=`which lpr`
        export LPRM=`which lprm`
        export CANCEL=`which cancel`
        export LPINFO=`which lpinfo`
}

################################################################################
# the testcase functions
################################################################################

#
#       Ensure cups package is installed
#
function test01()
{
        tc_register "Is cups installed?"
        tc_exists "/usr/lib/cups"
        tc_exec_or_break "cupsd lpadmin lpc lpq lpstat lp lpr lprm cancel \
lpinfo" || exit
}

#	Description of input "1\n0\nN\n"
#	1 -Basic conformance test
#	0 -No SSL/TLS
#	N -Not to pickup valgrind from http://developer.kde.org/~sewardj/
function test02()
{
        tc_register "IPP Basic conformance test"
        pushd $TEST_DIR &>/dev/null
        echo -e "1\n0\nN\n" | ./run-stp-tests.sh &>$stdout 2>$stderr
        rc=$?
        [ `grep -ivc "flood copy" $stderr` -eq 0 ] && 
        cat /dev/null >$stderr
        tc_pass_or_fail $? "IPP Basic conformance test failed" 
        popd $TEST_DIR &>/dev/null
}

################################################################################
# main
################################################################################
cd ${LTPBIN%/shared}/cups

TST_TOTAL=2

tc_setup                                # standard setup
test01 &&
test02 
