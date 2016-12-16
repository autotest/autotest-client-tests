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
## File :        lldpad.sh
##
## Description:  Test the lldpad command.
##
## Author:       Madhuri Appana, madhuria@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/lldpad
source $LTPBIN/tc_utils.source

REQUIRED="lldpad lldptool dcbtool lspci"
################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED
	#Start the lldpad service
	systemctl status lldpad.service >$stdout 2>$stderr
    	grep -iq inactive $stdout
	lldpad_status=$?
	[ ! $lldpad_status ]
	tc_service_start_and_wait lldpad >$stdout 2>$stderr
	
	#Get the Active interface
    	tc_get_iface
}

function tc_local_cleanup()
{
    	if [ ! $lldpad_status ]; then
    		systemctl stop lldpad.service >$stdout 2>$stderr
		tc_fail_if_bad $? "Failed to disable lldpad daemon"
	fi
}

function test01()
{
    tc_register "Check the functionality of lldptool set/get-lldp"
    lldptool get-lldp -i $TC_IFACE adminStatus >$stdout 2>$stderr
    tc_break_if_bad $? "Failed to get lldp status"
    admin_Status=`cat $stdout | cut -d= -f 2`
    lldptool set-lldp -i $TC_IFACE "adminStatus=rxtx" >$stdout 2>$stderr
    tc_break_if_bad $? "Failed to set lldp status"
    grep -q rxtx $stdout 
    tc_pass_or_fail $? "Failed to set adminStatus of the interface"
    lldptool set-lldp -i $TC_IFACE "adminStatus=$admin_Status" >$stdout 2>$stderr
    tc_break_if_bad $? "Failed to set lldp status"
}

function test02()
{
    tc_register "Check the functionality of lldptool -stats"
    lldptool -S -i $TC_IFACE ipv4 >$stdout 2>$stderr
    tc_break_if_bad $? "Failed to get lldptool stats"
    if [ -s $stdout ]; then 
	grep -iq "Total Frames Transmitted" $stdout
    	tc_pass_or_fail $? "Failed to display ipv4 statastics of $TC_IFACE"
    else
	tc_fail "Failed to display ipv4 statastics of $TC_IFACE"
    fi
}

function test03()
{
    tc_register "Check the functionality of lldptool -stats for loopback interface"
    lldptool -S -i lo ipv4 >$stdout 2>$stderr
    if [ $? -ne 0 ]; then
    	tc_pass
    else
    	tc_fail "Failed to display valid error message"
    fi
}

function test04()
{
    tc_register "Check the functionality of dcbtool -ping"
    dcbtool -r ping >$stdout 2>$stderr
    tc_break_if_bad $? "Failed to check dcbtool ping"
    grep -iq PPONG $stdout
    tc_pass_or_fail $? "client interface is not operational"
}

function test05()
{
	tc_register "Terminate lldpad using lldpad -k"
	lldpad -k >$stdout 2>$stderr
        tc_break_if_bad $? "Failed to terminate lldpad"
    	systemctl status lldpad.service >$stdout 2>$stderr
	grep -iq disabled $stdout
    	tc_pass_or_fail $? "Failed to terminate lldpad"
}

function test06()
{
	tc_register "Check for Subsequent terminations using lldpad -k after restarting lldpad"
	tc_service_restart_and_wait lldpad >$stdout 2>$stderr 
	lldpad -k >$stdout 2>$stderr
        tc_break_if_bad $? "Failed to terminate lldpad"
    	systemctl status lldpad.service >$stdout 2>$stderr
	grep -iq running $stdout
    	tc_pass_or_fail $? "Failed to disable lldpad"
}

function test07()
{
	tc_register "lldpad -d when the lldpad service is already running"
    	lldpad -d >$stdout 2>$stderr
	if [ $? -eq 1 ]; then
	 	pgrep -l lldpad | grep -Eq "lldpad" #to check lldpad service is Already running or not
		if [ $? -eq 0 ]; then
	    		tc_pass
		else 
	    		tc_fail "Enabled lldpad when the service is already running"
		fi 
	else
		tc_fail "Enabled lldpad when the service is already running"
        fi
}

function run_dcbtests()
{
	tc_register "Enable dcb on eth interface"
	#Dcbtool requires dcb enabled eth interface and Intel 82599 and X520 or X540 
	# are supported Intel® Ethernet DCB Service for FCoE and CEE
	lspci | grep -q Intel | grep -q "82599|X520|X540"
	if [ $? -eq 0 ];then
		TST_TOTAL=`expr $TST_TOTAL+3`
		dcbtool sc $TC_IFACE dcb on >$stdout 2>$stderr
        	tc_break_if_bad $? "Failed to set config of dcb"
		grep -q "Status: Successful" $stdout
    		tc_pass_or_fail $? "Failed to enable DCB"
		dcbtool go $TC_IFACE pfc >$stdout 2>$stderr
        	tc_break_if_bad $? "Failed to get config of dcb"
		grep -q "Status: Successful" $stdout
    		tc_pass_or_fail $? "Failed to get the status of pfc"
		dcbtool sc $TC_IFACE pfc e:1 a:1 w:1 >$stdout 2>$stderr
        	tc_break_if_bad $? "Failed to set config of dcb"
		grep -q "Status: Successful" $stdout
    		tc_pass_or_fail $? "Failed to set pfc cnfiguration"
	else
	   	tc_info "DCB enabled interfaces are not present and so skipping rest of the tests" || return
	fi
}
		
################################################################################
# main
################################################################################
tc_setup
TST_TOTAL=7
test01
test02
test03
test04
test05
test06
test07
run_dcbtests
