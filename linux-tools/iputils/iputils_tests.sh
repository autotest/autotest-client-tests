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
## File :       iputils_tests.sh
##
## Description: This program tests basic functionality of iputils program
##
## Author:      Manoj Iyer  manjo@mail.utexas.edu
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

INSTALL_PGMS="ping ping6 arping clockdiff ifenslave rdisc tracepath tracepath6"

NAMESERVER=""

#
# setup
#
function tc_local_setup()
{
	local xxx=$(route -n | grep "^0.0.0.0")
	[ "$xxx" ] && set $xxx && iface=$8
	[ "$iface" ]
	tc_break_if_bad $? "can't find network interface" || return
	tc_info "Using iface $iface"

        xxx=$(route -n | grep "^0.0.0.0 .*UG.*$iface$")
        [ "$xxx" ] && set $xxx && router=$2
        [ "$router" ]
        tc_break_if_bad $? "can't find router" || return
	tc_info "Using router $router"

        # read dns server from configuration /etc/resolv.conf
	local SERVERADDRS
        while read RESOLV
        do
                [ "$RESOLV" == "" ] && continue
                set $RESOLV
                [ "$1" == "nameserver" ] && { shift ; SERVERADDRS="$SERVERADDRS $1" ; }
        done </etc/resolv.conf

	SERVERADDRS="$SERVERADDRS $router"	# as last resort
        [ "$SERVERADDRS" != ""  ]
        tc_break_if_bad $? "no name servers found in /etc/resolv.conf" || return

        for SERVERADDR in $SERVERADDRS
        do
		tc_info "attempting to access nameserver $SERVERADDR"
                ping -c 1 $SERVERADDR > /dev/null && { NAMESERVER=$SERVERADDR ; break ; }
        done
        [ "$NAMESERVER" ]
        tc_break_if_bad $? "could not ping a name server. tried $SERVERADDRS" || return
	tc_info "Using $NAMESERVER as nameserver"
}
#
# clean up
#
tc_local_cleanup()
{
    #arp table entries are messed up by this testcase which is
    #causing trouble (bug 99129), in running many of the other testcases;
    #So restartig the network. These lines can be removed once the bug
    #get fixed.
    tc_service_restart_and_wait network
}

#
# installation check
#
function test01()
{
    tc_register "installation check"
    tc_executes $INSTALL_PGMS
    tc_pass_or_fail $? "iputils not installed properly"
}

#
# arping nameserver
#
function test02()
{
    tc_register    "arping router"
    
    arping -c 3 -I $iface $router >$stdout 2>$stderr
    tc_fail_if_bad $? "Unexpected response from \"arping -c 2 -I $iface $router\"" || return

    grep -qi "reply from $router" $stdout
    tc_pass_or_fail $? "Expected to see \"reply from $router\" in stdout"
}


#
# tracepath nameserver
#
function test03()
{
    tc_register    "tracepath nameserver"
    
    tracepath -n $NAMESERVER >$stdout 2>$stderr
    tc_fail_if_bad $? "Unexpected response from \"tracepath $NAMESERVER\"" || return
    
    grep -qi LOCALHOST $stdout; RC=$?
    tc_pass_or_fail $RC "did not get expected response."
}

#
# clockdiff nameserver
#
function test04()
{
    tc_register "clockdiff localhost"

    clockdiff localhost 2>&1 | grep -q "non-standard format" &&   # some systems have strange output
    tc_pass_or_fail $?  && return # pass if non-standard format is returned.

    clockdiff localhost >$stdout 2>$stderr
    tc_pass_or_fail $? "Unexpected response from \"clockdiff localhost\"" || return
    # NOTE: There is no usefull comparison that can be made to the output. For
    # some odd reason the interesting stuff disappears when output is redirected.
}

function test05()
{
    tc_register "clockdiff -o localhost"
    clockdiff -o localhost 2>&1 | grep -q "non-standard format" &&   
    tc_pass_or_fail $?  && return
    clockdiff -o localhost >$stdout 2>$stderr
    tc_pass_or_fail $? "Unexpected response from \"clockdiff -o localhost\"" || return
}

################################################################################
# ipv6 tests
################################################################################

#
# do_ping6
#	$1 interface	(required)
#	$2 ip address	(required)
#	$3 count	(optional)
#
function do_ping6()
{
	local iface ip_addr count timeout

	iface=$1
	ip_addr=$2
	count=$3

	[ "$iface" -a "$ip_addr" ]
	tc_break_if_bad $? "INTERNAL TESTCASE ERROR: $FUNCNAME called w/o required arguments" || exit

	[ "$count" ] || count=3
	((timeout=count*2))

	ping6 -W $timeout -c $count -I $iface $ip_addr >$stdout 2>$stderr
}

#
# find ipv6 router and ping it
#
function ping6_router()
{
	local router_line router_ip router_iface
	local requires="grep ping6"

	((++TST_TOTAL))
	tc_register "ping ipv6 router"

	ip -6 route >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from \"ip -6 route\"" || return

	router_line=$(grep "^default" $stdout ) && [ "$router_line" ] || {
		tc_info "No global scope address so skipping router test"
		return 0
	}

	tc_exec_or_break $requires || return

	set $router_line
	router_ip=$3
	router_iface=$5

	tc_info "router_ip=$3 router_iface=$5"

	do_ping6 $router_iface $router_ip 2
	tc_pass_or_fail $? "trouble with ping6"
}

#
# ping all ipv6 addresses of this system
#
function ping6_all()
{
	local requires="ping6"
	local addr iface 
	local -a addrs=(${TC_IPV6_ADDRS[@]})
	local -a ifaces=(${TC_IPV6_IFACES[@]})

	while [ "$addrs" ] ; do
		addr=$(tc_array_top addrs) ; tc_array_pop addrs
		iface=$(tc_array_top ifaces) ; tc_array_pop ifaces
		((++TST_TOTAL))
		tc_register "ping6 $addr on $iface"
		tc_exec_or_break $requires || return
		do_ping6 $iface $addr
		tc_pass_or_fail $? "trouble with ping6"
	done
}

#
# tracepath6
#
function tracepath6_router()
{

        local addr iface scope at_least_one
        local -a addrs=(${TC_IPV6_ADDRS[@]})
        local -a scopes=(${TC_IPV6_SCOPES[@]})

        # find globally scoped address of this system
        while [ "$addrs" ] ; do
                addr=$(tc_array_top addrs); tc_array_pop addrs
                scope=$(tc_array_top scopes); tc_array_pop scopes
                [ "$scope" = "global" ] || continue
		((++TST_TOTAL))
		tc_register "tracepath6 router $addr $scope"
                tracepath6 $addr >$stdout 2>$stderr
                tc_pass_or_fail $? "Unexpected response from tracepath6 $addr"
		at_least_one=yes
        done
	[ "$at_least_one" = "yes" ] ||
        tc_info "No globally scoped address so test skipped"
        return 0
}


# 
# main
#

TST_TOTAL=5
tc_setup

tc_root_or_break || exit
tc_exec_or_break  grep || exit

test01
test02
test03
test04
test05

tc_ipv6_info && {
	tracepath6_router
	ping6_router
	ping6_all
}
