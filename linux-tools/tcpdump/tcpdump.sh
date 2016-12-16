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
## File :	tcpdump.sh
##
## Description:	Test tcpdump package
##
## Author:	Andrew Pham, apham@austin.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/tcpdump
source $LTPBIN/tc_utils.source

REQUIRED="hostname grep wc cat"

kill_me=""	# PID of ping process
kill_me2=""	# PID of another ping process

PROTO=""	# set to "ip" for ipv4 or "ip6" for IPv6 tests

function tc_local_setup()
{
	tc_root_or_break || exit
	tc_exec_or_break $REQUIRED || exit

	DN=$(hostname -s)
	[ "$DN" ]
	tc_break_if_bad $? "Could not get hostname" || exit
	tc_get_iface
	IF_NAME=$TC_IFACE
	if [ "$IF_NAME" == "" ]; then
		IF_NAME="lo"
	fi
	tc_info "Using $IF_NAME as the interface." 
	tc_info "Please make sure $IF_NAME has the address $(hostname -i)" 
}

function tc_local_cleanup()
{
	[ "$kill_me" ] && kill "$kill_me" &>/dev/null
	[ "$kill_me2" ] && kill "$kill_me2" &>/dev/null
	[ -f $TCTMP/hosts ] && cp $TCTMP/hosts /etc/hosts
}

################################################################################
# testcase functions
################################################################################

function test01()
{	
	cmd="tcpdump -c 2 $PROTO"
	tc_register "$cmd: See that exactly two packets are dumped"

	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." || return

	grep -q "2 packets captured" $stdout
	tc_pass_or_fail $? "Expected 2 packets captured" || return
}

function test02()
{
	local dn=$DN
	[ "$PROTO" == "ip6" ] && dn="${dn}-ipv6"
	cmd="tcpdump -c 9 $PROTO host -i $IF_NAME $dn"
	tc_register "$cmd: limit output to host $dn"

	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." \
			"$(cat /etc/hosts)" || return

	grep -q "9 packets captured" $stdout
	tc_fail_if_bad $? "Expected 9 packets captured" || return

        local -i lines=$(grep "$DN" $stdout | wc -l)
        ((lines==9))
        tc_pass_or_fail $? "" "All 9 captures should be for $DN"
}

function test03()
{
	cmd="tcpdump -c 3 -n $PROTO"
	tc_register "$cmd: show ip instead of name"
	
	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." || return 

	grep -q $DN $stdout 2>$stderr
	[ $? -ne 0 ]
	tc_pass_or_fail $? "Expected $DN to NOT be in stdout" || return  
}

function test04()
{
	cmd="tcpdump -c 3 -t $PROTO"
	tc_register "$cmd: don't print timestamp"
	
	tcpdump -c 3 -t $PROTO &>$stdout
	tc_fail_if_bad $? "is not working." || return  

	grep -q -E "^[0-9]{2}:[0-9]{2}:[0-9]{2}\." $stdout 
	[ $? -ne 0 ]
	tc_pass_or_fail $? "Expected NO timestamp in stdout"
}

function test05()
{
	cmd="tcpdump -c 3 -X $PROTO"
	tc_register "$cmd: print hex"
	
	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." || return  

	grep -q -E "0x[0-9a-fA-F]{4}:  ([0-9a-fA-F]{4} ){8} *"  $stdout
	tc_pass_or_fail $? "Expected HEX in stdout"
}

