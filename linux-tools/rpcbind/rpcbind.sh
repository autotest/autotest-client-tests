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
### File:        rpcbind.sh                                                    ##
##
### Description: This program tests rpcbind and rpcinfo program.               ##
##
### Author:      Kingsuk Deb<kingsdeb@linux.vnet.ibm.com>                      ##
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/rpcbind
source $LTPBIN/tc_utils.source
TEST_PATH=${LTPBIN%/shared}/rpcbind
printmsg_svr=$TEST_PATH/printmsg_server
printmsg_clnt=$TEST_PATH/printmsg_client


################################################################################
# Utility functions
################################################################################

function tc_local_setup()
{
    tc_root_or_break || return
    tc_exec_or_break rpcbind rpcinfo || return

    tc_wait_for_service rpcbind &> /dev/null 
    [ $? -eq 0 ] && \
    tc_service_start_and_wait rpcbind >$stdout 2>$stderr 
    tc_break_if_bad $? "rpcbind failed to start"

    # Start printmsg RPC Server
    $printmsg_svr &
    svr_pid=$!

    sleep 1

    [ -f /etc/rpc ] 
    tc_break_if_bad $? "RPC program number database not found" || return
    cp /etc/rpc /etc/rpc.bak
    # Define RPC prog for user Range: 0x20000000 - 0x3fffffff
    # 536870913 is decimal equivalent RPC program number for 0x20000001 
    echo "printmsg   536870913" >>/etc/rpc

}

function tc_local_cleanup()
{
    kill -9 $svr_pid
    mv /etc/rpc.bak /etc/rpc
	tc_service_start_and_wait rpcbind >$stdout 2>$stderr 
}

################################################################################
# Testcase functions
################################################################################

function test01()
{
    tc_register     "Test printmsg client"
    $printmsg_clnt localhost >$stdout 2>$stderr
    grep -q "Message from Server:HELLO!" $stdout
    tc_pass_or_fail $? "printmsg client failed"
}

function test02()
{
    tc_register    "Test rpcinfo -m"
    rpcinfo -m localhost >$stdout 2>$stderr
    printmsg_stat=`grep printmsg $stdout`
    [ "`echo $printmsg_stat`" == "printmsg 1 tcp 1 0" ]
    if [ $? -eq 0 ]
        then
        	echo $stdout &>/dev/null
	fi
    tc_pass_or_fail $? "rpcinfo -m failed to get stat"
}

function test03()
{
    tc_register    "Test rpcinfo -p"
    rpcinfo -p localhost >$stdout 2>$stderr
    grep 536870913 $stdout | grep -q tcp
    tc_fail_if_bad $? "Not able to find tcp printmsg server" || return
    grep 536870913 $stdout | grep -q udp
    tc_pass_or_fail $? "Not able to find udp printmsg server"
}

function test04()
{
    tc_register    "Test rpcinfo -s"
    rpcinfo -s >$stdout 2>$stderr
    grep 536870913 $stdout | grep -q tcp,udp
    tc_pass_or_fail $? "rpcinfo -s failed to show printmsg service"
}

function test05()
{
    tc_register    "Test rpcinfo -T"
    rpcinfo -T tcp localhost printmsg >$stdout 2>$stderr
    grep -q "program 536870913 version 1 ready and waiting" $stdout
    tc_fail_if_bad $? "rpcinfo -T failed to get tcp info" || return
    rpcinfo -T udp localhost printmsg >$stdout 2>$stderr
    grep -q "program 536870913 version 1 ready and waiting" $stdout
    tc_pass_or_fail $?  "rpcinfo -T failed to get udp info"
}

function test06()
{
    tc_register     "Test rpcinfo -l"
    ipaddr=`hostname -i | awk -F " " '{print $1}'`
    rpcinfo -l $ipaddr 536870913 1 >$stdout 2>$stderr
    [ `grep 536870913 $stdout | wc -l` -eq 2 ]
    tc_pass_or_fail $? "Failed to list registered programs"
}

function test07()
{
    tc_register     "Test rpcinfo -a for portmap ver 3"
    rpcinfo -a 0.0.0.0.0.111 -T tcp 100000 3 >$stdout 2>$stderr
    grep -q "program 100000 version 3 ready and waiting" $stdout
    tc_pass_or_fail $? "Getting info using universal address failed"
}

function test08()
{
    tc_register    "Test delete registration with rpcinfo -d"
    rpcinfo -d -T udp 536870913 1 >$stdout 2>$stderr
    tc_fail_if_bad $? "rpcinfo -d failed for udp" || return
    rpcinfo -p >$stdout 2>$stderr
    grep 536870913 $stdout | grep -q udp
    test -s $stdout
    tc_fail_if_bad $? "Failed to unregister printmsg udp service"
    rpcinfo -d 536870913 1 >$stdout 2>$stderr
    tc_fail_if_bad $? "rpcinfo -d failed" || return
    rpcinfo -p >$stdout 2>$stderr
    grep -q 536870913 $stdout
    test -s $stdout
    tc_pass_or_fail $? "Failed to unregister printmsg service completely"
}


################################################################################
# main
################################################################################

TST_TOTAL=8

tc_setup

test01
test02
test03
test04
test05
test06
test07
test08 
