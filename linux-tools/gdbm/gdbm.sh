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
## File :	gdbm.sh
##
## Description:	test gdbm
##
## Author:	Robb Romans <robb@austin.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/gdbm
source $LTPBIN/tc_utils.source
TEST_PATH=${LTPBIN%/shared}/gdbm
################################################################################
# any utility functions specific to this file can go here
################################################################################

function tc_local_cleanup()
{
        rm -f junk.gdbm
}

################################################################################
# the testcase functions
################################################################################

function test01()
{
	tc_register "access gdbm"
	
	tc_exec_or_break grep || return
	
	cat > $TCTMP/gdbm_data <<-EOF
		s
		001
		welovetest
		f
		001
		quit
	EOF
	
	$TEST_PATH/testgdbm < $TCTMP/gdbm_data >$stdout 2>$stderr
	tc_break_if_bad $? "unexpected response" || return
	
	expected="com -> key -> data is ->welovetest"
	grep -q "$expected" $stdout 2>$stderr
	tc_pass_or_fail $? "Expected to see the following in stdout" \
		"==============================" \
		"$expected" \
		"=============================="
}

################################################################################
# main
################################################################################

TST_TOTAL=1

tc_setup
test01
