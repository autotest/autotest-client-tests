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
## File :	diff.sh
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
# test01	diff -b
#
function test01()
{
	#
	# Register test case
	#
	tc_register "\"diff -b\" check -b option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test files
	#
	echo "abcd" > $TCTMP/file1
	echo "abcd   " > $TCTMP/file2
	
	#
	# Execute and check result
	#
	diff -b $TCTMP/file1 $TCTMP/file2
	tc_pass_or_fail $? "[diff -b] failed with some white space at the end of line"
}

#
# test02	diff -c
#
function test02()
{
	#
	# Register test case
	#
	tc_register "\"diff -c\" check -c option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo grep || return
	
	#
	# Prepare test files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11\n22\n33\n44\n55x\n66\n77\n88\n99" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	diff -c $TCTMP/file1 $TCTMP/file2 > $TCTMP/file3
	rc=$?
	[ $rc != 0 ]
	tc_fail_if_bad $? "[diff -c] #1 unexpected result rc=$rc" || return
	grep " 3,9 " $TCTMP/file3 > /dev/null
	tc_fail_if_bad $? "[diff -c] #2 unexpected result" || return
	grep "! 55" $TCTMP/file3 > /dev/null
	tc_pass_or_fail $? "[diff -c] #3 unexpected result"
}

#
# test03	diff -e
#
function test03()
{
	#
	# Register test case
	#
	tc_register "\"diff -e\" check -e option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo cat || return
	
	#
	# Prepare test files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11\n22x\n33\n44\n55\n66\n77\n88x\n99" > $TCTMP/file2
	echo -e "9c\n88x\n.\n3c\n22x\n." > $TCTMP/file3
	
	#
	# Execute and check result
	#
	diff -e $TCTMP/file1 $TCTMP/file2 > $TCTMP/file4
	rc=$?
	[ $rc != 0 ]
	tc_fail_if_bad $? "[diff -e] #1 unexpected result" || return
	diff $TCTMP/file3 $TCTMP/file4 > /dev/null
	tc_pass_or_fail $? "[diff -e] #2 unxpected result with differences in restored file by using ed"
}

#
# test04	diff -f
#
function test04()
{
	#
	# Register test case
	#
	tc_register "\"diff -f\" check -f option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo cat || return
	
	#
	# Prepare test and expected result files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11\n22x\n33\n44\n55\n66\n77\n88x\n99" > $TCTMP/file2
	echo -e "c3\n22x\n.\nc9\n88x\n." > $TCTMP/file3
	
	#
	# Execute and check result
	#
	diff -f $TCTMP/file1 $TCTMP/file2 > $TCTMP/file4
	rc=$?
	[ $rc != 0 ]
	tc_fail_if_bad $? "[diff -f] #1 unexpected result" || return
	diff $TCTMP/file3 $TCTMP/file4 > /dev/null
	tc_pass_or_fail $? "[diff -f] #2 unexpected result"
}

#
# test05	diff -r
#
function test05()
{
	#
	# Register test case
	#
	tc_register "\"diff -f\" check -f option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo cat mkdir || return
	
	#
	# Prepare test and expected result files
	#
	mkdir -p $TCTMP/dir1/dirA
	mkdir -p $TCTMP/dir2/dirA
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/dir1/dirA/file1
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/dir2/dirA/file1
	
	#
	# Execute and check result
	#
	diff -r $TCTMP/dir1 $TCTMP/dir2 > /dev/null
	tc_fail_if_bad $? "[diff -r] #1 : failed with unexpected result" || return

	# Check if subdir name is di
	mkdir -p $TCTMP/dir1/dirB
	diff -r $TCTMP/dir1 $TCTMP/dir2 > /dev/null
	rc=$?
	[ $rc != 0 ]
	tc_pass_or_fail $? "[diff -r] #2 : failed with unexpected result"
}

#
# test06	diff -C
#
function test06()
{
	#
	# Register test case
	#
	tc_register "\"diff -C\" check -C option"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break echo cat mkdir || return
	
	#
	# Prepare test and expected result files
	#
	echo -e "00\n11\n22\n33\n44\n55\n66\n77\n88\n99" > $TCTMP/file1
	echo -e "00\n11\n22x\n33\n44\n55\n66x\n77\n88\n99" > $TCTMP/file2
	
	#
	# Execute and check result
	#
	diff -C 1 $TCTMP/file1 $TCTMP/file2 > $TCTMP/file3
	num=`grep -- "---"$ $TCTMP/file3 | wc -l`
	[ $num = 2 ]
	tc_pass_or_fail $? "[diff -C] #1 : failed with unxpected result"
}

################################################################################
# main
################################################################################

TST_TOTAL=6

# standard setup
tc_setup

# tc_add_user_or_break    # in addition to standard setup, create a temporary user

test01
test02
test03
test04
test05
test06

# If you want a sequence of tests to each be dependent on the previous one
# having succeeded, chain them together with "&&" as follows ...
#
# test01 && \
# test02 && \
# test03 && \
# test04
