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
## File :       sysvinitcmds_tests.sh
##
## Description: This program tests basic functionality of commands in sysvinit
##
## Author:      Manoj Iyer  manjo@mail.utexas.edu
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

#
# Function:	test01
#
function test01()
{
	tc_register "installation check"
	tc_executes  pidof last lastb mesg utmpdump wall 
	tc_pass_or_fail $? "sysvinit not installed properly"
}

#
# Function:    test02
#
test02()
{
	tc_register    "pidof"

	# use pidof to get my pid (-x needed for scripts)
	pidof_pid=$(pidof -x $0)

	[ "$pidof_pid" ] && [ "$pidof_pid" == "$$" ]
	tc_pass_or_fail $? "Expected my pid to be $$ but got $pidof_pid instead"
}

#
# Function:    test03
#
test03()
{
	tc_register    "last"

	last | grep -q "wtmp begins" 2>$stderr
	tc_pass_or_fail $? "failed to find unique sting wtmp begin"
}

#
# Function:    test04
#
test04()
{
	tc_register    "lastb"

	lastb 2>&1 | grep -q "btmp begins" 
	tc_pass_or_fail $? "failed to find unique string."
}

#
# Function:    test05
#
test05()
{
	tc_register    "utmpdump"

	tc_exist_or_break /var/run/utmp || return

	utmpdump /var/run/utmp &>$stdout	# good output in stderr!
	tc_fail_if_bad $? "utmpdump failed"

	expected="Utmp dump of /var/run/utmp"

	grep -q "$expected" $stdout 2>>$stderr
	tc_pass_or_fail $? "expected to see \"$expected\" in stdout"
}

#
# Function:    test06	SKIPPED maybe no pts from script
#
test06()
{
	tc_register    "wall"

	message="THIS IS A BIG HELLO FROM ROOT"

	echo $message | wall &>$stdout
	tc_pass_or_fail $? "Unexpected response from wall command" || return
}

#
# Function:    test07
#
test07()
{
	tc_exec_or_break taskset || return
	tc_register    "mountpoint"
	    
	mountpoint /
	tc_pass_or_fail $? "expect to see root filesystem's Major and Minor NO"
}

#
# main
# 

TST_TOTAL=7
tc_setup	# exits on failure

tc_root_or_break || exit
tc_root_or_break grep tail || exit

test01 &&
test02
test03 &&
test04 &&
test05 &&
test06 &&
test07
