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
## File :	expect.sh
##
## Description:	Test basic functionality/commands of Expect program
##
## Author:	Yu-Pao Lee, yplee@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# the testcase functions
################################################################################

function test01()	# installation check
{
	tc_register	"installation check"
	tc_executes expect
	tc_pass_or_fail $? "not properly instaled"
}

function test02()	# test expect, spawn, send, send_user, and lindex
{
	tc_register	"test expect/spawn/send/send_user/lindex"
	local password="k9j8d7sg"
	
	tc_exec_or_break scp cat chmod || return

	# create expect file to test Expect commands
	export HOST=`hostname -s`
	local expcmd=`which expect`
	cat > $TCTMP/expect.scr <<-EOF
		#!$expcmd -f
		set env(USER) $TC_TEMP_USER
		set timeout 60
		set id \$env(USER)
		set RHOST \$env(HOST)
		proc abort {} { exit 1 }
		spawn passwd [lindex \$argv 0]
		set password [lindex \$argv 1]
		expect {
			timeout abort
			"assword:" { sleep 2; send "\$password\r" }
		}
		expect {
			timeout abort
			"assword:" { sleep 1; send "\$password\r" }
		}
		expect eof
		# spawn su and issues scp
		# to verify the password is set and correct
		spawn su - $TC_TEMP_USER
		expect {
			timeout abort
			"\$id@\$RHOST" { send "mkdir tmpd\r" }
		}
		expect { 
			timeout abort
			"\$id@\$RHOST" { send "touch aaa\r" }
		}
		expect { 
			timeout abort
			"\$id@\$RHOST" { send "scp aaa \$id@\$RHOST:./tmpd\r" }
		}
		expect {
			timeout abort
			"(yes/no)?" { send "yes\r" }
		}
		expect {
			timeout abort
			"assword:" { send "\$password\r" }
		}
		expect {
			timeout abort
			"\$id@\$RHOST" { send "exit\r" }
		}
		expect eof
		#expect {
		#	timeout abort
		#	"\$id@\$RHOST"
		#}
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/expect.scr
	$TCTMP/expect.scr $TC_TEMP_USER $password >$stdout 2>$stderr
	tc_pass_or_fail $? "expect file failed."
}

function test03()	# test puts, set, unset, send_error, info exists
{
	tc_register	"test set/unset/info exists"
	tc_exec_or_break cat chmod || return

	# create expect file to test Expect commands 
	local expcmd=`which expect`
	cat > $TCTMP/expect.scr <<-EOF
		#!$expcmd -f
		set sleep 99		;# set variable sleep to be 99
		
		# use catch to check if puts command fails
		if 1==[catch {puts "sleep is set to be \$sleep"}] {
			send_error "catch return 1 for puts command\n"
			exit 1
		}
		
		# test "info" command
		# "info exists" returns 1 if variable exists or 0 otherwise
		if 1==[info exists sleep] {
			send_user "ok, sleep is set!\n"
		} else {
			send_error "the variable - sleep - should be set\n"
			exit 1
		}	

		unset sleep		;# variable sleep can no longer be read

		if 1==[info exists sleep] {
			send_error "variable sleep should no longer be set\n"
			exit 1
		} else {
			send_user "ok, sleep is unset!\n"
		}	
		
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/expect.scr
	$TCTMP/expect.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "expect file failed." 
}

function test04()	# test proc, catch, and error 
{
	tc_register	"test proc/catch/error"
	tc_exec_or_break cat chmod || return

	# create expect file to test Expect commands 
	local expcmd=`which expect`
	cat > $TCTMP/expect.scr <<-EOF
		#!$expcmd -f
		set answer 6		;# set variable answer to be 6
		proc abort {} { exit 1 }
		proc sum {args} {
			set total 0
			foreach int \$args {
				if {\$int < 0} {error "number is < 0"}
				incr total \$int
			}
			return \$total
		}	
		
		# use catch to check if sum works as expected
		# catch returns 1 if there was an error or 0 if the
		# procedure returns normally
		# the return value from sum is saved in result
		if 0==[catch {sum 1 2 3} result] {
			send_user "catch return 0 for sum\n"
			if {\$result != \$answer} {
				send_error "error in sum\n"
				abort
			} 
		} else {
			send_error "catch return 1 for sum\n"
			abort
		}	

		# call proc sum again, but this time pass (-1, 2, 3) to it
		# on purpose to check if the error message is caught by result
		if 0==[catch {sum -1 2 3} result] {
			send_error "{sum -1 2 3} -> catch return 0\n"
			abort
		} else { 
			if {\$result == "number is < 0"} { 
				send_user "error is catched!\n"
			} else {
				send_error "error is not catched.\n"
				abort
			}	
		}	
		
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/expect.scr
	$TCTMP/expect.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "expect file failed." 
}

function test05()	# executing UNIX commands in Expect program  
{
	tc_register	"executing UNIX commands in Expect"
	tc_exec_or_break cat chmod || return 1

	# create expect file to executing UNIX program 
	local expcmd=`which expect`
	cat > $TCTMP/expect.scr <<-EOF
		#!$expcmd -f
		proc abort {} { exit 1 }
	
		if 1==[catch {exec touch $TCTMP/expfile}] {
			send_error "catch return 1 for touch command\n"
			abort
		}
		
		# use "file exists" to check if the file exists
		# return 1 if file exists, 0 otherwise
		if 0==[file exists $TCTMP/expfile] {
			send_error "file created with touch does not\
					exist\n"
			abort
		}

		if 1==[catch {exec rm $TCTMP/expfile}] {
			send_error "catch return 1 for rm command\n"
			abort
		}
		
		# use "file exists" to check if the file exists
		# return 1 if file exists, 0 otherwise
		if 1==[file exists $TCTMP/expfile] {
			send_error "error: file should be rm already, but\
					still exists\n"
			abort
		}	
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/expect.scr
	$TCTMP/expect.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "expect file failed." 
}


function test06()	# check if timeout actually takes effect  
{
	tc_register	"check if timeout actually takes effect"
	tc_exec_or_break cat chmod || return 1

	# create expect file to executing UNIX program 
	local expcmd=`which expect`
	cat > $TCTMP/expect.scr <<-EOF
		#!$expcmd -f
		set timeout 3
		spawn sleep 1000
		proc done {} { puts "timeout"; exit 0 }
	
		expect {
			timeout done
			"ERROR"
			}

		send_user "ERROR: should not see this!\n"
		exit 1
	EOF
	chmod +x $TCTMP/expect.scr
	$TCTMP/expect.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "expect file failed." 
}

################################################################################
# main
################################################################################

TST_TOTAL=6

tc_setup
tc_root_or_break || exit

tc_add_user_or_break || exit

test01 &&
test02 &&
test03 &&
test04 &&
test05 &&
test06
