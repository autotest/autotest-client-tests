#!/bin/bash
# vi: ts=8 sw=8 noexpandtab :
###########################################################################################
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
# File :        hostname.sh
#
# Description:  This Testcase tests hostname package
#
# Author:       Basavaraju.G <basavarg@in.ibm.com>
#
# History:      oct 19 2015 - Initial Version
############################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/hostname
source $LTPBIN/tc_utils.source

TESTDIR=${LTPBIN%/shared}/hostname
# environment functions
################################################################################
#
# local setup
#
function tc_local_setup()
{
        rpm -q hostname >$stdout 2>$stderr
        tc_break_if_bad $? "hostname is not installed properly"
	tc_get_iface
}

################################################################################
# Testcase functions
################################################################################
function run_test()
{
	tc_info "Top Level network interfaces with ipaddress"
	ipaddress=`ip addr show dev $TC_IFACE | grep 'inet ' | awk '{ print $2}' | cut -d'/' -f 1`
	tc_register "Get hostname of the system"
	hostname 1>$stdout 2>$stderr
	tc_pass_or_fail $? "failed to get hostname of the system"

	tc_register "Get domain name of the system"
	dnsdomainname 1>$stdout 2>$stderr
	tc_pass_or_fail $? "failed to get Domain name of the system"

	tc_register "Get FQDN (Fully Qualified Domain Name) of the system."
	hostname  --fqdn --long 1>$stdout 2>$stderr
	tc_pass_or_fail $? "failed to get FQDN"

	#save hostname for restore back after the test.
	hostname_save=`hostname`
	pushd $TESTDIR >$stdout 2>$stderr
	tc_register "set hostname by using separate file"
	hostname -F domain_name.txt 1>$stdout 2>$stderr	
	tc_pass_or_fail $? "failed to set hostname."
	popd >$stdout 2>$stderr

	tc_register "verification of hostname"
	hostname | grep -Eq "testdomainname" 1>$stdout 2>$stderr
	tc_pass_or_fail $? "verification of  hostname failed."
	
	tc_register "restore hostname $hostname_save"
	hostname "$hostname_save"
	tc_pass_or_fail $? "failed to restore hostname"	
	
	tc_register "Display all network address of the host"
	hostname --all-ip-addresses | grep -Eq "$ipaddress" 1>$stdout 2>$stderr
	tc_pass_or_fail $? "failed to display network address."
	
	#save domain name for restore after the test
	domainname_save=`domainname`

	tc_register "set domain name."
	domainname localdomain  1>$stdout 2>$stderr
	tc_pass_or_fail $? "failed to set nisdomain."
	
	tc_register "verifying domainnanme"
	domainname | grep -Eq "localdomain" 1>$stdout 2>$stderr
	tc_pass_or_fail $? "domainname verification failed."

	tc_register "restore domainname back to original"
	domainname "$domainname_save"  
	tc_pass_or_fail $? "failed to restore nisdomainname"
	
	#save nisdomain name for restore after the test
	nisdomainname_save=`nisdomainname`

	tc_register "set nisdomain."
	nisdomainname localdomain  1>$stdout 2>$stderr
	tc_pass_or_fail $? "failed to set nisdomain."

	tc_register "verifying nisdomainnanme"
	nisdomainname | grep -Eq "localdomain" 1>$stdout 2>$stderr
	tc_pass_or_fail $? "nisdomainname verification failed."

	tc_register "restore nisdomain back to original"
	nisdomainname "$nisdomainname_save"  
	tc_pass_or_fail $? "failed to restore nisdomainname"

	#save ypdomain name for restore after the test
	ypdomainname_save=`ypdomainname`

	tc_register "set ypdomain."
	ypdomainname localdomain  1>$stdout 2>$stderr
	tc_pass_or_fail $? "failed to set nisdomain."

	tc_register "verifying ypdomainnanme"
	ypdomainname | grep -Eq "localdomain" 1>$stdout 2>$stderr
	tc_pass_or_fail $? "ypdomainname verification failed."

	tc_register "restore ypdomain back to original"
	ypdomainname "$ypdomainname_save"
	tc_pass_or_fail $? "failed to restore ypdomainname"

}

###############################################################################
#main
################################################################################
TST_TOTAL=16
tc_setup
run_test
