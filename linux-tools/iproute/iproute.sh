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
## File:		iproute2.sh
##
## Description:	Test basic functionality of ip command in iproute2 package
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the standard utility functions

## Author:	Manoj Iyer, manjo@mail.utexas.edu
###########################################################################################

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# globals
################################################################################

declare -i acnt=0	# count aliases
declare -a aliasips=""	# aliased ip addresses
declare -a aliasdevs=""	# matching aliased devices
aliasip=""		# most recently created alias ip
aliasdev=""		# most recently created alias interface
myloop="127.6.6.6/32"
orig_mtu=""
rmmod_dummy=""
iface=""

################################################################################
# any utility functions specific to this file can go here
################################################################################

#
# Alias $iface for private network.
#
#	$1	alias number to use
#	$2	ip address to use
#
function alias()
{
        tc_exec_or_break ifconfig || return

	# remember to unalias in cleanup
	let acnt+=1
	local myif=$iface:$1;	aliasdevs[acnt]=$myif;	aliasdev=$myif
	local myip=$2;		aliasips[acnt]=$myip;	aliasip=$myip

        ifconfig $myif inet $myip
	tc_break_if_bad $? "failed to alias $myif as $myip" || return

	route add -host $myip dev $myif

	tc_break_if_bad $? "failed to add route for $myip" || return

        return 0
}

#
# Setup specific to this testcase.
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break ifconfig route || return
	sysctl net.ipv4.neigh.default.gc_thresh1=0
	local xxx=$(route -n | grep "^0.0.0.0")
	[ "$xxx" ] && set $xxx && iface=$8
        [ "$iface" ]
        tc_break_if_bad $? "can't find network interface" || return
}

#
# Cleanup specific to this testcase.
#
function tc_local_cleanup()
{
	# remove aliases
	while [ $acnt -gt 0 ] ; do
		local myip=${aliasips[acnt]}
		local myif=${aliasdevs[acnt]}
		ifconfig $myif inet $myip down &>/dev/null
		let acnt-=1
	done
	sysctl net.ipv4.neigh.default.gc_thresh1=128
	# restore original MTU
	type -p ip >/dev/null && [ "$orig_mtu" ] && ip link set $iface mtu $orig_mtu

	# remove dummy module if we loaded it
	[ "$rmmod_dummy" = "yes" ] && rmmod dummy &>/dev/null
}

################################################################################
# the testcase functions
################################################################################

################################################################################
#
#	test01		See that iproute2 packge is installed (or at least that
#			the ip command is available).
#
function test01()
{
	tc_register	"installed"
	tc_executes ip
	tc_pass_or_fail $? "iproute2 package not properly installed"
}

