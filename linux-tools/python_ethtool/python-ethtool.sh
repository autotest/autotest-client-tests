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
# File :        python-ethtool.sh  		                                           #
# Description:  Test the pethtool and pifconfig command.        		           #
# Author:       Kumuda G, kumuda@linux.vnet.ibm.com		                           #
############################################################################################

################################################################################
# source the utility functions
################################################################################
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TESTS_DIR="${LTPBIN%/shared}/python_ethtool"

REQUIRED="pethtool pifconfig ethtool ifconfig"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    tc_exec_or_break $REQUIRED || return
    tc_get_iface
    interface="$TC_IFACE"
    restore_tso=`ethtool -k $interface | grep "tcp-segmentation-offload:"|cut -d":" -f2`
}

function tc_local_cleanup()
{
    #restoring the tcp segmentation offload, by default its on
    ethtool -K $interface tso $restore_tso >> /dev/null
}
function pethtool_tests()
{
    tc_register pethtool_Cc
    prev=`pethtool -c $interface|grep rx-usecs:|cut -d" " -f2`
    pethtool -C $interface rx-usecs $((prev+1)) 1>$stdout 2>$stderr
    res=`ethtool -c $interface|grep rx-usecs:|cut -d" " -f2`
    [ $res -gt $prev ]
    tc_pass_or_fail $? "Failed to set and/or read rx-usecs"

    tc_register pethtool_Kk
    [ "$restore_tso" = " off" ] && tso=on || tso=off
    pethtool -K $interface tso $tso 1>$stdout 2>$stderr
    pethtool -k $interface | grep -q "tcp segmentation offload: $tso"
    pret=$?
    #pethtool failure is validated with ethtool to confirm whether the TCP off/on'loading
    #operation is supported or not by network card, if its not supported then pethtool_Kk 
    #test will throw an info message for 'not supported operation'  without failing in 
    #regression run. If the operation is supported and pethtool fails, then pethtool_Kk test fails.
    if [ $pret -eq 0 ]				 
    then	
  	tc_pass 
    else					
	ethtool -K $interface tso $tso 1>$stdout 2>$stderr
	grep -qi "Cannot change" $stderr 
	if [ $? -eq 0 ]
	then
    	    tc_info "pethtool_Kk: `cat $stderr` !!"
        else 
	    tc_fail "Test fails"
    	fi
    fi

    tc_register pethtool_i
    pethtool -i $interface 1>$stdout 2>$stderr
    tc_pass_or_fail $? "test fail"

}
function pifconfig_test()
{
    tc_register pifconfig
    ifconf=`ifconfig $interface|grep -w "inet"|awk '{print $2}'`
    pifconfig $interface 1>$stdout 2>$stderr
    [ `grep "inet addr" $stdout|cut -f2 -d':' | cut -f1 -d' '` = "$ifconf" ]
    tc_pass_or_fail $? "test fail"
}
################################################################################
# MAIN
################################################################################
TST_TOTAL=4
tc_get_os_ver
tc_setup
[ $TC_OS_VER -le 73 ] && TST_TOTAL=3 || pifconfig_test
pethtool_tests
