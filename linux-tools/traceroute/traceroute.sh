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
### File : traceroute.sh                                                       ##
##
### Description: This testcase tests the traceroute package                    ##
##
### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TRACEROUTE_TESTS_DIR="${LTPBIN%/shared}/traceroute"
REQUIRED="awk sed"
tc_get_iface


function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return
      tc_check_package "traceroute"
	tc_break_if_bad $? "traceroute not installed" || return

	# Machine in boe lab cant access kjdev1.au.example.com
	# So, another dest host is needed for test machines in that lab
	tc_get_iface
	echo $TC_ROUTER | grep 9.152.128
	if [ $? -eq 0 ]
	then
		dest_host=$(grep lnx1.boe.example.com /etc/hosts | awk '{print $2}')
		dest_host_ip=$(grep lnx1.boe.example.com /etc/hosts | awk '{print $1}')
	else
		dest_host=$(grep kjdev1.au.example.com /etc/hosts | awk '{print $2}')
		dest_host_ip=$(grep kjdev1.au.example.com /etc/hosts | awk '{print $1}')
	fi
	ping -c 10 $dest_host 1>$stdout 2>$stderr
	tc_break_if_bad $? "Run the test by putting a pingable machine name in tc_local_setup" || return

}

#
# The test function 
#

function run_test()
{
	tc_register "Traceroute with default option"
	traceroute $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
	grep -q $dest_host $stdout
	tc_pass_or_fail $? "Traceroute with default option failed"

	tc_register "Traceroute with ICMP"
	traceroute -I $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
	grep -q $dest_host $stdout
	tc_pass_or_fail $? "Traceroute with ICMP option failed"

	tc_register "Print hop address numerically only"
	# This is a curious case of traceroute execution. If the tests are run
	# continously without any delay in between, the network nodes simply drops
	# the probe packets. So the test fails.
	sleep 05
	traceroute -n $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
	grep -q $dest_host_ip $stdout
	tc_pass_or_fail $? "Printing hop address numerically only failed"
	
	# Setting time delay between probes in miliseconds. Some systems such
	# as Solaris and routers such as Ciscos limits rate of icmp messages
	# If this is the only test that passes for a system, then we can guess
	# that there is some system in the probe path that expects some delay
	# between probes
	sleep 05
	tc_register "Set time delay between probes"
	traceroute -z 300 $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
	grep -q $dest_host $stdout
	tc_pass_or_fail $? "Time delay between probes failed"

	tc_register "Traceroute with TCP_SYN"
	traceroute -T $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
	grep -q $dest_host $stdout
	tc_pass_or_fail $? "Traceroute with TCP_SYN failed"

	tc_register "Traceroute without fragmenting probe packets"
	traceroute -F $dest_host|sed "1 d"|awk '{print $2}' 1>$stdout 2>$stderr
	grep -q $dest_host $stdout
	tc_pass_or_fail $? "Traceroute without fragmenting probe packet failed"

	tc_register "Traceroute with mtu"
	sleep 05
	mtu_value=`ifconfig $TC_IFACE | grep -i mtu | awk '{print $4}'`
	traceroute --mtu $dest_host|sed "1 d"|awk '{print $6}' 1>$stdout 2>$stderr
	grep -q "F=$mtu_value" $stdout
	tc_pass_or_fail $? "Traceroute with mtu failed"

	tc_register "Traceroute through a particular interface"
	grep -q $TC_IFACE /proc/net/dev
	tc_pass_or_fail $? "Traceroute through a particular interface failed"
}

#
# main
#
TST_TOTAL=8
tc_setup && run_test