function test06()
{
	cmd="tcpdump -c 9 -i lo $PROTO"
	tc_register "$cmd: dump only lo activity in midst of ethx clutter"
	
	local PING=ping
	[ "$PROTO" = "ip6" ] && PING="ping6 -I lo"

	#This is purposefully kept "ping" and not "$PING" because in case of IPv6, 
	#"ping6 -I lo" without any areguments fails, 
	#and then it tries to use busybox ping even on machines where ping6 is available. 
	#And the assumption is, machines that do not have "ping" will not have "ping6"
	tc_executes ping || {
        	PING="busybox ping"
		[ "$PROTO" = "ip6" ] && PING="busybox ping6 -I lo"
		tc_info "will use busybox ping"
	}

	$PING localhost &>/dev/null & kill_me2=$!
	tc_break_if_bad $? "\"$PING localhost\" is not working." || return  

	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." || return

	kill $kill_me2
	tc_wait_for_no_pid $kill_me2
	tc_break_if_bad $? "cannot kill \"$PING localhost\"" || return

	grep -q "localhost" $stdout
	tc_fail_if_bad $? "should see localhost in the output" || return

	grep -q "9 packets captured" $stdout
	tc_fail_if_bad $? "9 packets should have been captured" || return
	
	if [ "$PROTO" = "ip" ]; then
	{
		tc_info "checking all captures should be for localhost"
		local -i lines=$(grep localhost $stdout | wc -l)
		((lines==9))
		tc_pass_or_fail $? "" "All 9 captures should be for localhost" || return 
        }
	else
	# For IPv6 not checking whether all lines in the tcpdump output are for lo, for following reason -
	# Traffic from "$PING6 -I $TC_IPV6_link_IFACES ff02::1" would also be trapped by above tcpdump command since -
	# ping6 request on a local m/c, sent on "eth0" to link-local addresses (ping6 -I eth0 ff02::1)
	# causes "lo" to  generate echo replies. It is an intended behaviour. For more details refer bug #41350.
	# When the kernel knows it's for the local machine, even if the address
	# is attached to a physical device, it routes the packet over loopback.
	
		tc_pass_or_fail 0 "$cmd passed"
	fi
}

function test07()
{
	local -i packet_no=10
	local -i line_no=0

	tc_register "tcpdump read/write files $PROTO"
	
	tcpdump -c $packet_no -w $TCTMP/tcpdump_w.log $PROTO &>$stdout
	tc_fail_if_bad $? "unexpected response from \"tcpdump -c $packet_no -w $TCTMP/tcpdump_w.log\"" || return  

	# read packets from $TCTMP/tcpdump_w.log to see if there are 10 packets captured
	tcpdump -r $TCTMP/tcpdump_w.log $PROTO &>$stdout
	tc_fail_if_bad $? "unexpected response from \"tcpdump -r\"" || return
	line_no=$(grep -E "^[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{6}" $stdout |wc -l)
	((line_no == packet_no ))
	tc_pass_or_fail $? "Expected to capture $packet_no packets in tcpdump_w.log"
}

function test08()
{
	tc_register "tcpdump printing out ethernet packets $PROTO"
	tcpdump -e -c 1 $PROTO &>$stdout
	tc_fail_if_bad $? "Unexpected response from \"tcdump -e -c 1\"" || return
	grep -qE "([0-9a-zA-Z][0-9a-zA-Z]:){5}" $stdout
	tc_pass_or_fail $? "Expected to see mac address in output"
}

function testlo_01()
{
	cmd1="ping -c 2 localhost"
	cmd="tcpdump -i $IF_NAME -c 2 $PROTO"

	$cmd1 &
	tc_register "$cmd: See that exactly two packets are dumped"

	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." || return

	grep -q "2 packets captured" $stdout
	tc_pass_or_fail $? "Expected 2 packets captured" || return
}

function testlo_02()
{
	cmd1="ping -c 9 localhost"
	cmd="tcpdump -i $IF_NAME -c 9 $PROTO host 127.0.0.1"
	$cmd1 &

	tc_register "$cmd: limit output to host $dn"

	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." \
			"$(cat /etc/hosts)" || return

	grep -q "9 packets captured" $stdout
	tc_fail_if_bad $? "Expected 9 packets captured" || return
	local -i lines=$(grep "localhost" $stdout | wc -l)
	((lines==9))
	tc_pass_or_fail $? "" "All 9 captures should be for $DN"
}

function testlo_03()
{
	cmd1="ping -c 3 localhost"
	cmd="tcpdump -i $IF_NAME -c 3 -X $PROTO"
	$cmd1 &

	tc_register "$cmd: print hex"

	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." || return

	grep -q -E "0x[0-9a-fA-F]{4}:  ([0-9a-fA-F]{4} ){8} *"  $stdout
	tc_pass_or_fail $? "Expected HEX in stdout"
}

