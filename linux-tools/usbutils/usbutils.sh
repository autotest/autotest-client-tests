#!/bin/sh
############################################################################################
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
## File :        usbutils.sh
##
## Description:  This testcase tests the usbutils package.
##
## Author:       liudeyan@cn.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/usbutils
source $LTPBIN/tc_utils.source

tc_get_os_arch
if [ "$TC_OS_ARCH" = "s390x" ];
then
	tc_info " ** USB Devices are not present in s390x arch & usbfs in no more supported from kernel-3.5 onwards, Hence this test is not valid for s390x arch ** "
	exit 0
fi

function test00()
{
	tc_register "lsusb test"

	lsusb &>$stdout
	tc_pass_or_fail $? "lsusb test failed."
}

function test01()
{
	tc_register "lsusb -v"
	
	lsusb -v &>$stdout
	tc_pass_or_fail $? "lsusb -v test failed."

}

function test02()
{
	tc_register "lsusb -t"
	
	lsusb -t &>$stdout
	tc_pass_or_fail $? "lsusb -t test failed."

}


TST_TOTAL=3
tc_setup

test00 &&
test01 &&
test02 
