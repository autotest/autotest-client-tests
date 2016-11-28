#!/bin/sh
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
## File :	zlib.sh
##
## Description:	Test for availability and basic functionality of zlib
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/zlib_test
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/zlib_test/tests"


################################################################################
# the testcase functions
################################################################################

function runtest()
{
	pushd $TESTS_DIR &>/dev/null
	TESTS=`ls example*`
	TST_TOTAL=`echo $TESTS | wc -w`
	for test in $TESTS; do
		rm -rf foo.gz
		tc_register "zlib test for $test"
		case $test in 
		example)
			./example >$stdout 2>$stderr
			./minigzip -d foo.gz >$stdout 2>$stderr
			;;
		examplesh)
			./examplesh >$stdout 2>$stderr
			./minigzipsh -d foo.gz >$stdout 2>$stderr
			;;
		example64)
			./example64 >$stdout 2>$stderr
			./minigzip64 -d foo.gz >$stdout 2>$stderr
			;;
		esac
		tc_pass_or_fail $? "zlib test for $test failed"
	done
	popd &>/dev/null
}

################################################################################
# main
################################################################################

tc_setup
runtest
