#!/bin/bash
# vi: set ts=4 sw=4 expandtab:
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
## File :	libassuan.sh
##
## Description:	Tests for libassuan
##
## Author:	Athira Rajeev
###########################################################################################
# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libassuan
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/libassuan/tests/

################################################################################
# Utility functions
################################################################################
#
# local setup
#
function tc_local_setup()
{
      tc_check_package libassuan
    tc_break_if_bad $? "libassuan not installed" || return

    cp $TESTS_DIR/motd $TESTS_DIR/.libs/
}

function runtests()
{
    pushd $TESTS_DIR/.libs

    TESTS="pipeconnect fdpassing version"
    for t in $TESTS
    do
        tc_register "$t"
        ./$t >$stdout 2>$stderr
        RC=$?
        grep -q fail $stderr
        if [ $? -ne 0 ]; then
             cat /dev/null > $stderr
        fi
	tc_pass_or_fail $RC "$t failed"
    done
    popd
}
tc_setup
TST_TOTAL=3
runtests
