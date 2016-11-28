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
## File :	libedit_test.sh
##
## Description:	Test basic functionality of libeditline library
##
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libedit
## source the utility functions
source $LTPBIN/tc_utils.source
MYDIR=${LTPBIN%/shared}/libedit

################################################################################
# helper function
################################################################################
function tc_local_setup()
{       
	tc_exec_or_break expect || return

        # tc_info "LD_LIBRARY_PATH .."
	# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/tmp/libeditline-<date>/src

}

function test01()
{
	tc_register "basic function via expect"

	local expcmd=`which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/test 
		expect {
			timeout abort
			"Edit$ " { send "pwd\r" }
		}
		expect {
			timeout abort
			"Edit$ " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$stdout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	MyPWD=`pwd`
	grep -q ${MyPWD} $stdout
	tc_pass_or_fail $? "unexpected script output" 

}

function test02()
{
	tc_register "test history save" 

	local expcmd=`which expect`
	history_file="foo_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890"
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/test 
		expect {
			timeout abort
			"Edit$ " { send "pwd\r" }
		}
		expect {
			timeout abort
			"Edit$ " { send "date\r" }
		}
		expect {
			timeout abort
			"Edit$ " { send "history\r" }
		}
		expect {
			timeout abort
			"Edit$ " { send "history save $TCTMP/$history_file\r" }
		}
		expect {
			timeout abort
			"Edit$ " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$stdout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return
	[ -e $TCTMP/$history_file ] && grep -q pwd $TCTMP/$history_file && grep -q date $TCTMP/$history_file && \
		grep -q pwd $stdout && grep -q date $stdout
	tc_pass_or_fail $? "unexpected script output" 
}

function test03()
{
	tc_register "test history load" 

	local expcmd=`which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/test 
		expect {
			timeout abort
			"Edit$ " { send "history load $TCTMP/$history_file\r" }
		}
		expect {
			timeout abort
			"Edit$ " { send "history\r" }
		}
		expect {
			timeout abort
			"Edit$ " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$stdout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	grep -q pwd $stdout && grep -q date $stdout
	tc_pass_or_fail $? "unexpected script output" 
}

function test04()
{
	tc_info "Refer to 00_Description.txt for manual tests with test:"
	tc_info "	1. vi mode command line edit"
	tc_info "	2. command line completion"
}

################################################################################
# main
################################################################################

tc_setup			# standard setup

test01
test02
test03
test04
