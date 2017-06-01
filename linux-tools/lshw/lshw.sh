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
## File :        lshw.sh
##
## Description:  This Testcase tests lshw package
##
## Author:       Ramya BS  <ramyabs1@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/lshw
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/lshw
# environment functions
################################################################################
#
# local setup
#
function tc_local_setup()
{
      tc_check_package lshw
	tc_break_if_bad $? "lshw package is not installed properly"
	tc_get_iface
}
function tc_local_cleanup()
{
	 rm -f hardware_info.xml
}

################################################################################
function run_test()
{	
	#lshw without any options would generate full information report about all detected hardware.
	tc_register "lshw"
	lshw | grep -Eq `hostname`
	tc_pass_or_fail $? "lshw "
	
	#With the "-short" the lshw command would generate a brief information report about the hardware devices
	tc_register "lshw -short"
	lshw -short |grep -Eq 'H/W path|Device|Class|Description'
	tc_pass_or_fail $? "lshw -short"
	
	#To display information about any particular hardware, specify the class. 
	tc_register "lshw -class memory"
	lshw -short -class memory 1>$stdout 2>$stderr
	tc_pass_or_fail $? "lshw -class memory"

	#To display information about any particular hardware, specify the class. 
	tc_register "lshw -class cpu"
	lshw -short -class cpu 1>$stdout 2>$stderr 
	tc_pass_or_fail $? "lshw -class cpu"

	tc_register "lshw Mac address verification"
	mac=`ip link show $TC_IFACE | awk '/ether/ {print $2}'`
	lshw -xml | grep -Eq "$mac" 
	tc_pass_or_fail $? "Top Level network interfaces with MAC address"	
	
	tc_register "lshw -class network"
	lshw -class network  | grep -Eq "$TC_IFACE"
	tc_pass_or_fail $? "lshw -class network"

	tc_register "Generate Reports in xml"
	lshw -xml > hardware_info.xml
	tc_pass_or_fail $? "Generate Reports in xml"

	tc_register "Cpu bus verification for $TC_IFACE"
	lshw -businfo | awk '/processor/ {print $1}' | grep -Eq "cpu@0"
	tc_pass_or_fail $? "Display cpu bus information."

	tc_register "lshw -short -disable network"
	lshw -short -disable network | grep -Eq "$TC_IFACE"
	if [ $? -eq 0 ]; then
		tc_fail "lshw -short -disable network"
	else
		tc_pass "lshw -short -disable network"
	fi

	tc_register "lshw -short -enable network"
	lshw -short -enable network | grep -Eq "$TC_IFACE"
	if [ $? -eq 0 ]; then
		tc_pass "lshw -short -enable network"
	else
		tc_fail "lshw -short -enable network"
	fi 

	 
}

##########################################################################################
#main
##########################################################################################
tc_setup 
run_test 
