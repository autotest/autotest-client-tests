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
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/nscd
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/nscd
################################################################################
# the testcase functions
################################################################################

#
# local setup
#
function tc_local_setup()
{
    IP1="169.184.2.9"
    IP2="::2"
    DUMMY_HOST="dummy1"

    mkdir -p $TCTMP/etc/
    cp /etc/nsswitch.conf $TCTMP/etc/
    cp /etc/host.conf     $TCTMP/etc/
    cp /etc/hosts         $TCTMP/etc/

    # Host resolution based on address
    echo "hosts: files" > /etc/nsswitch.conf
    # Enable multiple IPs 
    echo "multi on" > /etc/host.conf
    # Add IPs for a dummy host
    echo "$IP1    $DUMMY_HOST" > /etc/hosts
    echo "$IP2    $DUMMY_HOST" >> /etc/hosts

    # Note down the status of nscd
    tc_service_status nscd
    NSCD_STATUS=$?

}

#
# local cleanup
#
function tc_local_cleanup()
{
    # Restore the configs
    [ -d $TCTMP/etc/  ] && cp -a $TCTMP/etc/* /etc/
    
    # Stop the nscd for sure, to start using original configs
    tc_service_stop_and_wait nscd
    # Start it back if it was running 
    [ $NSCD_STATUS -eq 0 ] && tc_service_start_and_wait nscd
}
    
#
# test01        installation check
#
function test01()
{
    tc_register     "installation check"
    tc_executes nscd && tc_exists /etc/nscd.conf
    tc_pass_or_fail $? "nscd not properly installed"
}


#
# test02        function check
#
function test02()
{
    tc_register     "service check"
    tc_service_restart_and_wait nscd
    tc_fail_if_bad $? "nscd did not start" || return

    local n=10
    while ((--n)) ; do
        ps -e | grep -q nscd && break
        sleep 1
    done < <(ps -e)
    ((n))
    tc_pass_or_fail $? "nscd did not start"

}

#
# test03 : check whether nscd returns multiple IP address
function test03()
{
    tc_register     "function check"

    tc_service_status nscd
    if [ $? -ne 0 ]
    then
        tc_service_start_and_wait nscd
        tc_break_if_bad $?  "nscd is not running" || return
    fi

    $TESTDIR/getip $DUMMY_HOST >$stdout 2>$stderr
    grep -q "$IP1" $stdout && grep -q "$IP2" $stdout
    tc_pass_or_fail $? "Expected to see 2 IPs ( $IP1 , $IP2) in result"
}

#
# test04 : Test the nscd caching functionality
function test04()
{
    tc_register     "Test nscd caching functionality"
    rm -f /etc/hosts
    echo "$IP1    $DUMMY_HOST" > /etc/hosts
    tc_service_stop_and_wait nscd
    $TESTDIR/getip $DUMMY_HOST >$stdout 2>$stderr
    grep -q "$IP1" $stdout
    tc_fail_if_bad $? "Did not see IP - $IP1 in result"
    
    rm -f /etc/hosts
    $TESTDIR/getip $DUMMY_HOST &>$stdout # We are expecting a failure here - Test for failure
    if [ $? -eq 0 ]
    then
        tc_fail "expected the command to fail, but it succeeded"
    fi

    tc_service_start_and_wait nscd
    tc_fail_if_bad $? "nscd failed to start" 

    echo "$IP1    $DUMMY_HOST" > /etc/hosts
    $TESTDIR/getip $DUMMY_HOST >$stdout 2>$stderr
    grep -q "$IP1" $stdout
    tc_fail_if_bad $? "Did not see IP - $IP1 in result"

    rm -f /etc/hosts # even after removing the hosts file, the lookup should work from nscd cache
    $TESTDIR/getip $DUMMY_HOST >$stdout 2>$stderr
    grep -q "$IP1" $stdout
    tc_pass_or_fail $? "Did not see IP - $IP1 in result - this time via the nscd cache"
}
    
################################################################################
# main
################################################################################

TST_TOTAL=3

tc_setup
tc_run_me_only_once

test01 &&
test02 &&
#test03 && # Commented this test due to bug - 68935 - comment # 23
test04 
