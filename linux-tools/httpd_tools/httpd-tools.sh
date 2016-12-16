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
## File :        httpd-tools.sh
##
## Description:  Test httpd-tools
##
## Author:       Athira Rajeev
###########################################################################################

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/httpd_tools
source $LTPBIN/tc_utils.source
SDIR=${LTPBIN%/shared}/httpd_tools/

# system files
HTTPD_CONF="/etc/httpd/conf/httpd.conf"
TOOLS="ab htdbm htdigest htpasswd logresolve"

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_root_or_break || exit
        tc_exec_or_break cat grep || exit

	tc_exec_or_break $TOOLS || return

	# apache must be installed
	rpm -q httpd >$stdout 2>$stderr
	tc_break_if_bad $? "httpd required, but not installed" || return 
	
	tc_exists $HTTPD_CONF
	tc_break_if_bad $? "conf file required, but not found" || return

	httpd_cleanup=0
	service httpd status &> /dev/null
	[ $? -eq 0 ] && \
		httpd_cleanup=1

	# backup files which are touched by the testcase.
        cp -f $HTTPD_CONF $TCTMP/httpd.conf

	HOST="127.0.0.1"

	tc_add_user_or_break || return # sets TC_TEMP_USER
	USER=$TC_TEMP_USER

	tc_add_user_or_break || return # sets TC_TEMP_USER
	USER2=$TC_TEMP_USER

	mkdir $TCTMP/test
	echo "Test" > $TCTMP/test/x	
	cat <<-EOF >> $HTTPD_CONF
		Alias $TCTMP/test/ "$TCTMP/test/"
		<Directory "$TCTMP/test">
		Options Indexes MultiViews FollowSymLinks ExecCGI
		AllowOverride None
		Order allow,deny
		Allow from all
		</Directory>

	EOF

		cat >> $TCTMP/download.exp <<-EOF
		#!/usr/bin/expect
		set timeout 5
		set file [lindex \$argv 0]
		set user [lindex \$argv 1]
		proc abort {} { exit 1 }
		spawn wget -O \$file --user=\$user --ask-password http://$HOST/$TCTMP/test/x
		# Look for passwod prompt
		expect "*?assword:*"
		# Send password aka $password
		send -- "password\r"
		expect eof
		EOF
	
	chmod +x $TCTMP/download.exp

	service httpd stop  >$stdout 2>$stderr
	tc_wait_for_inactive_port 80
}

function tc_local_cleanup()
{
	cp -rf $TCTMP/httpd.conf $HTTPD_CONF
	service httpd restart >$stdout 2>$stderr
	
	# Restore status of httpd service
	if [ $httpd_cleanup -eq 0 ]; then
		service httpd stop >$stdout 2>$stderr
		tc_break_if_bad $? "failed to stop httpd"
	fi 
}
function logresolve_test()
{
	tc_register "logresolve test"
	
	echo "$HOST - frank [<date>:13:55:36 -0700] "GET /apache_pb.gif HTTP/1.0" 200 2326" > $TCTMP/access.log
	logresolve -s $TCTMP/file -c < $TCTMP/access.log > $TCTMP/logresolve-result
	tc_fail_if_bad $? "Failed to execute logresolve"

	grep localhost $TCTMP/logresolve-result
	tc_pass_or_fail $? "logresolve failed to resolve ip to hostname"
}

function htpasswd_test()
{
	tc_register "htpasswd test"
	
	cat <<-EOF >> $HTTPD_CONF
		<Directory "$TCTMP/test">
		AuthType Basic
		AuthName "Restricted Files"
		# (Following line optional)
		AuthBasicProvider file
		AuthUserFile $TCTMP/test/passwd_file
		Require user $USER
		</Directory>
	EOF

	htpasswd -bc $TCTMP/test/passwd_file $USER password
	tc_fail_if_bad $? "htpasswd failed to create passwd file"

	service httpd start
	tc_wait_for_active_port 80
	tc_fail_if_bad $? "failed to stat httpd server"

	$TCTMP/download.exp $TCTMP/htpasswd_file $USER
	grep -q Test $TCTMP/htpasswd_file
	tc_pass_or_fail $? "failed to download file with the created htpasswd"

	tc_register "htpasswd -c"
	expect -c "spawn htpasswd -c $TCTMP/test/passwd_file $USER; expect \"*password*:\"; send -- \"password\r\"; expect \"*password*:\"; send -- \"password\r\"; expect eof"
	tc_fail_if_bad $? "htpasswd failed to create passwd file with -c"

	$TCTMP/download.exp $TCTMP/htpasswd_file1 $USER
	grep -q Test $TCTMP/htpasswd_file1
        tc_pass_or_fail $? "failed to download file with the created htpasswd -c"

	tc_register "htpasswd -mb"
	htpasswd -mb $TCTMP/test/passwd_file $USER2 password
	tc_pass_or_fail $? "htpasswd failed to create passwd file with -m"

	tc_register "htpasswd -D"
	htpasswd -D $TCTMP/test/passwd_file $USER
	tc_fail_if_bad $? "htpasswd failed to remove user"

	$TCTMP/download.exp "$TCTMP/htpasswd_file2" $USER
	grep -q Test $TCTMP/htpasswd_file2
	if [ $? -eq 0 ]; then
		tc_fail $? "htpasswd failed to remove user" || return
	fi
	
	tc_pass

}

