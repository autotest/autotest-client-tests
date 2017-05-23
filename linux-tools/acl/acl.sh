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
## File :        acl.sh
##
## Description:  Test the functions provided by star.
##
## Author:       Liu Deyan, liudeyan@cn.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

TESTDIR=${LTPBIN%/shared}/acl/acl-tests

TESTS=(
cp.test
getfacl-noacl.test
#permissions.test
#setfacl.test
setfacl-X.test
getfacl-recursive.test
utf8-filenames.test
sbits-restore.test
)
# not used
# nfsacl.test
# nfs-dir.test

################################################################################
# utility functions
################################################################################

function tc_local_setup()
{
    tc_exec_or_break grep perl || return
    tc_check_package "perl" 
    tc_break_if_bad $? "Need full perl installation, not just perl-base" || return

    local opts="remount,defaults,errors=remount-ro,acl,user_xattr"
    sudo mount -o $opts /
    tc_break_if_bad $? "could not remount / with $opts" || exit
}

################################################################################
# the testcase function
################################################################################

function runtest()
{
    local test_name=$1
    local cmd=$TESTDIR/$test_name
    tc_register $test_name
    #$TESTDIR/run $cmd >$stdout 2>$stderr
    cd $TESTDIR
    ./run $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response" || return
    cd ..
    set $(cat $stdout | grep "passed, 0 failed)" | wc -l)
    [ $1 -eq 1 ]
    tc_pass_or_fail $? "$1 errors"
}

function alltests()
{
    cd $TCTMP
    TST_TOTAL=${#TESTS[*]}
    local t
    for t in ${TESTS[@]} ; do
        runtest $t
    done
}

################################################################################
# main
################################################################################

tc_setup
tc_run_me_only_once     # for both acl and libacl tests
alltests
