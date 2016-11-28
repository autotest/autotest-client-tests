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
# File :	readline.sh
#
# Description:	Test basic functionality of GNU Readline library
#		The Readline library provides a set of functions for use by
#		applications that allow users to edit command lines as they
# 		are typed in.
#
#		test01 - test05:
#               we create an expect file to execute the commands in
#		"fileman". "Fileman" is a tiny application that
#		demonstrates how to use the GNU Readline library.
#		("Fileman.c" is an example program in /examples directory
#		of the readline distribution.)
#
#		test06:
#               we create an expect file to execute the commands in
#		"rltest". "Rltest" is a tiny application that
#		demonstrates how to use the GNU Readline library.
#		("Rltest.c" is an example program in /examples directory
#		of the readline distribution.)
#
# Author:	Yu-Pao Lee, yplee@us.ibm.com
# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/readline
MYDIR=${LTPBIN%/shared}/readline
source $LTPBIN/tc_utils.source

################################################################################
# helper function
################################################################################

#
# comp_results		All tests compare results the same way
#
function comp_results()
{
	# compare the results
	$DIFF $TCTMP/actout $TCTMP/expout >$stdout 2>$stderr
	tc_pass_or_fail $? "miscompare."$'\n' \
			"=============== expected ==============="$'\n'"`cat $TCTMP/expout`" \
			"================ actual ================"$'\n'"`cat $TCTMP/actout`" \
			"========================================"$'\n'
}

function tc_local_setup()
{
	DIFF_OPTS="-w -b -q"

	DIFF="diff ${DIFF_OPTS}"
	tc_executes diff || {
		DIFF=true
		tc_info "without diff, we rely only on commands' return codes"
	}
	# To avoid expect putting junk characters in the output
	export TERM=linux
}

################################################################################
# the testcase functions
################################################################################

function test01()	# test readline functionality   
{
	tc_register "test \"help list\""

	tc_exec_or_break expect cat chmod || return

	# create expect file to test commands in fileman
	local expcmd=`which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/fileman 
		expect {
			timeout abort
			"FileMan: " { send "help list\r" }
		}
		expect {
			timeout abort
			"FileMan: " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$TCTMP/actout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	# create the expected output
	cat > $TCTMP/expout <<-EOF
		FileMan: help list
		list            List files in DIR.
		FileMan: quit
	EOF

	# compare the results
	comp_results
}


function test02()	# test readline library 
{
	tc_register "test \"pwd\""

	tc_exec_or_break pwd expect cat chmod || return

	local dir=`pwd`
	local line="Current directory is"

	# create expect file to set TC_TEMP_USER password and issue scp command
	local expcmd=`which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/fileman 
		expect {
			timeout abort
			"FileMan: " { send "pwd\r" }
		}
		expect {
			timeout abort
			"FileMan: " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$TCTMP/actout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	# create the expected output
	cat > $TCTMP/expout <<-EOF
		FileMan: pwd
		$line $dir
		FileMan: quit
	EOF

	# compare the results
	comp_results
}


function test03()	# test readline functionality 
{
	tc_register "test \"list\""

	tc_exec_or_break mkdir expect cat chmod || return

	local dir=$TCTMP/tmp_d1
	mkdir $dir
	mkdir $dir/tmp_d2
	touch $dir/aaa

	# create expect file to set TC_TEMP_USER password and issue scp command
	local expcmd=`which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/fileman 
		expect {
			timeout abort
			"FileMan: " { send "ls $dir\r" }
		}
		expect {
			timeout abort
			"FileMan: " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$TCTMP/actout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	# create the expected output
	cat > $TCTMP/expout <<-EOF
		FileMan: ls $dir
		aaa tmp_d2/
		FileMan: quit
	EOF

	# compare the results
	comp_results
}


function test04()	# test readline functionality   
{
	tc_register "test \"cd\""

	tc_exec_or_break pwd mkdir expect cat chmod || return

	local line="Current directory is"
	local dir1="`pwd`"
	local dir2=$TCTMP
	mkdir $TCTMP/temp/
	local dir3=$TCTMP/temp

	# create expect file to test commands in fileman
	local expcmd=`which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/fileman 
		expect {
			timeout abort
			"FileMan: " { send "pwd\r" }
		}
		expect {
			timeout abort
			"FileMan: " { send "cd $TCTMP\r" }
		}
		expect {
			timeout abort
			"FileMan: " { send "cd temp/\r" }
		}
		expect {
			timeout abort
			"FileMan: " { send "cd ..\r" }
		}
		expect {
			timeout abort
			"FileMan: " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$TCTMP/actout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	# create the expected output
	cat > $TCTMP/expout <<-EOF
		FileMan: pwd
		$line $dir1
		FileMan: cd $TCTMP
		$line $dir2
		FileMan: cd temp/
		$line $dir3
		FileMan: cd ..
		$line $dir2
		FileMan: quit
	EOF

	# compare the results
	comp_results
}


function test05()	# test readline functionality 
{
	tc_register "test \"view\""

	tc_exec_or_break pwd expect cat chmod || return

	local fname=$TCTMP/tmp_file
	local text="Hello, this is a test!"
	# write something to the file
	echo $text > $TCTMP/tmp_file

	# create expect file to test commands in fileman
	local expcmd=`which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/fileman 
		expect {
			timeout abort
			"FileMan: " { send "view $fname\r" }
		}
		expect {
			timeout abort
			"FileMan: " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$TCTMP/actout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	# create the expected output
	cat > $TCTMP/expout <<-EOF
		FileMan: view $fname
		$text
		FileMan: quit
	EOF

	# compare the results
	comp_results
}


function test06()	# test readline functionality
{
	tc_register "test history"

	tc_exec_or_break touch expect cat chmod || return

	touch $TCTMP/actout

	# create expect file to test "rltest" - a readline application
	local expcmd=`which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
		spawn -noecho $MYDIR/rltest  
		expect {
			timeout abort
			"readline$ " { send "aaa\r" }
		}
		expect {
			timeout abort
			"readline$ " { send "bbb\r" }
		}
		expect {
			timeout abort
			"readline$ " { send "ccc\r" }
		}
		expect {
			timeout abort
			"readline$ " { send "list\r" }
		}
		expect {
			timeout abort
			"readline$ " { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/exp$TCID

	# execute the test
	$TCTMP/exp$TCID >$TCTMP/actout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	# create the expected output
	cat > $TCTMP/expout <<-EOF
		readline$ aaa
		aaa
		readline$ bbb
		bbb
		readline$ ccc
		ccc
		readline$ list
		list
		0: aaa
		1: bbb
		2: ccc
		3: list
		readline$ quit
		quit
	EOF

	# compare the results
	comp_results
}
################################################################################
# main
################################################################################

TST_TOTAL=6

tc_setup			# standard setup

test01
test02
test03
test04
test05
test06
