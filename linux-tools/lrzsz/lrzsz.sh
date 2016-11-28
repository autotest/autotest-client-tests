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
### File :       lrzsz.sh                                                      ##
##
### Description: This testcase tests lrzsz package                             ##
##
### Author:      Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                      ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/lrzsz
source $LTPBIN/tc_utils.source
LRZSZ_TESTS=${LTPBIN%/shared}/lrzsz

required="runtest"

function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $required || return
	export srcdir="$LRZSZ_TESTS/testsuite"
}

function test_lrzsz()
{
	tc_register "lrzsz tests"
	pushd $srcdir &>/dev/null
	runtest --tool lrzsz --srcdir $srcdir &>$stdout
	tc_pass_or_fail $? "lrzsz tests failed"
	popd
}
#
# main
#
TST_TOTAL=1
tc_setup

test_lrzsz
