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
# File :	nmap.sh
#
# Description:	Tests for nmap package.
#
# Author:	Gowri Shankar <gowrishankar.m@in.ibm.com>
############################################################################################

#cd $(dirname $0)
#LTPBIN="${LTPBIN%/shared}/nmap"
source $LTPBIN/tc_utils.source
source $LTPBIN/domain_names.source
################################################################################
# test variables
################################################################################
installed="ncat ndiff nmap"
required="cp echo grep"
restart_xinetd="no"
restart_iptables="no"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return
	tc_add_user_or_break || return

	# check the status of other services used by test
	systemctl status xinetd.service &>/dev/null && restart_xinetd="yes"
	systemctl status iptables.service &>/dev/null && restart_iptables="yes"
	return 0
}

function tc_local_cleanup()
{

	# restart xinetd if required.
	systemctl stop xinetd.service &>/dev/null
	[ -e $TCTMP/echo-stream ] && cp $TCTMP/echo-stream /etc/xinetd.d/
	[ $restart_xinetd = "yes" ] && tc_service_start_and_wait xinetd >$stdout 2>$stderr

	# reload iptables if required.
	[ $restart_iptables = "yes" ] && iptables-restore < $TCTMP/iptables.bak
}

#
# test A
#  check nmap port scan techniques
#
function test_port_scan()
{
	tc_register "checking TCP Connect scan for less priviliged user"
	echo "nmap -sT localhost" | su - $TC_TEMP_USER 1>$stdout 2>$stderr
	tc_pass_or_fail $? "$TC_TEMP_USER not able to nmap"

	tc_register "checking TCP Syn scan for priviliged root"
	nmap -sS localhost 1>$stdout 2>$stderr
	tc_pass_or_fail $? "TCP Syn scan failed"

	tc_register "checking UDP scan"
	nmap -sU localhost 1>$stdout 2>$stderr
	tc_pass_or_fail $? "UDP scan failed"

	tc_register "check Protocol scan"
	nmap -sO localhost | egrep "1\s*open\s*icmp" 1>$stdout 2>$stderr
	tc_pass_or_fail $? "Protocol scan failed"
}

#
# test B
#  check nmap host discovery techniques
#
function test_host_discovery()
{
	tc_register "check List scan"
	nmap -sL localhost 1>$stdout 2>$stderr
	tc_pass_or_fail $? "List scan failed"

	tc_register "check Ping scan"
	nmap -sP $KJDEVX1 | grep 'Host is up' 1>$stdout 2>$stderr
	tc_pass_or_fail $? "Ping scan failed" || return

	tc_register "check --traceroute to trace hop path"
	nmap -sP --traceroute localhost | grep 'Host is up' 1>$stdout 2>$stderr
	tc_pass_or_fail $? "Ping scan failed"
}

#
# test C
#  check nmap service/version detection
#  enable a installed service and verify if nmap can report it.
#  add a custom service (and block a tcp/udp port). verify if nmap can
#  report it.
function test_version_detection()
{
	tc_register "check Version scan"
	# VERSION for ssh is OpenSSH 5.3 (protocol 2.0)
	nmap -sV localhost -p 22 | grep -q 'protocol 2.0' 1>$stdout 2>$stderr
	tc_pass_or_fail $? "Version scan failed"

	# RPC scan is no more supported in higher versions (6 onwards) of nmap
	# and is an alias to above version scan. Hence, disabling this test.
	# tc_register "check RPC scan"
	# nmap -sR localhost -p 22 | grep '22/tcp open  ssh' 1>$stdout 2>$stderr
	# tc_pass_or_fail $? "RPC scan failed"
}

#
# test D
#  check nmap OS detection
#
function test_os_detection()
{
	# OS scan is unreliable and sometimes, nmap guess. It need not be
	# a failure at this time.
	tc_register "check OS detection"
	nmap -sT localhost -p 22 -O 1>$stdout 2>$stderr
	tc_pass_or_fail $? "OS detection failed"
}

#
# test E
#  check firewall evasion and spoofing
#  block a TCP port of an installed service in IP firewall and verify
#  if nmap reports accordingly.
function test_firewall()
{
	tc_register "nmap firewall evasion and spoofing"

	local test_requires="xinetd iptables iptables-save iptables-restore"
	tc_exec_or_break $test_requires || return

	tc_info "enable echo service for test"
	[ -e /etc/xinetd.d/echo-stream ] && cp /etc/xinetd.d/echo-stream $TCTMP/
	sed -i 's/^\s*disable.*=.*/disable = no/' /etc/xinetd.d/echo-stream
	systemctl stop xinetd.service &>/dev/null
	tc_service_start_and_wait xinetd >$stdout 2>$stderr
	tc_break_if_bad $? "xinetd(echo) not restarting"

	tc_info "checking echo port with TCP scan"
	nmap -sT localhost -p 7 | grep '7/tcp open  echo' 1>$stdout 2>$stderr
	tc_fail_if_bad $? "echo (tcp/7) should be open"

	tc_info "checking echo port with ACK scan"
	nmap -sA localhost -p 7 | grep '7/tcp unfiltered echo' 1>$stdout 2>$stderr
	tc_fail_if_bad $? "echo (tcp/7) should be unfiltered"

	tc_info "blocking echo tcp/7 port"
	[ "$restart_iptables" = "yes" ] && iptables-save > $TCTMP/iptables.bak
	# Please check bug 84359
	#iptables -A INPUT -i lo -p tcp --dport 7 -j REJECT 1>$stdout 2>$stderr
	iptables -A INPUT -i lo -p tcp --dport 7 -j DROP 1>$stdout 2>$stderr
	tc_fail_if_bad $? "unable to add new rule in iptables"

	tc_info "checking echo port with TCP scan"
	nmap -sT localhost -p 7 | grep '7/tcp filtered echo' 1>$stdout 2>$stderr
	tc_fail_if_bad $? "echo (tcp/7) should be filtered in -sT scan"

	tc_info "checking echo port with ACK scan"
	nmap -sA localhost -p 7 | grep '7/tcp filtered echo' 1>$stdout 2>$stderr
	tc_pass_or_fail $? "echo (tcp/7) should be filtered in -sA scan"

	tc_info "cleaning up test rule from iptables"
	if [ "$restart_iptables" = "yes" ]; then
		iptables-restore < $TCTMP/iptables.bak
		restart_iptables="no"
	fi
}

#
# test F
#  check nmap scripting engine (NSE)
#
function test_nse()
{
	tc_register "checking default scripts"
	nmap -sC -p 22 localhost | grep 'ssh-hostkey' 1>$stdout 2>$stderr
	tc_pass_or_fail $? "checking ssh-hostkey in -sC failed"

	tc_register "checking banner script"
	nmap --script=banner -p 22  localhost | grep 'banner: SSH-' 1>$stdout 2>$stderr
	tc_pass_or_fail $? "checking banner script failed"
}

#
# test G
#  check IPv6 basic support
#  minimal support in nmap5.xx (only TCP, Pind and List scans without traceroute)
#
function test_ipv6()
{
	tc_register "check ipv6 tcp scan"
	nmap -6 -sT localhost6 | grep '111/tcp *open  rpcbind' 1>$stdout 2>$stderr
	tc_pass_or_fail $? "ipv6 tcp scan failed"
}

################################################################################
# main
################################################################################
TST_TOTAL=13
tc_setup

test_port_scan
test_host_discovery
test_version_detection
test_os_detection
test_firewall
test_nse
test_ipv6
