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
# File :        dhclientts.sh
#
# Description:  This program tests basic functionality of dhclient program
#
# Author:       Robert Paulsen
#################################################################################


# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

REQUIRED="grep ifconfig" 
MY_LOG=/var/log/messages

#############################################################################
# utility functions
#############################################################################


#
#function to find an interface on which dhclient can be run
#
function find_interface()
{
	# This test will not run in a machine with
	# single network device, as it is failing always in
	# a machine with single interface.

	if [ `ls -l /sys/class/net/ | grep -vic virtual | sed 's/.*\///g'` -le 2 ]; then
		tc_conf "Machine has only one network device"
		return 1
	fi

	#Get the network devices available
	list=`ls -l /sys/class/net/ | grep -vi virtual | sed 's/.*\///g' | grep -iv total`

	#Get the default gateway
	ip=$(ip route | grep default | awk '{print $3}')
	if [ x$ip == x ]
	then
		tc_info "Default gateway is not configured"
		if [ -f  /etc/resolv.conf ]
		then
			#Get the name server is default  gateway is not confiured
			ip=$(grep nameserver /etc/resolv.conf |awk '{print $2}' )
			[ x$ip == x ] && { tc_conf "Configure gateway/dns"
					return 1
			}
		fi
		
	fi

	#Get default outgoing IP address and interface.
	default_eth=$(ip route get $ip | grep  $ip| awk '{print $3}')	
	for dev in $list
	do
		if [ $default_eth != $dev ]
		then
			net_dev=$dev
			break
		fi
	done
}



#
# local setup
#	 
function tc_local_setup()
{	
	tc_root_or_break || return
        tc_exec_or_break $REQUIRED || return

}


#
# local cleanup
#
function tc_local_cleanup()
{
	ifconfig $net_dev down >$stdout 2>/dev/null
	[ "$kill_pid" ] && {
		kill $kill_pid
		tc_wait_for_no_pid "$kill_pid"
	}
	# Do network restart when using virtual network interface
	if [ $dev_count -eq $dev_with_inetaddr ]; then
		service network restart &>/dev/null
	fi
}


#############################################################################
# test functions
#############################################################################

#
# installation check
#
function test01()
{
	tc_register "installation check"
	tc_executes dhclient
	tc_pass_or_fail $? "dhclient package not installed properly"
}


#
# See that dhclient sends DHCPDISCOVER message
#
function test02()
{
	tc_register    "dhclient sends DHCPDISCOVER"

	ifconfig $net_dev 192.168.11.100	
	dhclient $net_dev &>$stdout & kill_pid=$!
	tc_fail_if_bad $? "Unexpected response from dhclient command" || return

	tc_wait_for_pid $kill_pid
	tc_fail_if_bad $? "dhclient did not start" || return

	tc_wait_for_file_text $MY_LOG "DHCPDISCOVER on $net_dev to" 30
	tc_pass_or_fail $? "Did not see DHCPDISCOVER message" || return

	ifconfig $net_dev del 192.168.11.100
}


#############################################################################
# main
#############################################################################

TST_TOTAL=2
tc_setup
find_interface || exit

test01 &&
test02
