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
## File :	net-tools.sh
##
## Description:	Test the net-tools package
##
## Author:	Hong Bo Peng <penghb@cn.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/net_tools

iface=0		# system network interface

COMMANDS="arp hostname ifconfig ipmaddr iptunnel netstat route traceroute traceroute6"
set $COMMANDS
TST_TOTAL=$#

################################################################################
# utility functions
################################################################################
function tc_local_setup()
{
	#should run as root
	tc_root_or_break || return

	IPV6=0
	tc_ipv6_info && IPV6=1

	local xxx=$(route -n | grep "^0.0.0.0")
	[ "$xxx" ] && set $xxx && IFACE=$8
	[ "$IFACE" ]
	tc_break_if_bad $? "can't find network interface" || return

	xxx=$(route -n | grep "^0.0.0.0 .*UG.*$IFACE$")
	[ "$xxx" ] && set $xxx && ROUTER=$2
	[ "$ROUTER" ]
	tc_break_if_bad $? "can't find router" || return

	if [ "$(hostname 2>/dev/null)" != "" ]
	then
		hostname > $TCTMP/HOSTNAME
	else
		hostname localhost.localdomain
		hostname > $TCTMP/HOSTNAME
	fi
	return 0
}

function tc_local_cleanup()
{
	[ -r "$TCTMP/HOSTNAME" ] && hostname -F $TCTMP/HOSTNAME
}

################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"is net-tools installed"

	tc_executes $COMMANDS
	tc_pass_or_fail $? "net-tools is not installed properly"
}

function TC_hostname()
{
	tc_register	"hostname"


	hostname 2>$stderr >$stdout && [ "$stdout" ]
	tc_fail_if_bad $? "unexpected response from hostname command"

	hostname -s 2>$stderr >$stdout && [ "$stdout" ]
	tc_fail_if_bad $? "unexpected response from hostname -s command"

	hostname -f 2>$stderr >$stdout && [ "$stdout" ]
	tc_fail_if_bad $? "unexpected response from hostname -f command"

	hostname -d 2>$stderr >$stdout && [ "$stdout" ]
	tc_fail_if_bad $? "unexpected response from hostname -d command"

	echo "funnyhost.funny-domain" > $TCTMP/funnyfile
	hostname -F $TCTMP/funnyfile 2>$stderr >$stdout && [ "$stdout" ]
	tc_fail_if_bad $? "unexpected response from hostname -F command"

	set $(<$TCTMP/funnyfile)
	[ "$1" = "funnyhost.funny-domain" ]
	tc_fail_if_bad $? "hostname -F didn't set hostname" || return

	hostname -F $TCTMP/HOSTNAME
	tc_pass_or_fail $? "unexpected response trying to restore the hostname from HOSTNAME"
}

function TC_ifconfig()
{
	tc_register	"ifconfig"
	ifconfig 2>$stderr 1>$TCTMP/ifconfig.out
	tc_fail_if_bad $? "ifconfig failed"

	grep "Local Loopback" $TCTMP/ifconfig.out 2>$stderr 1>$stdout
	tc_fail_if_bad $? "unexpect output of ifconfig"

	(( IPV6 )) && {
	        cat $TCTMP/ifconfig.out | grep "inet6" >/dev/null
	        tc_fail_if_bad $? "Did not see IPV6 info" || return
	}
						
	#setup an alias interface
	ifconfig lo:1 127.0.0.240  netmask 255.0.0.0 2>$stderr 1>$stdout
	tc_fail_if_bad $? "ifconfig lo:1 failed"

	ifconfig lo:1 down >$stderr 1>$stdout
	tc_pass_or_fail $? "ifconfig lo:1 down failed"
}

function TC_netstat()
{
	tc_register	"netstat"

	netstat -s 2>$stderr 1>$stdout
	tc_fail_if_bad $? "netstat -s failed"

	netstat -rn 2>$stderr 1>$stdout
	tc_fail_if_bad $? "netstat -rn failed"

	netstat -i 2>$stderr 1>$stdout
	tc_fail_if_bad $? "netstat -i failed"

	netstat -gn 2>$stderr 1>$stdout
	tc_fail_if_bad $? "netstat -gn failed"

	netstat -apn 2>$stderr 1>$stdout
	tc_pass_or_fail $? "netstat -apn failed"
}

function TC_arp()
{
	tc_get_os_arch
	[ "$TC_OS_ARCH" = "s390x" ] && {
		tc_info "arp not supported on s390x -- uses qetharp instead." \
			"Tested by s390-tools."
		return 0
	}

	tc_register	"arp"

	ping -c 2 -w 5 $ROUTER

	arp -n >$stdout 2>$stderr
	tc_break_if_bad $? "unexpected response from ping" || return

	grep $ROUTER $stdout
	tc_pass_or_fail $? "no info for $ROUTER in arp table"
}

