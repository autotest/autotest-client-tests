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
## File :	cmp.sh
##
## Description:	This testcase checks a collection of the following
##
## Author:	Shoji Sugiyama (shoji@jp.ibm.com)
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# any utility functions specific to this file can go here
################################################################################

################################################################################
# the testcase functions
################################################################################

#
# test01	cmp -c
#
function test01()
{
	#
	# Register test case
	#
	tc_register "\"cmp -c\" check -c option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test files
	#
	echo -e "\x01\x02\x03\x04\x05\x06\x07\x08\x09" > $TCTMP/file1
	echo -e "\x01\x02\x03\x14\x05\x06\x17\x08\x09" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	cmp -c $TCTMP/file1 $TCTMP/file2 > $TCTMP/file3
	grep "differ:" $TCTMP/file3 | grep "4, line 1 is   4 \^D  24 \^T" $TCTMP/file3 > /dev/null
	tc_pass_or_fail $? "[cmp -c] failed with mixed case characters"
}

#
# test02	cmp -i
#
function test02()
{
	#
	# Register test case
	#
	tc_register "\"cmp -i\" check -i option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test files
	#
	echo -e "\x01\x02\x03\x04\x05\x06\x07\x08\x09" > $TCTMP/file1
	echo -e "\x01\x02\x03\x14\x05\x06\x17\x08\x09" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	cmp -i 7 $TCTMP/file1 $TCTMP/file2 > /dev/null
	tc_pass_or_fail $? "[cmp -i] unexpected result"
}

#
# test03	cmp -l
#
function test03()
{
	#
	# Register test case
	#
	tc_register "\"cmp -l\" check -l option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test files
	#
	echo -e "\x01\x02\x03\x04\x05\x06\x07\x08\x09" > $TCTMP/file1
	echo -e "\x01\x02\x03\x14\x05\x06\x17\x08\x09" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	cmp -l $TCTMP/file1 $TCTMP/file2 > $TCTMP/file3
	num=`cat $TCTMP/file3 | wc -l`
	[ $num = 2 ]
	tc_pass_or_fail $? "[cmp -l] unexpected result with muliple differing bytes"
}


#
# test04	cmp -s
#
function test04()
{
	#
	# Register test case
	#
	tc_register "\"cmp -l\" check -l option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test files
	#
	echo -e "\x01\x02\x03\x04\x05\x06\x07\x08\x09" > $TCTMP/file1
	echo -e "\x01\x02\x03\x14\x05\x06\x17\x08\x09" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	cmp -s $TCTMP/file1 $TCTMP/file2 > $TCTMP/file3
	[ $? != 0 ]
	tc_fail_if_bad $? "[cmp -s] unexpected result with no differing bytes" || return
	num=`cat $TCTMP/file3 | wc -c`
	[ $num = 0 ]
	tc_pass_or_fail $? "[cmp -s] failed with unexpected output"
}

################################################################################
# main
################################################################################

TST_TOTAL=4

# standard setup
tc_setup

# tc_add_user_or_break    # in addition to standard setup, create a temporary user

test01
test02
test03
test04

# If you want a sequence of tests to each be dependent on the previous one
# having succeeded, chain them together with "&&" as follows ...
#
# test01 && \
# test02 && \
# test03 && \
# test04
