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
#
# File:		dhcrelay_tests.sh
#
# Description:	This program tests basic functionality of dhcrelay program
#
# Author:	Manoj Iyer  manjo@mail.utexas.edu
###############################################################################
# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

restart=0

#
# tc_local_setup
#	 
function tc_local_setup()
{	
	# check dependencies
	tc_root_or_break || return
	tc_exec_or_break grep || return
	ifconfig lo up 127.0.0.1 >$stdout 2>$stderr
	tc_break_if_bad $? "No loopback configured" || return

	# find interface to use
	local router_line=$(route | grep default)
	[ "$router_line" ]
	tc_break_if_bad $? "No router configured" || return
	set $router_line
	iface=$8
	[ "$iface" ]
	tc_break_if_bad $? "can't find network interface" || return
	
	# get mac address
	hwaddr="$(cat /sys/class/net/$iface/address)"
	[ "$hwaddr" ]
	tc_break_if_bad $? "could not find mac address of interface" || return
}

#
# tc_local_cleanup
#
tc_local_cleanup()
{
	/etc/init.d/dhcrelay stop &>/dev/null
	killall dhcrelay &>/dev/null
	[ $restart -eq 1 ] && { /etc/init.d/dhcrelay start &>/dev/null ; }
}

#############################################################################
# testcase functions
#############################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"dhcrelay installation check"
	tc_executes dhcrelay /usr/sbin/dhcrelay
	tc_pass_or_fail $? "dhcrelay not instaled properly"
}

#
# test02	Test that 'dhcrelay server_name' will listen for DHCP request 
#		on the interface.
#
#		Execute command dhcrelay on 127.0.0.1 and check if dhcrelay is 
#		listening.
#
function test02()
{
	tc_register    "dhcrelay 127.0.0.1"

	# stop any dhcprelay if already running.
	/etc/init.d/dhcrelay status &>/dev/null && {
		/etc/init.d/dhcrelay stop &>/dev/null
		tc_fail_if_bad $? "failed to stop dhcp-relay" || return
		restart=1
	} 

	dhcrelay -i $iface 127.0.0.1 &>$stdout
	tc_fail_if_bad $? "dhcrelay failed to start" || return

	tc_wait_for_file_text $stdout "$iface" &&
	grep -i "Listening on" $stdout | grep -qi "LPF/$iface/$hwaddr" &&
	grep -i "Sending on" $stdout | grep -qi "LPF/$iface/$hwaddr"
	tc_pass_or_fail $? "did not get expected output"
}

#############################################################################
# main
#############################################################################

TST_TOTAL=2
tc_setup
test01 &&
test02
