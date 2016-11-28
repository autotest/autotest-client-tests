#!/bin/bash
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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
# vi: set ts=8 sw=8 autoindent noexpandtab :
################################################################################
# File :        apache.sh
# Description:  Check that apache can serve up an HTML web page.#
# Author:       Xu Zheng ,zhengxu@cn.ibm.com
#
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libusb
source $LTPBIN/tc_utils.source
#/opt/fiv/fiv-ltp-20040506-1.0/testcases/bin/tc_utils.source

LIBUSBPATH=${LTPBIN%/shared}/libusb


################################################################################
# the testcase functions
################################################################################

#
# test01        check that libusb is installed
#
function test01()
{
	tc_register     "check that libusb is installed"
	ls /usr/lib*/libusb* >$stdout 2>$stderr
        tc_pass_or_fail $? "not installed"
}

#
# test02         test libusb
#
function test02()
{
        tc_register "libusb"

        $LIBUSBPATH/testcase/libusb >$stdout 2>$stderr
	
        tc_pass_or_fail $? " failed: now libusb cannot work well! " || return
}

################################################################################
# main
################################################################################

TST_TOTAL=2

tc_setup                        # standard setup

tc_root_or_break || exit

test01 &&
test02