function htdigest_test()
{
	tc_register "htdigest test"
	
	sed -i 's/AuthType Basic/AuthType Digest/g' $HTTPD_CONF
	tc_fail_if_bad $? "Failed to edit httpd.conf file"

	expect -c "spawn htdigest -c $TCTMP/test/passwd_file \"Restricted Files\" $USER; expect \"New password:\"; send -- \"password\r\"; expect \"*password:\"; send -- \"password\r\"; expect eof"

	service httpd stop
	tc_wait_for_inactive_port 80

	service httpd start
	tc_wait_for_active_port 80
        tc_fail_if_bad $? "failed to start httpd server"

	$TCTMP/download.exp $TCTMP/htdigest_file $USER
	grep -q Test $TCTMP/htdigest_file
        tc_pass_or_fail $? "failed to download file with the created htdigest"
}

function htdbm_test()
{
	tc_register "htdbm test"
	
	sed -i 's/AuthType Digest/AuthType Basic/g' $HTTPD_CONF
	sed -i 's/AuthBasicProvider file/AuthBasicProvider dbm/g' $HTTPD_CONF
	sed -i 's:AuthUserFile $TCTMP/test/passwd_file:AuthDBMUserFile $TCTMP/test/passwd_file:g' $HTTPD_CONF
	
	expect -c "spawn htdbm -c $TCTMP/test/passwd_file $USER; expect \"*password*:\"; send -- \"password\r\"; expect \"*password*:\"; send -- \"password\r\"; expect eof"
	tc_fail_if_bad $? "htdbm -c failed to create password"
	
	service httpd stop
	tc_wait_for_inactive_port 80

	service httpd start
        tc_wait_for_active_port 80
        tc_fail_if_bad $? "failed to start httpd server"

	$TCTMP/download.exp $TCTMP/htdbm_file $USER
	grep -q Test $TCTMP/htdbm_file
        tc_pass_or_fail $? "failed to download file with the created htdbm"

	tc_register "htdbm -bc"
	htdbm -bc $TCTMP/test/passwd_file $USER password
	tc_fail_if_bad $? "htdbm -bc failed to create password"

	$TCTMP/download.exp $TCTMP/htdbm_file1 $USER
        grep -q Test $TCTMP/htdbm_file1
        tc_pass_or_fail $? "failed to download file with the created htdbmi -bc"

	tc_register "htdbm -l"
	htdbm -l $TCTMP/test/passwd_file &> $TCMP/result 
	grep -w $USER $TCMP/result
	tc_pass_or_fail $? "htdbm -l failed to list user"

	tc_register "htdbm -vb"
	htdbm -vb $TCTMP/test/passwd_file $USER password
	tc_pass_or_fail $? "htdbm failed to validate password"

	tc_register "htdbm -x"
	htdbm -x $TCTMP/test/passwd_file $USER 
	tc_fail_if_bad $? "htdbm -x failed"

	htdbm -l $TCTMP/test/passwd_file &> $TCMP/result_del
	grep -w $USER $TCMP/result_del
	if [ $? -eq 0 ]; then
		tc_fail "Failed to remove user from database"
	fi
	tc_pass
}

function ab_test()
{
	tc_register "ab test"
	
	ab -n 100 -kc 10 http://localhost/ &> $TMP/result
	grep -E "Concurrency Level:\s+10" $TMP/result && grep -E "Complete requests:\s+100" $TMP/result
	tc_pass_or_fail $? "ab command failed to process statistics for specified requests"

}
################################################################################
# main
################################################################################

TST_TOTAL=11

tc_setup

logresolve_test
htpasswd_test
htdigest_test
htdbm_test
ab_test
