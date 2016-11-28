#!/bin/sh
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
## File :        test_netcf.sh
##
## Description:  This Testcase tests netcf package
##
## Author:       Basavaraju.G <basavarg@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/netcf
source $LTPBIN/tc_utils.source

TESTDIR=${LTPBIN%/shared}/netcf
# environment functions
################################################################################
#
# local setup
#
function tc_local_setup()
{
        rpm -q netcf >$stdout 2>$stderr
        tc_break_if_bad $? "netcf is not installed properly"
}

################################################################################
# Testcase functions
################################################################################
function run_test()
{
	tc_get_iface
	tc_register "Top Level network interfaces with MAC address"
	Mac=`ip link show $TC_IFACE | awk '/ether/ {print $2}'`
	ncftool list --macs | grep -Eq "$Mac" 
	tc_pass_or_fail $? "Top Level network interfaces with MAC address"

	tc_register "show all (up & down) interfaces"
	ncftool list --all | grep -Eq "$TC_IFACE" 
	tc_pass_or_fail $? "show all (up & down) interfaces."

	ipaddr=`ifconfig $TC_IFACE | awk '/inet / {print $2}'`
	tc_register "Dump the XML description of an interface "
	ncftool dumpxml $TC_IFACE | grep -Eq "$ipaddr"
	tc_pass_or_fail $? "Dump the XML description of interface"
	
	#get the configuration of the loopback device.
	ncftool dumpxml lo > test_lo.xml || return
	
	tc_register "Remove the configuration of the interface.."
	ncftool undefine lo  | grep -Eq "lo undefined" 
	tc_pass_or_fail $? "Remove the configuration of the interface."

	tc_register "Define an interface from XML file."
	ncftool define test_lo.xml | grep -Eq "Defined interface lo"
	tc_pass_or_fail $? "Define an interface from XML file."
	
	tc_register "Bring up interface."
	ncftool ifup lo 1>$stdout 2>$stderr
	RC=$?
	tc_ignore_warnings "Interface lo successfully brought up"
	tc_pass_or_fail $RC "Bring up interface.."

	tc_register "Bring down specified interface."
	ncftool ifdown lo  1>$stdout 2>$stderr
	RC=$?
	tc_ignore_warnings "Interface lo successfully brought down"
	tc_pass_or_fail $RC "Bring down specified interface."

}

function tc_local_cleanup()
{
	rm -rf test_lo.xml >$stdout 2>$stderr
	tc_break_if_bad $? "faled to delete loopback dump xml"	
	ncftool ifup lo  >$stdout 2>$stderr
	RC=$?
	tc_ignore_warnings "Interface lo successfully brought up"
	tc_break_if_bad $RC "netcf is failed to brought up loop back"
}
###############################################################################
#main
################################################################################
TST_TOTAL=7
tc_setup
run_test
