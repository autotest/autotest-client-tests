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
#
# File :	arpwatch_tests.sh
#
# Description: This program tests basic functionality of arpwatch command.
#
# Author:	Manoj Iyer  manjo@mail.utexas.edu
#
#

###############################################################################
# source the utility functions
###############################################################################

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

interface=
running=0

###############################################################################
# utility functions
###############################################################################

#
# tc_local_setup	Check dependencies; get alias interface.
#
function tc_local_setup()
{
	# check dependencies
	tc_root_or_break || return
	tc_exec_or_break cat head tail ifconfig grep rsyslogd || return

	# save the autofs status
	tc_service_status arpwatch
	ARPWATCH_STATUS=$?
	if [ $ARPWATCH_STATUS -eq 0 ]; then
		tc_service_stop_and_wait arpwatch
	fi
	# get the default interface
	tc_get_iface	# sets TC_IFACE and TC_ROUTER
	[ "$TC_IFACE" ]
	tc_break_if_bad $? "Can't find network interface" || return
}

#
#	Restore networking, kill arpwatch.
#
function tc_local_cleanup()
{
	# stop arpwatch
	tc_service_stop_and_wait arpwatch ||
	killall arpwatch &>/dev/null

	# recover the environment
	if [ $ARPWATCH_STATUS -eq 0 ]; then
		tc_service_start_and_wait arpwatch
        fi
}

###############################################################################
#	test functions
###############################################################################

#
#	test01	ensure arpwatch installed
#
function test01()
{
	tc_register "is arpwatch installed?"
	tc_executes arpwatch
	tc_pass_or_fail $? "arpwatch NOT installed"
}

#
# test02	See that arpwatch starts w/o error
#
function test02()
{
	tc_register "start arpwatch"

	local syslog=$TCTMP/syslog
	tc_cap_log_start $syslog

	cat /dev/null > $TCTMP/arp.dat	# required for arpwatch
	arpwatch -i $TC_IFACE -f $TCTMP/arp.dat >$stdout 2>$stderr
	tc_fail_if_bad $? "failed to start arpwatch on interface $TC_IFACE" || return

	tc_wait_for_file_text $syslog "arpwatch: listening on $TC_IFACE"
	tc_pass_or_fail $? "arpwatch failed to report \"listening\"" \
		"syslog has"$'\n'"$(<$syslog)" || return
}

#
# test03	See that arpwatch logs data
#
function test03()
{
	local syslog=$TCTMP/syslog CMD

	tc_get_os_arch	# sets TC_OS_ARCH

	unset CMD
	while true ; do
		tc_executes qetharp &>/dev/null && CMD="qetharp -d $TC_IFACE -i $TC_ROUTER" && break
		tc_executes traceroute &>/dev/null && CMD="traceroute -q 1 $TC_ROUTER" && break
		# could look for other commands here ...
		# tc_executres ...
		break
	done
	[ "$CMD" ]  || {
		tc_info "can't find a command to generate arp activity so skipping this part"
		return 0
	}

	tc_register "arpwatch logging"

	tc_cap_log_start $syslog

	tc_info "Using \"$CMD\" in attempt to generate arp activity fo arpwatch to log"
	$CMD

	tc_wait_for_file_text $syslog "bogon" ||
	tc_wait_for_file_text $syslog "station"

	tc_pass_or_fail $? "arpwatch failed to report activity using syslog" \
		"syslog has"$'\n'"$(<$syslog)"
}

###############################################################################
#	main
###############################################################################

TST_TOTAL=2
tc_setup
test01 &&
test02 &&
test03
