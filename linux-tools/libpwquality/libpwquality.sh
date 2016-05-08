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
## File :        libpwquality.sh
##
## Description:  Test the APIs of libpwquality package.
##
## Author:      Tejaswini Sambamurthy <tejaswin.linux.vnet.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TESTS_DIR="${LTPBIN%/shared}/libpwquality"
REQUIRED="expect"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED

	set `find /usr/lib* -name libcrack\*`
	[ -f $1 ] &&  tc_break_if_bad $? "cracklib not installed properly"

	set `find /usr/lib* -name libpwquality\*`
        [ -f $1 ] &&  tc_break_if_bad $? "libpwquality not installed properly"

	set `find /usr/lib* -name pam_pwquality\*`
        [ -f $1 ] &&  tc_break_if_bad $? "libpwquality not installed properly"
        

	# Verifying that pam_pwquality is in /etc/pam.d/system-auth and /etc/pam.d/password-auth
        grep pam_pwquality /etc/pam.d/system-auth | grep -q password 
        tc_conf_if_bad $? "pam_pwquality has to be set as the type in system-auth"  
	grep pam_pwquality /etc/pam.d/password-auth | grep -q password
	tc_conf_if_bad $? "pam_pwquality has to be set as the type in password-auth"

	# Create a test user to use in PAM module testing
	tc_add_user_or_break || return
	test_user=$TC_TEMP_USER
	test_passwd=$TC_TEMP_PASSWD

	tc_root_or_break || return

	# Take a back up of pwquality.conf
	if [ -f /etc/security/pwquality.conf ];then
		mv /etc/security/pwquality.conf /etc/security/pwquality.conf.bak 
	else
		tc_info "/etc/security/pwquality.conf not found" && return
	fi
}

function tc_local_cleanup()
{
	mv /etc/security/pwquality.conf.bak /etc/security/pwquality.conf
}

function run_test()
{
	pushd $TESTS_DIR &> /dev/null

	# Testing the PAM module
	tc_register "PAM module"
	# Setting the limits in pwquality.conf, refer to pwquality.conf for details
	cat > /etc/security/pwquality.conf <<- EOF
	minlen = 11
	maxrepeat = 1
	EOF


	local expcmd=`which expect`
	cat > $TCTMP/pamtest <<-EOF
	#!$expcmd 
	spawn ssh $test_user@localhost
	expect "*yes/no*" { send "yes\r" }
	expect "* password:" { send "password\r" }
	expect "*$ " { send "passwd\r" }
	expect "*current*" { send "password\r" }
	expect "New password:" { send "asdf\r" }
	expect "New password:" {send "aabbqwertyop\r" }
	expect "New password:" {send "\r" }
	expect "*$ " {send "exit\r" }
	expect eof
	EOF

	chmod +x $TCTMP/pamtest	

	$TCTMP/pamtest >$stdout 2>$stderr
	grep -q "The password is shorter than 10 characters" $stdout
	tc_pass_or_fail $? "failed to use pam module"
	grep -q "The password contains more than 1 same characters consecutively" $stdout
	tc_pass_or_fail $? "failed to use pam module"


	tc_register "Pwscore and Pwmake"
	# Using pwscore test the quality limits in pwquality.conf and pwmake tools to test the API
	echo asdf | pwscore >$stdout 2>$stderr
	grep -q "The password is shorter than 10 characters" $stderr
	tc_fail_if_bad_rc $? "pwscore failed"
	echo 9999mxaneltswtv | pwscore >$stdout 2>$stderr
	grep -q "The password contains more than 1 same characters consecutively" $stderr
	tc_fail_if_bad_rc $? "pwscore failed"
	echo ncjsleitncu863j7 | pwscore >$stdout 2>$stderr
	tc_pass_or_fail $? "pwscore failed"
	
	pwmake 90 | pwscore >$stdout 2>$stderr
	tc_pass_or_fail $? "pwmake failed"
	

	popd &> /dev/null
}

################################################################################
# MAIN
################################################################################
TST_TOTAL=2
tc_setup
run_test
