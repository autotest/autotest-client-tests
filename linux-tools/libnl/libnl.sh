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
## File :	libnl.sh
##
## Description:	Tests for libnl
##
## Author:	Suzuki K P <suzukikp@in.ibm.com>
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libnl
source $LTPBIN/tc_utils.source
testdir=${LTPBIN%/shared}/libnl

PATH=$PATH:$testdir/libnl-tests/
export PATH

ip=`hostname -i 2>/dev/null | awk '{print $1}'`

function tc_local_setup()
{
	tc_executes "nl-link-stats nl-addr-dump nl-list-sockets nl-route-dump nl-neigh-dump nl-route-get ping" ||
	exit 0;
}

function test_link_stats()
{
	tc_executes ping || {
		tc_info "ping command is un-available. link-stats test skipped"
		return;
	}

	tc_register "Link statistics using nl-link-stats"

	# Read the rx_, tx_ packet count for $dev
        rx1=`nl-link-stats  rx_packets 2>$stderr | grep $dev.rx_packets | awk '{print $2}'`
	tc_fail_if_bad $? "Failed to read the rx_packets for $dev"
	tx1=`nl-link-stats  tx_packets 2>$stderr | grep $dev.tx_packets | awk '{print $2}'`
	tc_fail_if_bad $? "Failed to read the tx_packets for $dev"
	
	# ping our interface to increment the counters.
	ping -c 2 $ip &>/dev/null
	tc_fail_if_bad $? "Failed to ping $ip of $dev"
	
	# Read the counters again
	rx2=`nl-link-stats  rx_packets 2>$stderr | grep $dev.rx_packets | awk '{print $2}'`
	tc_fail_if_bad $? "Failed to read the rx_packets for $dev"
	tx2=`nl-link-stats  tx_packets 2>$stderr | grep $dev.tx_packets | awk '{print $2}'`
	tc_fail_if_bad $? "Failed to read the tx_packets for $dev"

	# Make sure the count has gone up.
	if [ $rx1 -le $rx2 ] || [ $tx1 -le $tx2 ];
	then
       		tc_pass
        else
		tc_fail "Expected changes in counts:" \
		       "rx1:$rx1 - rx2: $rx2" \
       			"tx1:$tx1, tx2:$tx2"
	fi
}

function test_addr_dump()
{
	
	tc_register "Dump addresses using nl-addr-dump"

	if [ "x$ip" == "x" ] 
	then 
		ip="127.0.0.1"
		tc_info "No ip info available from hostname, using lo"
	fi

	nl-addr-dump brief >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to fetch address" || return;

	grep $ip  $stdout &>/dev/null
	tc_fail_if_bad $? "Failed find the $ip using nl-addr-dump" || return

	dev=`grep $ip $stdout | awk '{print $4}'  2>/dev/null|head -n 1`
	tc_info "Found device \"$dev\" with $ip"

	grep "scope host" $stdout &>/dev/null
	tc_pass_or_fail  $? "Failed to fetch loopback address"
}

function test_list_sockets()
{
	tc_register "List sockets using nl-list-socket"

	nl-list-sockets >$stdout 2>$stderr 
	tc_fail_if_bad $? "nl-list-socket execution failed" || return

	#Format of the out put is :
	# Address    	Family           PID    Groups   rmem   wmem   CB         refcnt        drops
	# [Hex Address]	[Name/Num]	[Num]	[Num]	[NUM]	[NUM]	[HexAddr]/(null)	[NUM]	[NUM]
	grep -v "^Address" $stdout > $TCTMP/result.list_sockets
	cat $TCTMP/result.list_sockets |  \

        grep "0x[[:xdigit:]]\+[[:space:]]\+[[:alnum:]_]\+[[:space:]]\+[[:digit:]]\+[[:space:]]\+[[:digit:]]\+[[:space:]]\+[[:digit:]]\+[[:space:]]\+[[:digit:]]\+[[:space:]]\+\(\(0x[[:xdigit:]]\+\)\|(null)\)[[:space:]]\+[[:digit:]]" &>/dev/null
	tc_pass_or_fail $? "Unexpected format of o/p:"\
	"Please verify if the format confirms to:"\
	"[Hex Address] [Name/Num]      [Num]   [Num]   [NUM]   [NUM]   [HexAddr]/(null)       [NUM]        [NUM]" \
	"=========== stdout below =============" \
	"$(< $stdout)"\
	"======================================"
}

function test_route_dump()
{
	tc_register "Dump route info using nl-route-dump"

	nl-route-dump brief >$stdout 2>$stderr
	tc_fail_if_bad $? "nl-route-dump execution failed" || return

	# We should expect to see "default" route output
	# default dev <devname> [via <ipaddr>] scope <scopename>
	grep "^default dev [a-z0-9A-Z\. :]\+ scope [a-zA-Z]\+" $stdout &>/dev/null

	tc_pass_or_fail $? "Failed to get default route information" \
	"Expected to see lines of the format"\
	"default dev <devname> [via <ipaddr>] scope <scopename>" \
	"=========== stdout below =========" \
	"$(< $stdout)"\
	"=================================="
}

function test_neigh_dump()
{
	tc_register "Dump neighbour info using nl-neigh-dump"

	nl-neigh-dump brief dev $dev >$stdout 2>$stderr
	tc_fail_if_bad $? "Execution of nl-neigh-dump failed" || return

	# We should see lines of the following format
	# <ip addr> dev $dev lladdr <addr> *
	grep "[0-9A-Fa-f:\.]\+ dev $dev lladdr [0-9A-Fa-f:\.]\+" $stdout &>/dev/null

	tc_pass_or_fail $? "Expected to see lines of the following format in o/p" \
	"<ip addr> dev $dev lladdr <addr> *" \
	"=========== stdout =============="\
	"$(< $stdout)" \
	"================================="
}

function test_route_get()
{
	local dst="10.0.0.1"

	tc_register "Get the route to an address in the network(nl-route-get)"

	nl-route-get $dst >$stdout 2>$stderr
	tc_fail_if_bad $? "Execution of nl-route-get failed" || return
        default_route=`grep preferred-src $stdout`
        rout_ip=`echo $default_route |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
        ip route show | grep -q $rout_ip &>/dev/null
        tc_pass_or_fail $? "Failed to get the route to an address in the network "    
}

function test_tctree_dump()
{
	[ -e /proc/net/psched ] || {
		tc_info "CONFIG_NET_SCHED is not enabled. skipping traffic control tree tests"
		return
	}

	tc_register "Dump traffic control tree using nl-tctree-dump"
	
	nl-tctree-dump brief >$stdout 2>$stderr
	tc_fail_if_bad $? "Execution of nl-tctree-dump failed" || return

	#Now we should see the line for $dev in the output. The format is:
	# $dev <type-of-dev> [<address>]  <attr1,attr2,attr3,...,up,running,...>
	# So we should see at least two attributes for the device.
	# i.e, up and running !
	grep "^$dev" $stdout 2>/dev/null | grep "running" &>/dev/null

	tc_pass_or_fail $? "Expected traffic control info for $dev in o/p" \
	"$dev <type> [<addr>] <attr1,...,attrn>" \
	"========= stdout ============"\
	"$(< $stdout)" \
	"============================="
}

tc_setup

# The first test is important. Thats where we get the $dev, $ip info from.
test_addr_dump || exit

test_link_stats 
test_list_sockets
test_route_dump
test_neigh_dump
test_route_get
test_tctree_dump
