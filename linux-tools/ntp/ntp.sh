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
## File :       ntp.sh 
##
## Description: This program tests basic functionality of ntpd demon
##
## Author:      Manoj Iyer  manjo@mail.utexas.edu
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/ntp
source $LTPBIN/tc_utils.source
tc_get_os_arch || return
restart_ntpd="no"

#############################################################################
# Utility functions
#############################################################################

#
# create new ntp.conf file, saving original
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break cat grep tail sleep || return
        if [ "$TC_OS_ARCH" != "s390x" ]; then
               export NTP_SERVER=test1.au.example.com
        else
               export NTP_SERVER=lnx1.boe.example.com
        fi
	ps -elf | grep ntpd | grep -vq grep && restart_ntpd="yes"

	[ -e /etc/ntp.conf ] && mv /etc/ntp.conf $TCTMP

	cat <<-EOF > /etc/ntp.conf
		# SPECIAL ntp.conf file for use by testcase.
		
		# ntpd will use syslog() if logfile is not defined
		#logfile /var/log/ntpd
		
		driftfile /var/lib/ntp/ntp.drift
		statsdir /var/log/ntpstats/
		server $NTP_SERVER
		
		statistics loopstats peerstats clockstats
		filegen loopstats file loopstats type day enable
		filegen peerstats file peerstats type day enable
		filegen clockstats file clockstats type day enable
		
	EOF
	my_syslog=$TCTMP/my_syslog
	tc_cap_log_start $my_syslog || return
}

function tc_local_cleanup()
{
	[ $? -eq 0 ] || {
		tc_info "=========== my syslog ================"
		cat $my_syslog
		tc_info "======================================"
	}
	tc_cap_log_stop
	[ -e $TCTMP/ntp.conf ] && mv $TCTMP/ntp.conf /etc
	if [ $restart_ntpd == "yes" ] ; then 
		tc_service_restart_and_wait ntpd &>/dev/null
	else 
		systemctl stop ntpd &>/dev/null
	fi
}

#############################################################################
# Test functions
#############################################################################

function test01()
{
	tc_register	"Installation check"
	tc_service_start_and_wait ntpd >$stdout 2>$stderr
	tc_pass_or_fail $? "ntp not installed"
}

function test02()
{
	tc_register    "start ntpd daemon"

	# restart ntp demon and check for messages in syslog.
	tc_service_restart_and_wait ntpd >$stdout 2>$stderr
	tc_fail_if_bad $? "failed to start daemon" || return
	tc_wait_for_file_text $my_syslog "ntpd"
	tc_fail_if_bad $? "ntpd message not recorded in syslog" || return
	tc_wait_for_file_text $my_syslog "precision"
	tc_fail_if_bad $? "\"precision\" Not recorded in syslog" || return
	tc_wait_for_file_text $my_syslog "Listen normally on"
	tc_fail_if_bad $? "\"Listen normally on\" Not recorded in syslog" || return
	tc_wait_for_file_text $my_syslog "freq_set kernel"
	tc_pass_or_fail $? "\"freq_set kernel\" Not recorded in syslog"
	systemctl stop ntpd >$stdout 2>$stderr
}

function test03()
{
	export LANG=C

	local year actual
	before=$(date  +%Y)
	new=$((before+1))

	tc_register    "ntpdate"

	tc_info "Changing date one year ahead to $new at $(date)"

	actual=$(date)
	date -s "${actual/$before/$new}" >/dev/null
        tc_info "Date is now: $(date)"
        tc_info "calling ntpdate $NTP_SERVER"
	ntpdate $NTP_SERVER >$stdout 2>$stderr 
	tc_fail_if_bad $? "ntpdate failed" 
	rc=$?
        tc_info "Date is now set to: $(date)"

	# Save the year here
	after=$(date +%Y)
	
	# now restore the date
	actual=$(date)
	date -s "${actual/$after/$before}" &>/dev/null
	tc_info "Restored date to $(date)"

	#ntpdate exec failed. return here
	[ $rc -ne 0 ] && return

	# check if ntpdate restored the date to proper value
	[ $before -eq $after ]
	
	tc_pass_or_fail $? "ntpdate failed to set the year to normal time"
}

#############################################################################
# main
#############################################################################

TST_TOTAL=2
tc_setup        # exits on failure

test01 &&
test02 &&
test03
