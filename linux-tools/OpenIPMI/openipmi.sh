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
## File:         OpenIPMI.sh
##
## Description:  Tests OpenIPMI library using ipmitool.
##
## Author:       Abhishek Misra  <abmisra1@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/OpenIPMI
source $LTPBIN/tc_utils.source

REQUIRED="dmidecode egrep cut ipmitool"

#############################################################################
# Test lists
#############################################################################

declare -a V9_TESTS
V9_TESTS=(
	"firewall info lun 0 netfn 0"
	"firewall info lun 0 netfn 1"
	"firewall info lun 0 netfn 4"
	"firewall info lun 0 netfn 0 command 0"
	"firewall info lun 0 netfn 0 command 1"
	"firewall info lun 0 netfn 0 command 2"
	"firewall info lun 0 netfn 1 command 0"
	"firewall info lun 0 netfn 1 command 1"
	"firewall info lun 0 netfn 1 command 2"
	"firewall info lun 0 netfn 4 command 0"
	"firewall info lun 0 netfn 4 command 1"
	"firewall info lun 0 netfn 4 command 2"
	"firewall disable lun 0 netfn 0 command 2"
	"firewall enable lun 0 netfn 0 command 2"
	"channel getciphers ipmi 1"
	"channel getciphers sol 1"
)
declare -a TESTS
TESTS=(
	"lan print"
	"bmc getenables"
	"channel info 0"
        "channel info 1"
        "channel info 2"
        "channel info 14"
        "channel info 15"
        "channel authcap 1 1"
        "channel authcap 1 2"
        "channel authcap 1 3"
        "channel authcap 1 4"
        "channel getaccess 0x1"
        "channel getaccess 0x2"
        "chassis status"
        "chassis identify"
        "chassis restart_cause"
        "chassis power status"
        "pef info"
        "pef status"
        "pef list"
        "sdr info"
        "sdr list all"
        "sdr list full"
        "sdr list compact"
        "sdr list event"
        "sdr list mcloc"
        "sdr list fru"
        "sdr list generic"
        "sdr type list"
        "sdr entity"
        "sel"
        "sel info"
        "sel list"
        "sel elist"
        "sel list 5"
        "sel time get"
        "sel writeraw testing"
        "sel readraw testing"
        "sensor list"
        "session info all"
        "session info active"
        "user summary 0x1"
        "user summary 0x2"
        "user list 0x1"
	"user list 0x2"
)

#############################################################################
# Utility function
#############################################################################

#
# Local setup
#
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || exit

	dmidecode | egrep 'Baseboard Management Controller|IPMI' >$stdout 2>$stderr
	tc_break_if_bad $? "BMC is not detected. Aborting." || exit

}

#############################################################################
# Test functions
#############################################################################

#
# Run one test as passed on command line
#
function run_test()
{
	tc_register "$*"

	[ "$*" ]
	tc_break_if_bad $? "Internal script error: $FUNCNAME called without arguments" || exit

	ipmitool $* >$stdout 2>$stderr
	tc_pass_or_fail $? "Unexpected response from \"ipmitool $*\""
}

#
# Installation and startup check
#
function test00()
{
	tc_register "Check install and start OpenIPMI"

	/etc/init.d/ipmi restart >$stdout 2>$stderr
	tc_fail_if_bad $? "OpenIPMI not installed properly or would not start" || return

	VERSION="old"
	BMC2=$(ipmitool bmc info | grep "IPMI Version" | cut -b 29)
	VERSION=$(ipmitool -V | cut -b 22)
	((BMC2>=2)) && ((VERSION>=9)) && {
		((TST_TOTAL+=${#V9_TESTS[*]}))
		TESTS=( "${V9_TESTS[@]}" "${TESTS[@]}" )
	}
	TST_TOTAL=${#TESTS[*]}
	((++TST_TOTAL))		# to account for test00

	tc_info "ipmitool utility version: $(ipmitool -V)"
	tc_info "OpenIPMI Driver version: $(dmesg |grep ipmi |grep -i -m 1 version) "

	ipmitool event 1 >$stdout 2>$stderr
	tc_pass_or_fail $? "Could not start system event"
}

#############################################################################
# Main
#############################################################################

tc_setup

test00 || exit

((n=-1))
while ((++n < TST_TOTAL-1)) ; do
	run_test ${TESTS[n]}
done
