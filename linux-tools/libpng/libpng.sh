#!/bin/bash
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##2.Redistributions in binary form must reproduce the above copyright notice, this  ##
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
# File :	testpng.sh
#
# Description:	Test libpng package
#
# Author:	Robb Romans <robb@austin.ibm.com>
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libpng
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/libpng
cd $TESTDIR
################################################################################
# testcase functions
################################################################################

# Function:		test01
#
# Description:		- run pngtest
#
# Parameters:		- none
#
# Return		- zero on success
#			- return value from commands on failure
#
function test01() {

	# housekeeping
	tc_register "pngtest"
	tst="$TESTDIR/pngtest"

	# make sure test file exists
	[ -f $tst ]
	tc_break_if_bad $? "The test '$tst' does not exist." || return

	# runit
	$tst >/dev/null 2>$stderr

	# results
	tc_pass_or_fail $? "$tst output unexpected."
}


####################################################################################
# MAIN
####################################################################################

# Function:	main
#
# Description:	- Execute all tests, report results
#
# Exit:		- zero on success
#		- non-zero on failure
#

TST_TOTAL=1
tc_setup
test01

