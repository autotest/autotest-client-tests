#!/bin/bash
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##  1.Redistributions of source code must retain the above copyright notice,              ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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

#
# File :        ksh.sh
#
# Description:  Test ksh package
#               The scripts directory is a copy of the tests directory in the
#               ksh source tree.
#
# Author:       dch,dingchao@cn.ibm.com 
#
################################################################################

# source the utility functions
ME=$(readlink -f -- $0)
#LTPBIN=${ME%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

# location of test scripts
SCRIPTS=${LTPBIN%/shared}/ksh/ksh-tests

################################################################################
# utility functions

################################################################################

function tc_local_setup()
{
    tc_add_user_or_break || return
}   

function test01()
{
    tc_register "Installation check"
    tc_executes ksh
    tc_pass_or_fail $? "ksh not installed properly" || return
    KSH=$(which ksh)
}

function do_tests()
{
    for f in $tests
    do
        tc_register "${f} test"
        local cmd="cd ${SCRIPTS} ; SHELL=$KSH $KSH shtests $f"
        #echo "$cmd" | su - $TC_TEMP_USER >$stdout 2>$stderr
        $cmd >$stdout 2>$stderr
        tc_pass_or_fail $?
    done
}

tc_setup

tests=$(cd $SCRIPTS; ls *.sh)
[ "$@" ] && tests="$@"
[ "$tests" ]
tc_break_if_bad $? "No tests found" || exit
set $tests
((TST_TOTAL=$#+1))

test01 || exit
do_tests
