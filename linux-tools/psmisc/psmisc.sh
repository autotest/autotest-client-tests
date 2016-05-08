#!/bin/bash
# vi: ts=4 sw=4 expandtab :
###########################################################################################
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
#
# File :        psmisc.sh
#
# Description:  This testcase tests the following commands in the psmisc. 
#       pstree, killall, fuser
# 
# Author:       rende@cn.ibm.com
#

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

REQUIRED="ps grep sleep netstat" 

commands="pstree fuser killall"

MYPID=""
IPV6=""

function tc_local_setup()
{
    tc_exec_or_break $REQUIRED || exit
    tc_ipv6_info && IPV6=yes
    return 0
}

function tc_local_cleanup()
{
    [ $? -eq 0 ] || ps -ef
}

function test00()
{
    tc_register "installation check"
    tc_executes $commands
    tc_pass_or_fail $? "psmisc not installed properly"
}

function test_pstree()
{
    tc_register "pstree"
    subtest=("pstree" "pstree -al" "pstree -uh root") 

    i=0
    while [ $i -lt 3 ] ; do
        tc_info "${subtest[$i]}"
        ${subtest[$i]} >$stdout 2>$stderr 
        tc_fail_if_bad $? "failed" || return
        let i+=1
    done

    local sleeper_name="ps_$$"
    tc_sleeper $sleeper_name

    pstree -alp >$stdout 2>$stderr
    grep $sleeper_name $stdout | grep -qw $TC_SLEEPER_PID
    tc_pass_or_fail $? "\"$sleeper_name\" pid $TC_SLEEPER_PID not found in pstree output"
}

function test_killall1()
{
    tc_register "killall"

    local sleeper_name=ka1_$$
    tc_sleeper $sleeper_name

    killall $sleeper_name >$stdout 2>$stderr
    tc_fail_if_bad $? "killall failed" || return
    tc_wait_for_no_pid $TC_SLEEPER_PID
    tc_pass_or_fail $? "process not killed by killall"
}

function test_killall2()
{
    tc_register "killall -I"

    local sleeper_name=ka2_$$
    tc_sleeper $sleeper_name

    killall -I Ka2_$$ >$stdout 2>$stderr # Intentional capitalization mismatch
    tc_fail_if_bad $? "killall -I failed" || return
    tc_wait_for_no_pid $TC_SLEEPER_PID
    tc_pass_or_fail $? "process not killed by killall"
}

function test_killall3()
{
    tc_register "killall -r"

    local sleeper_name=xxx_ka3_$$
    tc_sleeper $sleeper_name

    killall -r "xxx.*[Ka]3_$$" >$stdout 2>$stderr
    tc_fail_if_bad $? "killall -r failed" || return
    tc_wait_for_no_pid $TC_SLEEPER_PID
    tc_pass_or_fail $? "process not killed by killall" 
}

function test_fuser_file()
{
    tc_register "fuser file"

    # Create a file-using process to look for
    tail -f /var/log/messages &>/dev/null & MYPID=$!
    tc_wait_for_pid $MYPID
    tc_break_if_bad $? "Could not tail -f /var/log/messages" || return

    # look for the above process
    fuser /var/log/messages &>$stdout
    tc_fail_if_bad $? "unexpected response from \"fuser /var/log/messages\"" || return
    grep messages $stdout | grep -qw $MYPID
    tc_pass_or_fail $? "process $MYPID not found by \"fuser /var/log/messages\"" || return

    kill $MYPID
    tc_wait_for_no_pid $MYPID
}

function test_fuser_socket()
{
    netstat -ant |grep ":22 "|grep -q ESTABLISHED
    if [ $? -ne 0 ] ; then
        ((--TST_TOTAL))
        tc_info "skipped fuser socket test since ssh connection not ESTABLISHED"
        return 0
    fi

    tc_register "fuser socket"
    fuser ssh/tcp &>$stdout
    tc_fail_if_bad $? "unexpected respone from \"fuser ssh/tcp\"" || return
    grep -q ssh $stdout
    tc_fail_if_bad $? "ssh process not found by fuser"

    [ "$IPV6" = "yes" ] && {
        fuser -6 ssh/tcp &>$stdout
        tc_fail_if_bad $? "unexpected respone from \"fuser -6 ssh/tcp\"" || return
        grep -q ssh $stdout
        tc_fail_if_bad $? "ssh process not found by fuser"
    }
    tc_pass_or_fail 0       # pass if we get this far
}

################################################################################
# main
################################################################################
TST_TOTAL=7

tc_setup

test00 || exit  # installation check
test_pstree
test_killall1
test_killall2
test_killall3
test_fuser_file
test_fuser_socket
