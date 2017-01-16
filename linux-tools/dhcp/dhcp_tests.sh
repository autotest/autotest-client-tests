#!/bin/bash
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##  1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this  ##
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
# File :    dhcp_tests.sh
#
# Description:  Wrapper script for community test scripts for dhcp package
#
# Author:   Madhura P S, madhura.ps@in.ibm.com
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
#REQUIRED_SCRIPTS="dhcp-server.sh dhcrelay_tests.sh"
cp $LTPBIN/../dhcp/dhcp-server.sh $LTPBIN/../dhcp/dhcrelay_tests.sh $LTPBIN

################################################################################
# the testcase functions
################################################################################

#
# dhcp daemon testing
#
function test01()
{
    tc_register "Test for dhcpd"
    $LTPBIN/dhcp-server.sh 2>/dev/null
	tc_pass_or_fail $? "dhcp-server failed"
}

#
# dhcp daemon testing in OMSHELL
#
function test02()
{
    tc_register "Test for OMSHELL"
	OMSHELL=yes $LTPBIN/dhcp-server.sh 2>/dev/null
    tc_pass_or_fail $? "OMSHELL for dhcp failed"
}

#
# dhcrelay related tests
#
function test03()
{
	tc_register "Test for dhcrelay"
    $LTPBIN/dhcrelay_tests.sh 2>/dev/null
    tc_pass_or_fail $? "dhcrelay test failed"
}


################################################################################
# main
################################################################################

# Total number of testcases in this file.
TST_TOTAL=3
tc_setup
test01
test02 
test03 
