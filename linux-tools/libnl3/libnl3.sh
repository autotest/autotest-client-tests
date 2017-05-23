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
## File:         libnl3.sh
##
## Description:  This program tests libnl3
##
## Author:       Athira Rajeev>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libnl3
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/libnl3/tests/.libs

################################################################################
# Utility functions
################################################################################
#
#function to create temporary test files
#
function temp_test()
{
    cat >> $TCTMP/test.sh <<-EOF
    #!/usr/bin/expect -f
    set timeout 2
    spawn ./test-cache-mngr
    expect .sock
    send \x03
    expect eof
EOF
    chmod +x $TCTMP/test.sh
}

#
# local setup
#
function tc_local_setup()
{
      tc_check_package libnl3
    tc_break_if_bad $? "libnl3 not installed" || return
    temp_test 
       
    ifconfig -a| grep -q vlan0
    if [ $? -eq 0 ]; then
        ifconfig vlan0 down
        vconfig rem vlan0
    fi
}   

function runtests()
{
    pushd $TESTS_DIR

    TESTS=`ls test-*`
    TST_TOTAL=`echo $TESTS | wc -w`
    for t in $TESTS
    do
        tc_register "$t"
        echo $t | grep -q test-cache-mngr
        if [ $? -eq 0 ]; then
            expect $TCTMP/test.sh >$stdout 2>$stderr
            if [ `grep -E 'cache-manager|protocol|flags|nassocs|sock' $stdout | wc -l` -eq 5 ]; then
                tc_pass
            else
                tc_fail "test-cache-mngr failed to display information"
            fi

        else
            ./$t >$stdout 2>$stderr
            RC=$?
            tc_pass_or_fail $RC "$t failed"
        fi
    done
    popd
}
tc_setup
tc_run_me_only_once
TST_TOTAL=1
runtests
