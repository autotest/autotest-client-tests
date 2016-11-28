#!/bin/bash
############################################################################################
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
## File:         strace.sh
##
## Description:  This program tests basic functionality of strace program
##
## Author:       Manoj Iyer <manjo@mail.utexas.edu>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/strace
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/strace"

IPV6=""

################################################################################
# Utility functions
################################################################################

#
# local setup
#        
function tc_local_setup()
{       
    tc_exec_or_break mkdir touch || return

    # create a temporary directory and populate it with empty files.
    mkdir -p $TCTMP/strace.d 2>$stderr 1>$stdout
    tc_break_if_bad $? "can't make directory $TCTMP/strace.d" || return
    for file in x y z ; do
        touch $TCTMP/strace.d/$file 2>$stderr
        tc_break_if_bad $? "can't create file $TCTMP/strace.d/$file" || return
    done

    tc_ipv6_info && IPV6=yes
    
    return 0
}

################################################################################
# Tesytcase functions
################################################################################

#
# test01        installation check
#
function test01()
{
    tc_register     "installation check"
    tc_executes strace
    tc_pass_or_fail $? "strace not installed properly"
}

#
# test02        strace -c
#
function test02()
{
    tc_register     "strace -c"
 
    strace -c ls $TCTMP/strace.d &>$stdout
    tc_fail_if_bad $? "strace command failed" || return

    # Check for key-words/phrases that will indicated expected behaviour.
    grep -iq "time \+seconds \+usecs/call \+calls \+errors syscall" $stdout 2>$stderr
    tc_pass_or_fail $? "could not identify summary report"
}

#
# test03        strace -e open
#
function test03()
{
    tc_register     "strace -e open"

    strace -e open $TEST_DIR/hello_strace &>$stdout
    tc_fail_if_bad $? "strace command failed" || return

    # Check for key-words/phrases that will indicated expected behaviour.
    grep "open\(.*\.so.*O_RDONLY\).*= " $stdout| grep -q -v "\-1" 2>$stderr && 
    grep -q "OS Rocks" $stdout 2>$stderr
    tc_pass_or_fail $? "did not isolate strace to open systemcalls"
}


#
# test04 
#
function test04()
{
    local host=$(hostname)
    local cmd="ping $host -c 4"
    local text="sa_family=AF_INET"
    tc_executes ping &>/dev/null || {
        cmd="ip addr show"
        text="inet .* scope"
    }
    tc_register     "strace ipv4 syscall verification using $host"

    #tc_exec_or_break "$cmd" || return

    $cmd >$stdout 2>$stderr
    tc_break_if_bad $? "\"$cmd\" failed so can't strace it." || return

    strace $cmd &>$stdout 
    tc_fail_if_bad $? "strace $cmd failed." || return

    # Check for key-words/phrases that will indicated expected behaviour.
    cat $stdout | grep -q "$text" 
    tc_pass_or_fail $? "strace $cmd did not show \"$text\"."

    [ "$IPV6" = "yes" ] && {
        local host scope
        [ "$TC_IPV6_host_ADDRS" ] && host="$TC_IPV6_host_ADDRS" && scope=host
        [ "$TC_IPV6_global_ADDRS" ] && host="$TC_IPV6_global_ADDRS" && scope=global
        [ "$TC_IPV6_link_ADDRS" ] && host="$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES" && scope=link
        host=$(tc_ipv6_normalize $host)

        tc_register     "strace ipv6 syscall verification using $host"

        local cmd="ping6 $host -c 4"
        local text="sa_family=AF_INET6"
        tc_executes "$cmd" &>/dev/null || {
            cmd="ip -f inet6 addr show"
            text="link/ether"
            text="inet6 .* scope $scope"
        }
        #tc_exec_or_break "$cmd" || return

        $cmd >$stdout 2>$stderr
        tc_break_if_bad $? "$cmd failed." || return

        strace $cmd &>$stdout
        tc_fail_if_bad $? "strace $cmd failed." || return

        # Check for key-words/phrases that will indicated expected behaviour.
        cat $stdout | grep -q "$text"
        tc_pass_or_fail $? "strace \"$cmd\" did not show \"$text\"." || return
    }
}

################################################################################
# main
################################################################################

TST_TOTAL=4

tc_setup

test01 &&
test02
test03
test04
