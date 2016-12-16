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
## File :	libmng.sh
##
## Description:	test of libmng package
##
## Author:	CSDL
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libmng
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/libmng

# global variables
REQUIRED="rm"

# Optional command line arguments
[ "$1" ] && ReadFile=$1   || ReadFile="read.mng"
[ "$2" ] && CreateFile=$2 || CreateFile="create.mng"

################################################################################
# utility functions
################################################################################

#
# Setup specific to this test
#
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return

	# check files
	[ -e $TESTDIR/$ReadFile ]
	tc_break_if_bad $? "$ReadFile doen't exist" || return
}

#
# Cleanup specific to this program
#
function tc_local_cleanup()
{
	# have nothing to do
	return 0
}

#
# usage, print usage information
#
function test_usage()
{
	local tab=$'\t'
	cat <<-EOF
		usage:
		${tab}$0 --help
		${tab}$0 [ readfile createfile ]
		${tab}If <readfile> is not specified, read.mng is the default.
		${tab}If <createfile> is not specified, create.mng is the default.
		exapmle:
		${tab}$0 read.mng create.mng
		<readfile> must be exist already
	EOF
	exit 1
}

################################################################################
# testcase functions
################################################################################

#
# mngread, test libmng read
#
function test_mngread()
{
	tc_register	"mng read"
	./mngtest "read" "$ReadFile"
	tc_pass_or_fail $? "read $ReadFile failed"
}

#
# mngcreate, test libmng create and write
#
function test_mngcreate()
{
	tc_register "mng create"
	./mngtest "create" "$TCTMP/$CreateFile" >$stdout 2>$stderr
	tc_pass_or_fail $? "create $TCTMP/$CreateFile failed"
}

################################################################################
# MAIN
################################################################################

[ "$1" = "--help" ] && test_usage

TST_TOTAL=2
(
tc_setup
cd $TESTDIR
test_mngread &&
test_mngcreate
)
