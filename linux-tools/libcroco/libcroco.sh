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
### File : libcroco.sh                                                         ##
##
### Description: This testcase tests the libcroco package                      ##
##
### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libcroco
source $LTPBIN/tc_utils.source
LIBCROCO_TESTS_DIR="${LTPBIN%/shared}/libcroco/tests"

function tc_local_setup()
{
	##Installation check ##
	tc_check_package "libcroco"
	tc_break_if_bad $? "libcroco not installed properly"
}

function run_test()
{
	pushd $LIBCROCO_TESTS_DIR  >$stdout 2>$stderr
	tc_register "Read file byte by byte"
        ./test0 test0.1.css >$stdout 2>$stderr
	tc_pass_or_fail $? "Reading byte by byte failed"

	tc_register "Read file character by character"
	./test1 test1.css >$stdout 2>$stderr
	tc_pass_or_fail $? "Reading file by character failed"

	# Some of the below testcases test with more than 1 different files.
	# both the files are .css files but of different
	# css styles and contents
	tc_register "Test the cr_parser_parse method: file1"
	./test2 test2.1.css >$stdout 2>$stderr
	tc_pass_or_fail $? "cr_parser_parse for file1 failed"

	tc_register "Test the cr_parser_parse method: file2"
	./test2 test2.2.css >$stdout 2>$stderr
	tc_pass_or_fail $? "cr_parser_parse for file2 failed"

	tc_register "Test CROMParser class: file1"
	./test3 test3.css >$stdout 2>$stderr
	tc_pass_or_fail $? "CROMparser for file1 failed"

	tc_register "Test CROMParser class: file2"
	./test3 test3.1.css >$stdout 2>$stderr
	tc_pass_or_fail $? "CROMparser for file2 failed"

	tc_register "Test CROMParser class: file3"
	./test3 test3.2.css >$stdout 2>$stderr
	tc_pass_or_fail $? "CROMparser for file3 failed"

	# The 2 tests below has many sub-routines 
	# cr_parser, cr_statement, cr_term_parse, cr_declaration 
	# and many others
	tc_register "Test some sub-routines: file1"
	./test4 test4.1.css >$stdout 2>$stderr
	tc_pass_or_fail $? "Test for file1 failed"

	tc_register "Test some sub-routines: file2"
	./test4 test4.2.css >$stdout 2>$stderr
	tc_pass_or_fail $? "Test for file2 failed"

	tc_register "Test the selection Engine"
	./test5 test5.1.css >$stdout 2>$stderr
	tc_pass_or_fail $? "Test for selection engine failed"

	tc_register "Test the cr_input_read_byte method"
	./test6 >$stdout 2>$stderr
	tc_pass_or_fail $? "Test cr_input_read_byte failed"

	popd >$stdout 2>$stderr
}

#
#main
#
TST_TOTAL=11
tc_setup && run_test 
