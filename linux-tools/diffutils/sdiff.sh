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
## File :	sdiff.sh
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
# test01	sdiff -i
#
function test01()
{
	#
	# Register test case
	#
	tc_register "\"sdiff -i\" check -i option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo || return
	
	#
	# Prepare test files
	#
	echo "abcd" > $TCTMP/file1
	echo "aBcD" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	sdiff -i $TCTMP/file1 $TCTMP/file2 > /dev/null
	tc_pass_or_fail $? "[sdiff -i] failed with mixed case characters"
}

#
# test02	sdiff -W
#
function test02()
{
	#
	# Register test case
	#
	tc_register "\"sdiff -W\" check -W option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test files
	#
	echo -e "abcd" > $TCTMP/file1
	echo -e " a b c   d   " > $TCTMP/file2
	
	#
	# Execute and check result
	#
	sdiff -W $TCTMP/file1 $TCTMP/file2 > /dev/null
	tc_pass_or_fail $? "[sdiff -W] failed with white space characters"
}

#
# test03	sdiff -b
#
function test03()
{
	#
	# Register test case
	#
	tc_register "\"sdiff -b\" check -b option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo || return

	#
	# Prepare test files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11 \n22\n33  \n44\n55  \n66\n77\n88 \n99" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	sdiff -b $TCTMP/file1 $TCTMP/file2 > /dev/null
	tc_pass_or_fail $? "[sdiff -b] failed to ignore changes in the amount of white space"
}

#
# test04	sdiff -B
#
function test04()
{
	#
	# Register test case
	#
	tc_register "\"sdiff -B\" check -B option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo || return
	
	#
	# Prepare test and expected result files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11\n22\n\n33\n44\n\n55\n66\n77\n\n88\n99" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	sdiff -B $TCTMP/file1 $TCTMP/file2 > /dev/null
	tc_pass_or_fail $? "[sdiff -B] failed with blank lines"
}

#
# test05	diff -w
#
function test05()
{
	#
	# Register test case
	#
	tc_register "\"sdiff -w\" check -w option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo || return
	
	#
	# Prepare test and expected result files
	#
	echo -e "1234567890" > $TCTMP/file1
	echo -e "12345x67890y" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	sdiff -w 27 $TCTMP/file1 $TCTMP/file2 | grep -v y > /dev/null
	tc_fail_if_bad $? "[sdiff -w] #1 failed with specified num chars per line" || return
	
	sdiff -w 21 $TCTMP/file1 $TCTMP/file2 | grep -v x > /dev/null
	tc_pass_or_fail $? "[sdiff -w] #2 failed with specified num chars per line"
}

#
# test06	sdiff -l
#
function test06()
{
	#
	# Register test case
	#
	tc_register "\"sdiff -l\" check -l option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep wc || return
	
	#
	# Prepare test and expected result files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11\n22x\n33\n44\n55\n66x\n77\n88\n99" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	sdiff -l $TCTMP/file1 $TCTMP/file2 > $TCTMP/file3
	num=`grep "(" $TCTMP/file3 | wc -l`
	if [ $num -ne 8 ]; then
		# fail
		tc_pass_or_fail 1 "[sdiff -l] #1 : failed with unxpected result"
	else
		# success
		tc_pass_or_fail 0 "[sdiff -l] #1 : failed with unxpected result"
	fi	
}

#
# test07	sdiff -s
#
function test07()
{
	#
	# Register test case
	#
	tc_register "\"sdiff -s\" check -s option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test and expected result files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11\n22x\n33\n44\n55\n66x\n77\n88x\n99" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	sdiff -s $TCTMP/file1 $TCTMP/file2 > $TCTMP/file3
	num=`cat $TCTMP/file3 | wc -l`
	if [ $num -ne 3 ]; then
		# fail
		tc_pass_or_fail 1 "[sdiff -s] #1 : failed with suppress common line option"
	else
		# success
		tc_pass_or_fail 0 "[sdiff -s] #1 : failed with suppress common line option"
	fi	
}

#
# test07	sdiff -t
#
function test08()
{
	#
	# Register test case
	#
	tc_register "\"sdiff -t\" check -t option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test and expected result files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11\n22x\n33\n44\n55\n66x\n77\n88x\n99" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	sdiff -t $TCTMP/file1 $TCTMP/file2 > $TCTMP/file3
	grep -v "	" $TCTMP/file3 > /dev/null
	tc_pass_or_fail $? "[sdiff -t] failed with expand tab option"
}

################################################################################
# main
################################################################################

TST_TOTAL=8

# standard setup
tc_setup

# tc_add_user_or_break    # in addition to standard setup, create a temporary user

test01
test02
test03
test04
test05
test06
test07
test08

# If you want a sequence of tests to each be dependent on the previous one
# having succeeded, chain them together with "&&" as follows ...
#
# test01 && \
# test02 && \
# test03 && \
# test04
