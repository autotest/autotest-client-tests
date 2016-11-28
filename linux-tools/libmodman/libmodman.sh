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
### File : libmodman							      ##
##
### Description: test script to test libmodman package                  	      ##
##
### Author:      Ravindran Arani <ravi@linux.vnet.ibm.com>                     ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libmodman
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/libmodman/"

function tc_local_setup()
{
	rpm -q libmodman >$stdout 2>$stderr
	tc_break_if_bad $? "libmodman is not installed"
}

function runtests()
{
	pushd $TESTDIR/test >$stdout 2>$stderr
	TST_TOTAL=7
	tc_register "Test condition"
	./condition "modules/condition" "two" >$stdout 2>$stderr
	tc_pass_or_fail $? "Test condition failed"
	tc_register "Test singleton"
	./singleton "modules/singleton" "one" >$stdout 2>$stderr
	tc_pass_or_fail $? "Test singleton failed"
	tc_register "Test sorted"
	./sorted "modules/sorted" "two" "one" >$stdout 2>$stderr
	tc_pass_or_fail $? "Test sorted failed"
	tc_register "Test symbollnk"
	./symbollnk "modules/symbol" "two" >$stdout 2>$stderr
	tc_pass_or_fail $? "Test symbollnk failed"
	tc_register "Test symbol"
	./symbol "modules/symbol" >$stdout 2>$stderr
	tc_pass_or_fail $? "Test symbol failed"
	tc_register "Test symbol one"
	./symbol "modules/symbol" "one" >$stdout 2>$stderr
	tc_pass_or_fail $? "Test symbol one failed"
	tc_register "Test builtin"
	./builtin >$stdout 2>$stderr
	tc_pass_or_fail $? "Test builtin failed"
	popd >$stdout 2>$stderr
}
#
#MAIN
#
tc_setup
runtests
