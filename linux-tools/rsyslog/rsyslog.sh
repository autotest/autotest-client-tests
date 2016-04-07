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
## File :	rsyslogd.sh
##
## Description:	check that rsyslog will listen to port 514 when started with  -r
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

SYSLOG_PORT=514
MUST_RESTART=no
IPVER=""
TAIL_LOGGER_PID=""
SYSLOGD_PID=""
TEST_HOSTNAME=""

tc_local_setup()
{
	tc_root_or_break || return
}

tc_local_cleanup()
{
	[ "$TAIL_LOGGER_PID" ] && kill $TAIL_LOGGER_PID
	[ "$SYSLOGD_PID" ] && kill $SYSLOGD_PID
	tc_wait_for_no_pid "$TAIL_LOGGER_PID $SYSLOGD_PID"
	[ -f "$TCTMP/rsyslog.conf" ] && mv $TCTMP/rsyslog.conf /etc/rsyslog.conf
	[ "$MUST_RESTART" = "yes" ] && systemctl restart rsyslog&>/dev/null
}

################################################################################
# the testcase functions
################################################################################

function test01()
{
	tc_register "installation check ($IPVER)"
	tc_exec_or_fail rsyslogd || return 

	tc_pass_or_fail 0	# pass if we get this far
}

function test02()
{
	tc_register "start rsyslogd ($IPVER)"

	TEST_HOSTNAME=localhost
	[ "$IPVER" = "ipv6" ] && {
					TEST_HOSTNAME=$TC_IPV6_global_ADDRS
		[ "$TEST_HOSTNAME" ] || TEST_HOSTNAME=$TC_IPV6_link_ADDRS
		[ "$TEST_HOSTNAME" ] || TEST_HOSTNAME=$TC_IPV6_host_ADDRS
		[ "$TEST_HOSTNAME" ]
		tc_break_if_bad $? "No IPv6 IP found." || return
	}

	# Replace rsyslog.conf with test version.
	# The test version forces log data to be forwarded back to rsyslog via
	# the network (IPv4 or IPv6).
	mv /etc/rsyslog.conf $TCTMP
	echo "\$ModLoad imuxsock.so" > /etc/rsyslog.conf
	echo "\$ModLoad imklog.so" >> /etc/rsyslog.conf
	echo "\$ModLoad imudp.so" >> /etc/rsyslog.conf
	echo "\$UDPServerRun 514" >> /etc/rsyslog.conf
	echo "*.* /var/log/messages" >> /etc/rsyslog.conf

	rm -f /var/run/syslogd.pid
	rsyslogd  >$stdout 2>$stderr &&
	tc_wait_for_file /var/run/syslogd.pid
	tc_fail_if_bad $? "Could not start syslogd with -r option." || return

	SYSLOGD_PID=$(cat /var/run/syslogd.pid)
	grep -q . /proc/$SYSLOGD_PID/maps
	tc_fail_if_bad $? "rsyslogd did not start." || return

	tc_wait_for_active_port $SYSLOG_PORT
	tc_pass_or_fail $? "rsyslog not listening on $SYSLOG_PORT."
}

function test03()
{
	# skip this test if no logger command
	tc_executes logger || {
		((--TST_TOTAL))
		tc_info "Skipping logger test since logger is not available."
		return 0
	}

	tc_register "See if rsyslog records something ($IPVER)"

	# Start logging snapshot
	tc_cap_log_start  $TCTMP/logfile
	tc_break_if_bad $? "Could not start tail of snapshot rsyslog." || return

	local message="test from $$"
	logger -t $IPVER "$message"

	tc_wait_for_file_text $TCTMP/logfile "$IPVER: $message" 30
	tc_pass_or_fail $? "Did not see \"$IPVER: $message\" in rsyslog." || {
		tc_info "============== rsyslog snapshot ================"
		cat $TCTMP/logfile
		tc_info "==============================================="
		return 1
	}
}

################################################################################
# main
################################################################################

TST_TOTAL=3
tc_setup			# standard tc_setup

IPVER=ipv4
test01 || exit
test02 &&
test03

tc_ipv6_info && {
	((TST_TOTAL+=2))
	tc_local_cleanup
	tc_local_setup
	IPVER=ipv6
	test02 &&
	test03
}