function TC_traceroute()
{
	tc_register	"traceroute"

	traceroute localhost 2>$stderr >$stdout
	tc_fail_if_bad $? "traceroute failed"

	# Only one hop is required to get to localhost.
	local hops_line=$(tail -1 $stdout)
	[ "$hops_line" ]
	tc_fail_if_bad $? "no localhost info from traceroute" || return
	set $hops_line
	[ "$1" -eq 1 ]
	tc_pass_or_fail $? "traceroute did not show 1 hop for localhost"

}

function TC_traceroute6()
{
	(( IPV6 )) || {
		((--TST_TOTAL))
		tc_info "ipv6 not configured so skipping traceroute6 test"
		return 0
	}
	tc_register	"traceroute6"

	traceroute6 localhost6 2>$stderr >$stdout
	tc_fail_if_bad $? "traceroute6 failed"

	# Only one hop is required to get to localhost.
	local hops_line=$(tail -1 $stdout)
	[ "$hops_line" ]
	tc_fail_if_bad $? "no localhost6 info from traceroute6" || return
	set $hops_line
	[ "$1" -eq 1 ]
	tc_pass_or_fail $? "traceroute6 did not show 1 hop for localhost"
}

function TC_route()
{
	tc_register	"route"
	
	route -n 2>$stderr 1>$stdout
	tc_fail_if_bad $? "route failed"

	(( IPV6 )) && {
		route -A inet6 -n 2>$stderr 1>$stdout
		tc_fail_if_bad $? "route  ipv6 failed"
	}
	tc_pass_or_fail 0 
								
}

function TC_ipmaddr()
{
	tc_register	"ipmaddr"
	
	ipmaddr show dev lo 2>$stderr 1>$stdout
        tc_fail_if_bad $? "ipmaddr failed"

	(( IPV6 )) && {
		ipmaddr show ipv6 dev lo 2>$stderr 1>$stdout
		tc_fail_if_bad $? "ipmaddr ipv6 failed"
	}
	tc_pass_or_fail 0
								
}

#
# Note, this messes up dhcp client configurations so is skipped
# in that case.
#
function TC_iptunnel()
{
	tc_register	"iptunnel"

	ps -ef | grep -q dhclient && {
                tc_info "Skipped on dhclient systems"
                return 0
        }

	# add sit1
	iptunnel add sit1 mode sit local 127.0.0.1 ttl 64 2>$stderr 1>$stderr
	tc_fail_if_bad $? "iptunnel add sit1 failed"

	iptunnel show 2>$stderr 1>$TCTMP/iptunnel.out
	tc_fail_if_bad $? "iptunnel show failed"

	grep "sit1" $TCTMP/iptunnel.out 2>$stderr 1>$stdout
	tc_fail_if_bad $? "iptunnel didn't add sit1"

	# remove sit1
	iptunnel del sit1 2>$stderr 1>$stdout
	tc_fail_if_bad $? "iptunnel del sit1 failed"

	iptunnel show 2>$stderr 1>$TCTMP/iptunnel.out

	# sit1 has been removed. So it should not appare here.
	grep "sit1" $TCTMP/iptunnel.out 2>$stderr 1>$stdout
	rc=$?
	[ $rc -ne 0 ]
	tc_pass_or_fail $? "iptunnel didn't remove sit1"
}

function TC_nameif()
{
	tc_register	"nameif"
	
	#change name of lo to vlo
	ifdown lo
	nameif -r vlo lo 2>/dev/null 1>/dev/null
	tc_fail_if_bad $? "nameif change to vlo failed"

	# this should fail because lo is not exising now.
	ifconfig lo 127.0.0.1 2>$stdout 1>$stdout
	rc=$?
	[ $rc -ne 0 ] 
	tc_fail_if_bad $? "change lo to vlo failed"

	# now config vlo and check the result
	ifconfig vlo 127.0.0.1 2>$stderr 1>$stdout
	tc_fail_if_bad $? "config for vlo failed"

	ifconfig 2>$stderr 1>$TCTMP/nameif.out
	grep vlo $TCTMP/nameif.out 2>$stderr 1>$stdout
	tc_fail_if_bad $? "config for vlo failed"

	#remove vlo and restore lo
	ifdown vlo 2>&1 1>/dev/null
	nameif -r lo vlo 2>/dev/null 1>/dev/null
	ifconfig lo up 127.0.0.1 netmask 255.0.0.0

	tc_pass_or_fail $? "nameif failed"
}

################################################################################
################################################################################
# main
################################################################################

# standard tc_setup
tc_setup

test01 || exit

for cmd in $COMMANDS
do
	TC_$cmd || break
done
