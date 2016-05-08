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
## Description:	This script invokes a series of diffutils test scripts
##
## Author:	Shoji Sugiyama (shoji@jp.ibm.com)
###########################################################################################
## source the utility functions
TESTDIR=${LTPBIN%%shared}/diffutils

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
tc_setup
tc_register	"diffutils"
tc_info "diffutils test consists of cmp.sh, diff.sh, diff3.sh, and sdiff.sh"

#
# Run test
#
function runtest()
{
	#
	# Check if target package has been installed.
	#
	tc_exec_or_break cmp diff diff3 sdiff || return

	#
	# Execute a series of test cases
	#
	rc=0;
	# for file in `ls *.sh | grep -v diffutils.sh`
	for file in cmp.sh diff.sh diff3.sh sdiff.sh
	do
	#	echo $file
		eval $TESTDIR/$file || rc=$?
	done

	tc_pass_or_fail $rc "one of the above failed"
}

#
# Test main.
#
runtest
