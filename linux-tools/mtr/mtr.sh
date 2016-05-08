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
### File :        mtr.sh
##
### Description:  Test the mtr command.
##
### Author:       Kumuda G, kumuda@linux.vnet.ibm.com
###########################################################################################
### source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TESTS_DIR="${LTPBIN%/shared}/mtr"

REQUIRED="mtr host hostname traceroute"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    tc_exec_or_break $REQUIRED || return
    tc_get_os_arch
    if [ "$TC_OS_ARCH" == "s390x" ];
    then
        dest_host=lnx1.boe.example.com
    else
        dest_host=kjdev1.au.example.com
    fi
} 

# mtr_default verifies the default functionality of mtr's traceroute and ping.
function mtr_default()
{
    tc_register "mtr"
    local mtr_res=""
    local tr_res=""
    mtr --report --report-wide --report-cycles=1 $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
    mtr_res=`grep -q $dest_host $stdout`
    traceroute $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
    tr_res=`grep -q $dest_host $stdout`
    [ "$mtr_res" = "$tr_res" ]
    tc_pass_or_fail $? "mtr and traceroute paths do not match"

    tc_register "mtr using UDP"
    mtr -u --report --report-wide --report-cycles=1 $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
    mtr_res=`grep -q $dest_host $stdout`
    traceroute $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
    tr_res=`grep -q $dest_host $stdout`
    [ "$mtr_res" = "$tr_res" ]
    tc_pass_or_fail $? "mtr and traceroute paths do not match while using UDP"
}

# Verify that MTR displays IP address
function mtr_no_dns()
{
    tc_register "mtr --no-dns"
    dest_host_ip=$(grep $dest_host /etc/hosts | awk '{print $1}')
    mtr --report --report-wide --no-dns --report-cycles=3 $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
    grep -q $dest_host_ip $stdout
    tc_pass_or_fail $? "couldn't find the destination hosts IP!"

    tc_register "mtr --no-dns using UDP"
    mtr -u --report --report-wide --no-dns --report-cycles=3 $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
    grep -q $dest_host_ip $stdout
    tc_pass_or_fail $? "couldn't find the destination hosts IP! while using UDP in mtr"
}

# Binds outgoing packet through the specified IP using --address 
function mtr_addr()
{
    tc_register "mtr --address"
    tc_get_iface
    ipaddress=`ip addr show  $TC_IFACE | grep "inet " | awk '{print $2}'| sed 's|/[0-9]*||g'`
    mtr --report --report-wide --address $ipaddress --report-cycles=3 $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
    grep -q `grep $dest_host /etc/hosts | awk '{print $2}'` $stdout
    tc_pass_or_fail $? "couldn't find the destination host"

    tc_register "mtr --address using UDP"
    mtr -u --report --report-wide --address $ipaddress --report-cycles=3 $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
    grep -q `grep $dest_host /etc/hosts | awk '{print $2}'` $stdout
    tc_pass_or_fail $? "couldn't find the destination host while using UDP in mtr"
}
################################################################################
# MAIN
################################################################################
TST_TOTAL=3
tc_setup
mtr_default
mtr_no_dns
mtr_addr
