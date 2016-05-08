#!/bin/bash
############################################################################################
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
## File :	template_sh
##
## Description:	Test that shadow passwords are used properly
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

# global variables
shadow_line1=""
shadow_line2=""

################################################################################
# the testcase functions
################################################################################

function test01()	# verify temp user has entry in /etc/shadow
{
	tc_register	"new users go into /etc/shadow"
	tc_exec_or_break cat || return

	shadow_line1="`cat /etc/shadow | grep \"$tempuser2\"`" >/dev/null
	[ "$shadow_line1" ]
	tc_pass_or_fail $? "$tempuser2 was not put into /etc/shadow"
}

function test02()	# set a pasword - should modify user's shadow pw
{
	tc_register	"set password changes /etc/shadow"
	tc_exec_or_break expect cat chmod grep || return

	local expcmd=`/usr/bin/which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		set timeout 5
		proc abort {} { exit 1 }
		spawn passwd $tempuser2
		expect {
			timeout abort
			assword:
		}
		sleep 2
		send "2zxcvbnm345abcd\r"
		expect {
			timeout abort
			assword:
		}
		sleep 2
		send "2zxcvbnm345abcd\r"
		expect {
			timeout abort
			changed
		}
	EOF
	chmod +x $TCTMP/exp$TCID
	$TCTMP/exp$TCID >$stdout 2>$stderr
	tc_fail_if_bad $? "could not set password" || return

	shadow_line2="`cat /etc/shadow | grep \"$tempuser2\"`"
	[ "$shadow_line1" != "$shadow_line2" ]
	tc_pass_or_fail $? \
		"$tempuser2 password not changed in /etc/shadow: $shadow_line2"
}

function test03()	# test password login
{
	tc_register	"login using changed password"
	tc_exec_or_break cat chown chmod expect || return

	# tempuser1's login scripts
	cat >> /home/$tempuser1/.bashrc <<-EOF
		echo "OK1"
	EOF
	chown $tempuser1 /home/$tempuser1/.bashrc
	cp -a /home/$tempuser1/.bashrc /home/$tempuser1/.bash_profile

	# tempuser2's login scripts
	cat >> /home/$tempuser2/.bashrc <<-EOF
		echo "OK2"
	EOF
	chown $tempuser2 /home/$tempuser2/.bashrc
	cp -a /home/$tempuser2/.bashrc /home/$tempuser2/.bash_profile

	local expcmd=`/usr/bin/which expect`
	cat > $TCTMP/exp$TCID <<-EOF
		#!$expcmd -f
		set timeout 5
		spawn su -l $tempuser1
		expect {
			timeout { exit 1 }
			OK1
		}
		send "su -l $tempuser2\r"
		expect {
			timeout { exit 2 }
			assword:
		}
		sleep 2
		send "2zxcvbnm345abcd\r"
		expect {
			timeout { exit 3 }
			OK2
		}
	EOF
	chmod +x $TCTMP/exp$TCID
#	$TCTMP/exp$TCID >$stdout 2>$stderr
	$TCTMP/exp$TCID &>$stdout 
	tc_pass_or_fail $? "$tempuser2 unable to login using password"
}

################################################################################
# main
################################################################################

TST_TOTAL=3

tc_setup			# standard tc_setup

tc_root_or_break || exit

tc_add_user_or_break || exit
tempuser1=$TC_TEMP_USER
tc_add_user_or_break || exit
tempuser2=$TC_TEMP_USER

test01 && \
test02 && \
test03