function testlo_04()
{
	cmd="tcpdump -c 9 -i $IF_NAME $PROTO"
	tc_register "$cmd: dump only lo activity in midst of ethx clutter"

	local PING=ping

	$PING localhost &>/dev/null & kill_me2=$!
	tc_break_if_bad $? "\"$PING localhost\" is not working." || return

	$cmd &>$stdout
	tc_fail_if_bad $? "is not working." || return

	kill $kill_me2
	tc_wait_for_no_pid $kill_me2
	tc_break_if_bad $? "cannot kill \"$PING localhost\"" || return

	grep -q "localhost" $stdout
	tc_fail_if_bad $? "should see localhost in the output" || return

	grep -q "9 packets captured" $stdout
	tc_fail_if_bad $? "9 packets should have been captured" || return

	tc_info "checking all captures should be for localhost"
	local -i lines=$(grep localhost $stdout | wc -l)
	((lines==9))
	tc_pass_or_fail $? "" "All 9 captures should be for localhost" || return
}

function tc_find_gateway()
{
	local iface dest gateway flags junk 
	while read iface dest gateway flags junk ; do
	[ "$flags" = "Flags" ] && continue     # skip header

		# EITHER OF THE NEXT TWO WORK!
		(( (0x$flags&0x3) != 0x3 ))    && continue # not active (0x2) gateway (0x1)

	echo "$gateway"                        # found it!
	exit                                   # so we're done
	done < /proc/net/route
}

################################################################################
# main
################################################################################

tc_setup

################################################################################
# IPv4 testing
##############

TST_TOTAL=8
tc_info "============ IPv4 tests ============="
tc_info "Issuing ping -b 255.255.255.255 or busybox ping <gateway>"
PING=ping
tc_executes $PING || {
	PING="busybox ping"
	tc_info "will use busybox ping"
}
tc_exec_or_break "$PING" || return

# make some network traffic
if (! tc_is_busybox $PING) then
	$PING -b 255.255.255.255 &>/dev/null &
	kill_me="$!"
	tc_break_if_bad $? "Cannot ping" || exit
else
	gateway_hex=$(tc_find_gateway)

	[ "$gateway_hex" ]
	tc_break_if_bad $? "cannot find gateway" || exit

	h1=${gateway_hex:6:2}
	h2=${gateway_hex:4:2}
	h3=${gateway_hex:2:2}
	h4=${gateway_hex:0:2}

	d1=$(tc_hex2dec $h1)
	d2=$(tc_hex2dec $h2)
	d3=$(tc_hex2dec $h3)
	d4=$(tc_hex2dec $h4)

	gateway=$d4.$d3.$d2.$d1
	#gateway=$d1.$d2.$d3.$d4
	
	$PING $gateway &>/dev/null &
	kill_me="$!"
	tc_break_if_bad $? "Cannot ping" || exit
fi

PROTO="ip"

if [ "$IF_NAME" == "lo" ]; then
	TST_TOTAL=4
	for i in 01 02 03 04 ; do
		testlo_$i
	done

	kill $kill_me
	tc_wait_for_no_pid $kill_me
	tc_break_if_bad $? "Could not kill ping pid $kill_me" || exit	
else
	i=1
	while (( i <= TST_TOTAL )) ; do
		test0$i
		((++i))
	done
	
	kill $kill_me
	tc_wait_for_no_pid $kill_me
	tc_break_if_bad $? "Could not kill ping pid $kill_me" || exit
	
################################################################################
# IPv6 testing
##############
	
	tc_ipv6_info || exit 0	# IPv6 not configured
	[ "$TC_IPV6_link_IFACES" ] && [ "$TC_IPV6_link_ADDRS" ]
	tc_break_if_bad $? "IPv6 not configured with a link-scope interface" || exit
	
	cp /etc/hosts $TCTMP/hosts
	echo "$TC_IPV6_link_ADDRS" ${DN}-ipv6 >> /etc/hosts
	# Name Services Caching Daemon: Invalidate the hosts cache
	type nscd &>/dev/null && nscd -i hosts
	
	tc_info "============ IPv6 tests ============="
	tc_info "Issuing ping6 -I $TC_IPV6_link_IFACES ff02::1 (IPV6 broadcast equivalent)"
	PING6=ping6
	tc_executes $PING6 || {
		PING6="busybox ping6"
		tc_info "will use busybox ping6"
	}
	tc_exec_or_break "$PING6" || return
	
	$PING6 -I $TC_IPV6_link_IFACES ff02::1 &>/dev/null &
	kill_me=$!
	tc_break_if_bad $? "Cannot ping6" ||exit
	
	PROTO="ip6"

	((TST_TOTAL+=8))
	for i in 01 02 03 04 05 06 07 08 ; do
		test$i
	done
fi