################################################################################
#
#	test02		See that "ip link set DEVICE mtu MTU"
#			changes the device mtu.
#
function test02()
{
	tc_register	"ip link set"

	# save original MTU to be restored later
	local mtu_line=`ifconfig $iface | grep -i MTU`
	mtu_line=${mtu_line##*mtu}
	orig_mtu=${mtu_line%% *}

	alias $TST_COUNT 10.1.1.12 || return

	local new_mtu=1400
	local command="ip -6 link set $aliasdev mtu $new_mtu"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	ifconfig $aliasdev >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from ifconfig $aliasdev" || return

	grep -qi "MTU $new_mtu" $stdout 2>$stderr
	tc_pass_or_fail $? "MTU not set to $new_mtu"
}

################################################################################
#
#	test03		See that "ip link show" lists device attributes.
#
function test03()
{
	tc_register	"ip link show"

	local command="ip -6 link show $iface"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	grep -q "$iface:" $stdout 2>$stderr
	tc_pass_or_fail $? "\"$command\" failed to show $iface attributes"
}

################################################################################
#
#	test04		See that "ip addr add <ip address> dev <device>"
#			will add new protocol address.
#
function test04()
{
	tc_register	"ip addr add"
	tc_exec_or_break grep || return

	local command="ip addr add $myloop dev lo"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	command="ip addr show dev lo"
	$command >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	grep -q "$myloop" $stdout 2>$stderr
	tc_pass_or_fail $? "\"$command\" did not add protocol address"
}

################################################################################
#
#	test05		See that "ip addr del <ip address> dev <device>"
#			will delete the protocol address added in test03.
#
function test05()
{
	tc_register	"ip addr del"
	tc_exec_or_break grep || return

	local command="ip addr del $myloop dev lo"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	command="ip addr show dev lo"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	grep -q "$myloop" $stdout 2>$stderr
	tc_pass_or_fail !$? "\"$command\" did not delete protocol address $myloop"
}

################################################################################
#
#	test06		See that "ip neigh add" adds new neighbor entry
#			to arp table.
#
function test06()
{
	tc_register	"ip neigh add"
	tc_exec_or_break grep || return
	ifconfig lo:0 10.2.2.0

	local loopb="10.2.2.1"
	local command="ip neigh add $loopb dev lo:0 nud reachable"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	local exp="$loopb dev lo lladdr 00:00:00:00:00:00 REACHABLE" 
	local command="ip neigh show"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	grep -q "$exp" $stdout 2>$stderr
	tc_pass_or_fail $? "\"$command\" did not add neighbor" \
		"expected to see"$'\n'"$exp in stdout"
}

################################################################################
#
#	test07		See that "ip neigh del" deletes the new neighbor
#			added in test06.
#
function test07()
{
	tc_register	"ip neigh del"

	local loopb="10.2.2.1"
	local command="ip neigh del $loopb dev lo:0"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	command="ip neigh show"
	local n=31
	while ((--n)) ; do
		$command 2>$stderr >$stdout
		tc_fail_if_bad $? "unexpected result from \"$command\"" || return

		grep -q "$loopb" $stdout 2>$stderr || break
		tc_info "Waiting for $loopb to drop from arp table ($n)"
		sleep 1
	done
	((n>0))
	tc_pass_or_fail $? "$loopb was not removed from arp"
	ifconfig lo:0 down
}

################################################################################
#
#	test08		See that "ip maddr add" adds a multicast addr entry
#
function test08()
{
	tc_register	"ip maddr add"

	alias $TST_COUNT 10.6.6.6 || return
	local command="ip maddr add 66:66:00:00:00:66 dev $aliasdev"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	command="ip maddr show"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	grep "link" $stdout | grep "66:66:00:00:00:66" | grep -q "static" 2>$stderr
	tc_pass_or_fail $? "unexpected result from \"$command\"" \
		"expected to see"$'\n'"$exp in stdout"
	
}

################################################################################
#
#	test09		See that "ip maddr del" deletes the multicast addr entry
#			created in test08.
#
function test09()
{
	tc_register	"ip maddr del"

	local hwaddr="66:66:00:00:00:66"
	local command="ip maddr del $hwaddr dev $aliasdev"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	command="ip maddr show"
	$command 2>$stderr >$stdout
	tc_fail_if_bad $? "unexpected result from \"$command\"" || return

	grep -q "$hwaddr" $stdout 2>$stderr >$TCTMP/output
	[ ! -s $TCTMP/output ]
	tc_pass_or_fail $? "unexpected result from \"$command\"" \
		"expected to NOT see"$'\n'"$hwaddr in stdout"
}

################################################################################
# ipv6 tests
################################################################################

#
# ip addr show should find all ipv6 addresses
#
function ip_addr_show()
{
	local addr iface cmd scope count index=0

	count=$(tc_array_size TC_IPV6_ADDRS)

	while ((index<count)) ; do
		addr=${TC_IPV6_ADDRS[index]}
		scope=${TC_IPV6_SCOPES[index]}
		iface=${TC_IPV6_IFACES[index]}
		((++index))
		((++TST_TOTAL))
		cmd="ip -o -6 addr show dev ${iface}"
		tc_register "$cmd (expecting scope $scope)"
		$cmd >$stdout 2>$stderr
		tc_fail_if_bad $? "Unexpected response"
		grep -q "${iface}.*scope $scope" $stdout
		tc_pass_or_fail $? "Expected results ($scope) not seen"
	done
}

#
# ip neighbor show 
#
function ip_neigh_show()
{

	local iface cmd1 cmd2 index=0 count

	count=$(tc_array_size TC_IPV6_link_ADDRS)

	while ((index<count)) ; do
		iface=${TC_IPV6_link_IFACES[index]}

		((++index))
		((++TST_TOTAL))

		local cmd1="ip -o -f inet6 neigh show dev $iface"
		tc_register "$cmd1"

		tc_executes ping6
		tc_conf_if_bad $? "No ping6 command available" || return

		local cmd2="ping6 -c 10 -W 10 -I $iface fe80::"
		tc_info "issuing \"$cmd2\""
		$cmd2 >$stdout 2>$stderr
		tc_conf_if_bad $? "Router not pingable on $iface" || continue

		$cmd1 >$stdout 2>$stderr
		tc_fail_if_bad $? "Unexpected response from \"$cmd1\"" || return
		grep -q "REACHABLE" $stdout  || grep -q "STALE" $stdout || grep -q "DELAY" $stdout
		tc_pass_or_fail $? "Expected results \"REACHABLE\" not seen" || return
	done
}


################################################################################
# main
################################################################################

TST_TOTAL=9

tc_setup

test01 || exit
tc_info "==================="
tc_info "running ipv4 tests"
tc_info "==================="
test02
test03
test04 &&
test05
test06 &&
test07
test08
test09

tc_ipv6_info || {
	tc_info "No ipv6 configuration so skipping ipv6 tests"
	return 0
}

tc_info "==================="
tc_info "running ipv6 tests"
tc_info "==================="
ip_addr_show
ip_neigh_show
