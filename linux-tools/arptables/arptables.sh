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
## File :	arptables.sh
##
## Description:	Test arptables support
##
## Author:	Pritam S Gundecha, pritam.gundecha@in.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/arptables
source $LTPBIN/tc_utils.source

# global variables
router_ip=""    # router IP address
iface=""        # ethernet interface

ARP_TABLE_CMDS="arptables"	# only one command so far

################################################################################
# any utility functions specific to this file can go here
################################################################################

function tc_local_setup()
{
	tc_root_or_break || return

	# start with a clean slate
	rmmod arpchains &>/dev/null
	rmmod arpt_mangle &>/dev/null
	rmmod arpt_state &>/dev/null
	rmmod arp_conntrack &>/dev/null
	rmmod arptable_filter &>/dev/null
	rmmod arp_tables &>/dev/null

	return 0
}

function tc_local_cleanup()
{
	# clean the arptables entry
        # This is required if some testcase aborted after setting up the rule
        arptables -F >$stdout 2>$stderr
        tc_fail_if_bad $? "Unable to clean the arptables entries" || return

        return 0

}

################################################################################
# the testcase functions
################################################################################

#
# Get a router IP address.
# Results put in global var router_ip 
# On error test is BROK. Caller should go on to next test or exit testcase.
#
function get_router_ip()
{
	local xxx=$(route -n | grep "^0.0.0.0")
	[ "$xxx" ] && set $xxx && iface=$8
        [ "$iface" ]
        tc_break_if_bad $? "can't find network interface" || return
	
	xxx=$(route -n | grep "^0.0.0.0 .*UG.*$iface$")
	[ "$xxx" ] && set $xxx && router_ip=$2
	[ "$router_ip" ]
	tc_break_if_bad $? "can't find router" || return
}

#
# Installation check
#
function test01()
{
	tc_register "installation check"
	tc_executes $ARP_TABLE_CMDS
	tc_fail_if_bad $? "Not all arptables execcutables are installed" || return

	# force load of arptables module
	arptables -L >$stdout 2>$stderr
	tc_pass_or_fail $? "Unexpected response from \"arptables -L\". Are all modules present?"

	# remove the arptable entry if there
        # Otherwise cause problem if router is already blocked before running testscript
        arptables -F >$stdout 2>$stderr
        tc_fail_if_bad $? "Unable to remove the arptables entries" || return
}

#
# test02   (set/check rules: append(-A), delete(-D), list(-L))
#
function test02()
{
	tc_register "use rule to block router"
	tc_info "$FUNCNAME takes about 45 seconds..."

	# get the router ip address
	get_router_ip || return

	# be sure arp packets are not blocked for router_ip 
	ping -c 1 -w 5 -I $iface $router_ip >$stdout 2>$stderr
	tc_break_if_bad $? \
		"failed to receive the arp packets from router ip" || 
		return

	# add DROP rule
	arptables -A INPUT -i $iface -s $router_ip -j DROP >$stdout 2>$stderr
	tc_fail_if_bad $? \
		"arptables -A INPUT -i $iface -s $router_ip -j DROP failed" ||
		return

 	# remove the router entry from arp cache
	# this is necessary because till this entry is present we can not test the drop rule 
	arp -d $router_ip 

	# be sure DROP rule is set
	arptables -L INPUT >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -L INPUT failed" || return
	grep -q DROP $stdout 2>$stderr
	tc_fail_if_bad $? "failed to list DROP" || return

	# check that ping DROPped
	ping -c 1 -w 5 -I $iface $router_ip &>$stdout 
	[ $? -ne 0 ]
	tc_fail_if_bad $? "failed to DROP" || return

	# delete DROP rule
	arptables -D INPUT -i $iface -s $router_ip -j DROP >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -D INPUT -i $iface -s $router_ip -j DROP failed" || return

 	# remove the router entry from arp cache
	# this is necessary because till this entry is present we can not test the drop rule 
	arp -d $router_ip 

	# check that ping now works
	ping -c 1 -w 5 -I $iface $router_ip >$stdout 2>$stderr
	tc_pass_or_fail $? "failed to delete DROP; ping still fails!"
}

