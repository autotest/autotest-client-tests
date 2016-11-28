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
### File : tuned                                         	              ##
##
### Description: This testcase tests tuned package                             ##
##
### Author:      Ravindran Arani <ravi@linux.vnet.ibm.com>                     ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/tuned
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/tuned/"

function tc_local_setup()
{
	rpm -q tuned >$stdout 2>$stderr
	tc_break_if_bad $? "tuned is not installed"
}

function runtests()
{
	pushd $TESTDIR >$stdout 2>$stderr
	TST_TOTAL=8

#Start tuned service if not already started:
	tc_register "tuned Service Start"
	tc_service_status tuned
	servicerc=$?
	if [ $servicerc -ne 0 ]; then
	tc_service_start_and_wait tuned
	fi

#List all available profiles:
	tc_register "List all available profiles"
	tuned-adm list |grep -i "balanced\|desktop\|latency-performance\|network-latency\|network-throughput\|powersave\|sap\|throughput-performance\|virtual-guest\|virtual-host" >$stdout 2>$stderr
	tc_pass_or_fail $? "profiles are not listed"

#Let tuned to recommend you the best profile for your system:
	tc_register "tuned-adm recommend command check"
	tuned-adm recommend >$stdout 2>$stderr
	tc_pass_or_fail $? "tuned-adm has failed to recommend profile"

#check the current set profile:
	tc_register "tuned-adm active command check"
	profile=`tuned-adm active|cut -d' ' -f4` >$stdout 2>$stderr
	if [ $? -eq 0 ] && [ ! -z "$profile" ]
	then RC=0
	else RC=1
	fi
	tc_pass_or_fail $RC "tuned-adm active has issues"

	tc_service_restart_and_wait tuned
#Try to switch between profiles:
	tc_register "test changing tuned profiles"
	if [ $profile != balanced ]
	then profile2set="balanced"
	else profile2set="powersave"	
	fi
	tuned-adm profile $profile2set >$stdout 2>$stderr
	tc_pass_or_fail $? "set profile failed"	

#Check if the profile was really set
	tc_register "test tuned profile change instruction"	
	newprofile=`tuned-adm active|cut -d' ' -f4` >$stdout 2>$stderr
	if [ $newprofile != $profile2set ]
	then RC=1
	else RC=0
	fi
	tc_pass_or_fail $RC "new profile is not set properly"

#Stop tuned service
	tc_register "Stop tuned service if not already stopped"
	tc_service_status tuned
	if [ $? -eq 0 ]; then
	tc_service_stop_and_wait tuned
	fi

#Restore tuned to its original configuration
	tc_register "Restore tuned to its original configuration"
	if [ $servicerc -ne 0 ]; then
	tc_service_stop_and_wait tuned
	else
	tc_service_start_and_wait tuned
	fi
	tuned-adm profile $profile >$stdout 2>$stderr
	RC=$?
	#below warnings showup when we try to set a profile while services are down. So, ignoring.
	tc_ignore_warnings "Cannot talk to Tuned daemon via DBus"
	tc_ignore_warnings "You need to (re)start the tuned daemon by hand for changes to apply"
	tc_pass_or_fail $RC "Restore of original config failed"
	popd >$stdout 2>$stderr
}

#
#MAIN
#
tc_setup
runtests
