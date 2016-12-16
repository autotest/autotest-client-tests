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
## File :        ORBit2.sh
##
## Description:  Test ORBit2 package.
##
######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/ORBit2
## source the utility functions
## Author:       Poornima Nayak      mpnayak@linux.vnet.ibm.com
###########################################################################################

source $LTPBIN/tc_utils.source
export LANG="en_US"
export LC_ALL=""

TESTS_DIR="${LTPBIN%/shared}/ORBit2/test/.libs"

function tc_local_setup()
{
    # check installation and environment
    set `find /usr/lib*/libORBit*`
    [ -f $1 ] && tc_break_if_bad $? "ORBit2 not installed"
}

function tc_local_cleanup()
{
    rm -f *.iorfile
}

function test_echo()
{
    tc_register "CORBA echo tests"
    ./echo-server >$stdout 2>$stderr &
    tc_wait_for_file_text 'echo-server.iorfile' 'IOR'
    tc_break_if_bad $? "echo-server failed to generate IOR file" ||\
    return
    
    # IOR & ITER(ations) are arguments for client program 
    ior=`cat echo-server.iorfile`
    iter=2
    ./echo-client $ior $iter >$stdout 2>$stderr
    rc=$?
    [ `grep -e "^$" -v $stderr | grep -ivc ": \[[client|server]\]*"` -eq 0 ]\
    && cat /dev/null > $stderr
        
    pkill echo-server
    [ $rc -eq 0 ] && tc_pass_or_fail $? "Test echo failed"
}

function test_echot()
{
    tc_register "CORBA echo thread tests"
    ./echo-server >$stdout 2>$stderr &
    tc_wait_for_file_text 'echo-server.iorfile' 'IOR'
    tc_break_if_bad $? "echo-server failed to generate IOR file" ||\
    return
    
    # IOR & ITER(ations) are arguments for client program 
    ior=`cat echo-server.iorfile`
    iter=1
    ./echo-client-t $ior $iter >$stdout 2>$stderr
    rc=$?
    [ `grep -e "^$" -v $stderr | grep -ivc "\*\* Message: [client]*"` -eq 0 ] &&\
            cat /dev/null > $stderr

    pkill echo-server
    [ $rc -eq 0 ] && tc_pass_or_fail $? "Test echo thread failed"
}

function test_empty()
{
    tc_register "CORBA empty test"
    ./empty-server >$stdout 2>$stderr &
    tc_wait_for_file_text 'empty-server.iorfile' 'IOR'
    tc_break_if_bad $? "empty-server did not generate IOR file" ||\
    return

    ior=`cat empty-server.iorfile`
    ./empty-client $ior  >$stdout 2>$stderr
    rc=$?
    pkill empty-server
    [ $rc -eq 0 ] && tc_pass_or_fail $? "Test CORBA empty failed"
}

function test_ior_decode()
{   
    tc_register "CORBA IOR Decode test"
    ior=`cat empty-server.iorfile`
    ./ior-decode-2 $ior >$stdout 2>$stderr
    tc_break_if_bad $? "Test IOR decode failed"
    cnt=`grep -e 'IOP_TAG_GENERIC_IOP' -e 'IOP_TAG_ORBIT_SPECIFIC' \
        -e 'IOP_TAG_MULTIPLE_COMPONENTS' $stdout | wc -l`
    [ $cnt -eq 3 ] 
    tc_pass_or_fail $? "Test CORBA IOR Decode failed"
}

function test_any()
{
    tc_register "CORBA Test Any interface"
    ./test-any-server >$stdout 2>$stderr &
    tc_wait_for_file_text 'test-any-server.iorfile' 'IOR' 
    tc_break_if_bad $? "any-server failed to generate IOR file" ||\
    return

    ior=`cat test-any-server.iorfile`
    ./test-any-client $ior >$stdout 2>$stderr
    rc=$?
    pkill test-any-server
    [ $rc -eq 0 ] && tc_pass_or_fail  $? "Test CORBA anyvalue failed"
}

function test_giop_timeout()
{
    tc_register "Test GIOP Timeout"
    ./timeout-server >$stdout 2>$stderr &
    # Sometime timeout-server takes time so this delay has been put
    sleep 10
    tc_break_if_bad $? "Failed to start timeout-server"

    ./timeout-client >$stdout 2>$stderr
    tc_break_if_bad $? "Error while executing timeout-client"
    grep -q "All GIOP timeout tests passed OK" $stdout
    rc=$?

    pkill timeout-server
    [ $rc -eq 0 ] && tc_pass_or_fail $? "Test GIOP timeout Failed" 
}

function test_typelib_dump()
{
    tc_register "Test typelib_dump"
    ./typelib-dump Bonobo >$stdout 2>$stderr
    tc_break_if_bad $? "Error while executing typelib-dump"
    grep -q '120 types:' $stdout
    tc_break_if_bad $? "Test typelib_dump failed"
    grep -q '33 interfaces:' $stdout
    tc_pass_or_fail $? "Test typelib_dump failed"
}

#
# main
#

TST_TOTAL=7 
tc_setup
pushd $TESTS_DIR &>/dev/null
test_echo
test_echot
test_empty
test_ior_decode
test_any
test_giop_timeout
test_typelib_dump
tc_local_cleanup
popd &>/dev/null