#
# test03   (set/check chain-command: create-chain(-N), and delete-chain(-X))
#
function test03()
{
	tc_register "set/check chain"

	# add user defined new chain: -N 
	local new="new-chain"
	arptables -N $new >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -N $new failed" || return

	# check if $new exist
	arptables -L >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -L failed" || return
	grep -q $new $stdout 2>$stderr
	tc_fail_if_bad $? "failed to create chain: $new" || return

	# remove user defined new chain: -X
	arptables -X $new >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -X $new failed" || return

	# $new should now be gone
	arptables -L >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -L failed" || return
	grep -q $new $stdout > $stderr
	[ $? -ne 0 ]
	tc_pass_or_fail $? "failed to delete new chain"
}

#
# test04    (set/check policy for chains)
#
function test04()
{
        tc_register "set/check policy"

	# set/check DROP policy on INPUT chain 
	arptables -P INPUT DROP >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -P INPUT DROP failed" || return
	arptables -L INPUT >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -L INPUT failed" || return
	grep -q DROP $stdout 2>$stderr
	tc_fail_if_bad $? "failed to set policy on INPUT" || return
        
        # Remove DROP policy on INPUT chain 
	arptables -P INPUT ACCEPT >$stdout 2>$stderr
        tc_fail_if_bad $? "arptables -P INPUT ACCEPT failed" || return

	# set/check policy on OUTPUT chain
	arptables -P OUTPUT DROP >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -P OUTPUT DROP failed" || return
	arptables -L OUTPUT >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -L OUTPUT failed" || return
	grep -q DROP $stdout 2>$stderr
	tc_fail_if_bad $? "failed to set policy on OUTPUT" || return
	
	# Remove DROP policy on OUTPUT chain
	arptables -P OUTPUT ACCEPT >$stdout 2>$stderr
        tc_fail_if_bad $? "arptables -P OUTPUT ACCEPT failed" || return

	# set/check policy on FORWARD chain
	arptables -P FORWARD DROP >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -P FORWARD DROP failed" || return
	arptables -L FORWARD >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -L FORWARD failed" || return
	grep -q DROP $stdout 2>$stderr
	tc_pass_or_fail $? "failed to set policy on FORWARD"

	# Remove DROP policy on FORWARD chain
	arptables -P FORWARD ACCEPT >$stdout 2>$stderr
        tc_fail_if_bad $? "arptables -P FORWARD ACCEPT failed" || return
}	

#
# test05    (set/check flush in filter tables)
#
function test05
{
	tc_register "set/check flush"

	# flush the filter table
	arptables -F >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -F failed" || return

	# add DROP so we can flush it
	arptables -A INPUT -j DROP >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -A INPUT -j DROP failed" || return
	arptables -L >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -L failed" || return
	grep -q DROP $stdout 2>$stderr
	tc_fail_if_bad $? "failed to set DROP (A)" || return

	# flush the filter table and be sure DROP is gone
	arptables -F >$stderr 2>$stdout
	tc_fail_if_bad $? "arptables -F failed" || return
	arptables -L >$stdout 2>$stderr
	tc_fail_if_bad $? "arptables -L failed" || return
	grep -q DROP $stdout 2>$stderr
	[ $? -ne 0 ]
	tc_pass_or_fail $? "failed to flush DROP (A)" || return
}

#
# test06	(mangle rule)
#
function test06()
{
	tc_register mangle

	# For the case where "hostname -i" returns more than one ip
	# check through the list of ip's in loop

	local ipaddr=$(hostname -i)
        set $ipaddr
	local mangled=localhost
	local chain=INPUT
	
	while [ $1 ]; do
		# On $chain, pretend that source $real is source $mangled
		local cmd="arptables -A $chain -s $1 -j mangle --mangle-ip-s $mangled"
		$cmd >$stdout 2>$stderr; RC=$?
		if [ $RC -eq 0 ]; then
			break
		else
			shift
		fi
	done
	tc_fail_if_bad $RC "CMD $cmd failed" || return

	cmd="arptables -L $chain"
	$cmd | grep mangle >$stdout 2>$stderr
	tc_fail_if_bad $? "$cmd failed to set mangle rule"

	cmd="arptables -F $chain"
	$cmd >$stdout 2>$stderr
	tc_fail_if_bad $? "CMD $cmd failed" || return

	cmd="arptables -L $chain"
	! $cmd | grep mangle >$stdout 2>$stderr
	tc_pass_or_fail $? "$cmd failed to flush mangle rule"

}	

##########################################################################################
# main
##########################################################################################

TST_TOTAL=6

# standard tc_setup
tc_setup

test01 && 
test02 && 
test03 && 
test04 &&
test05 &&
test06
