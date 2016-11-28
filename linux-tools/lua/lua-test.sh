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
### File :       lua-test.sh                                                   ##
##
### Description: This testcase tests lua package                               ##
##
### Author:      Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                      ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/lua
source $LTPBIN/tc_utils.source
LUA_TESTS_DIR="${LTPBIN%/shared}/lua/test"

required="lua luac"

function tc_local_setup()
{
	# check installation and environment 
	tc_exec_or_break $required || return 
	# Create a test file
	cat <<-EOF > $TCTMP/lua_test_file
		kings 12345
		KINGS   123
	EOF
}

function run_test()
{
	pushd $LUA_TESTS_DIR &>/dev/null 
	TESTS="*.lua"
	for testfile in $TESTS; do
		case "$testfile" in
		
		"globals.lua")
		
			tc_register "testing globals.lua"
			luac -p -l globals.lua | lua globals.lua >$stdout 2>$stderr
			tc_pass_or_fail $? "test globals.lua failed"		   
			;;
	
		"luac.lua")

			tc_register "testing luac.lua"
			lua luac.lua hello.lua >$stdout 2>$stderr
			tc_pass_or_fail $? "test luac.lua failed"
			;;

		"table.lua")

			tc_register "testing table.lua"
			lua table.lua < $TCTMP/lua_test_file >$stdout 2>$stderr
			tc_pass_or_fail $? "test table.lua failed"
			;;
		

		"xd.lua")
		
			tc_register "testing xd.lua"
			lua xd.lua < $TCTMP/lua_test_file >$stdout 2>$stderr
			tc_pass_or_fail $? "test xd.lua failed"
			;;

		"readonly.lua")
	
			tc_register "testing readonly.lua"
			lua readonly.lua >$stdout 2>$stderr
			[ $? -eq 1 ] && { 
				cmp $stderr $LUA_TESTS_DIR/../readonly.lua_stderr.exp
				[ $? -eq 0 ] && cp /dev/null $stderr
			}
			tc_pass_or_fail $? "test readonly.lua failed"
			;;
		*)
	        
			tc_register "testing $testfile"
			lua $testfile >$stdout 2>$stderr
			tc_pass_or_fail $? "test $testfile failed"
			;;

		esac		
	done
	popd &>/dev/null
}

#
# main
#
tc_setup
TST_TOTAL=`ls $LUA_TESTS_DIR/*.lua | wc -w`
run_test
