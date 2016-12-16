#!/bin/bash
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
## File:           file.sh
##
## Description: This program tests the file command. The tests are aimed at
##
## Author:      Robert Paulsen. Based on ideas by Manoj Iyer
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/file
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/file"

################################################################################
# global variables
################################################################################

REQUIRED="grep"
ME=$0

################################################################################
# utility functions specific to this script
################################################################################

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED
}

#
# tc_local_cleanup
#
function tc_local_cleanup()
{
	true	# nothing here yet!
}

################################################################################
# the test functions
################################################################################

#
# test01	check that file is installed
#
function test01()
{
	tc_register	"installation check"
	tc_executes file
	tc_pass_or_fail $? "file not installed"
}

#
# test02	ASCII text
#
function test02()
{
	local expected="ASCII text"
	tc_register	"$expected"
	cat > $TCTMP/testfile02.xyz <<-EOF
		The time has come, the Walrus said, to talk of many things
		Of shoes and ships and sealing wax, of cabbages and kings,
		Of why the sea is boiling hot and whether pigs have wings.
	EOF
	file $TCTMP/testfile02.xyz >$stdout 2>$stderr
	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in output"
}

#
# test03	bash shell script
#
function test03()
{
	local expected="Bourne-Again shell script"
	tc_register	"$expected"
	cat > $TCTMP/testfile03.xyz <<-EOF
		#!/bin/bash
		echo "Hello, Sailor!"
	EOF
	file $TCTMP/testfile03.xyz >$stdout 2>$stderr
	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in output"
}

#
# test04	korn shell script
#
function test04()
{
	local expected="Korn shell script"
	tc_register	"$expected"
	cat > $TCTMP/testfile04.xyz <<-EOF
		#!/bin/ksh
		echo "Hello, Sailor!"
	EOF
	file $TCTMP/testfile04.xyz >$stdout 2>$stderr
	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in output"
}

#
# test05	C shell script
#
function test05()
{
	local expected="C shell script"
	tc_register	"$expected"
	cat > $TCTMP/testfile05.xyz <<-EOF
		#!/bin/csh
		echo "Hello, Sailor!"
	EOF
	file $TCTMP/testfile05.xyz >$stdout 2>$stderr
	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in output"
}

#
# test06	ASCII C program text
#
function test06()
{
	local expected="C source, ASCII text"
	tc_register	"$expected"
	cat > $TCTMP/testfile06.xyz <<-EOF
		#include <stdio.h>
		int main()
		{
			printf("Hello, Sailor!");
			return 0;
		}
	EOF
	file $TCTMP/testfile06.xyz >$stdout 2>$stderr
	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in output"
}

#
# test07	ELF executable
#
function test07()
{
	tc_register	"ELF Executable"
	file $TEST_DIR/file-test-cprog >$stdout 2>$stderr
	grep -q "ELF .*executable" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"ELF ... executable\" in output"
}

#
# test08	tar file
#
function test08()
{
	local expected="POSIX tar archive"
	tc_register	"$expected"
	file $TEST_DIR/file-tests.tar >$stdout 2>$stderr
	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in output"
}

#
# test09	tar gzip file
#
function test09()
{
	local expected="POSIX tar archive"
	tc_register	"gzipped $expected"
	file $TEST_DIR/file-tests.tgz >$stdout 2>$stderr
	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in output"
}

#
# test10	gziped file
#
function test10()
{
	local expected="gzip compressed data"
	tc_register	"gzipped $expected"
	file $TEST_DIR/file-test.xxx.gz >$stdout 2>$stderr
	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in output"
}

################################################################################
# main
################################################################################

TST_TOTAL=10	# there are three tests in this testcase

tc_setup	# standard setup

test01 || exit
test02
test03
test04 
test05 
test06 
test07 
test08 
test09 
test10
