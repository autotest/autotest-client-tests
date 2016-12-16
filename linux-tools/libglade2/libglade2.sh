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
## File:         libglade2.sh
##
## Description:  This program tests libglade2
##
## Author:       Athira Rajeev>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libglade2
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/libglade2/tests

################################################################################
# Utility functions
################################################################################

#
# local setup
#
function tc_local_setup()
{
    rpm -q libglade2 1>$stdout 2>$stderr
    tc_break_if_bad $? "libglade2 not installed" || return

    vncserver -kill :4 > /dev/null
    vncserver :4 -SecurityTypes None > /dev/null
    export DISPLAY=:4

    export srcdir=$TESTS_DIR
}

function tc_local_cleanup()
{
    vncserver -kill :4 > /dev/null
}

function runtests()
{
    pushd $TESTS_DIR

    TESTS="test-value-parse"
    for t in $TESTS
    do
        tc_register "$t"
        ./$t >$stdout 2>$stderr
        tc_pass_or_fail $? "$t failed"
    done
    popd
}
tc_setup
TST_TOTAL=1
runtests
