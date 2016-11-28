#!/bin/bash
###########################################################################################
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
# source the standard utility functions
################################################################################
# Author:       rende@cn.ibm.com

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/krb5
source $LTPBIN/tc_utils.source

inits="/etc/init.d"
krb5_bin="/usr/kerberos/bin"
sys_bin="/usr/bin"
#krb5_sbin="/usr/sbin"
krb5_sbin="/usr/kerberos/sbin/"

domain=""		
kdb_passwd="kpassword"
app_server=""   
app_client=""  
user1=""      
user2=""     

#changeme: pass by scenario file command line envionment.
KDC_SERVER=9.47.101.218

MYREALM="BEAVERTON.IBM.COM"

installed="$sys_bin/kadmin \
        $krb5_sbin/ftpd $sys_bin/ktutil $krb5_sbin/telnetd \
        $sys_bin/kinit $sys_bin/klist $sys_bin/kdestroy \
        $krb5_bin/ftp $sys_bin/kpasswd $sys_bin/ksu \
        $sys_bin/kvno $krb5_bin/rcp $krb5_bin/rlogin \
        $krb5_bin/rsh $krb5_bin/telnet"

required="cat chmod cut diff dnsdomainname expect grep hostname xinetd id"

restart_xinetd="no"

#
#	tc_local_setup		tc_setup specific to this set of testcases
#
function tc_local_setup()
{
	# for CSTL SUTs: KDC_SERVER=test0, 
	[ -n "$KDC_SERVER" ] 
	tc_break_if_bad $? "env var KDC_SERVER not set" || return

	#check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return

	#add temporary user1 and user2
	tc_info "add two tempoaray users"
	tc_add_user_or_break &>/dev/null || return
	user1=$TC_TEMP_USER
	tc_add_user_or_break &>/dev/null || return
	user2=$TC_TEMP_USER

	# get server and client info
	local hostname=$(hostname -s)
	domain=$(dnsdomainname)
	app_server="$hostname.$domain"
	app_client=$app_server  # server and client are both SUT

	# shut down currently running xinetd, if running
	if $inits/xinetd status &>/dev/null ; then
		tc_info "Stopping currently running xinetd"
		$inits/xinetd stop &>/dev/null
		restart_xinetd="yes"
	fi

	# back up
	mv /etc/xinetd.conf $TCTMP/xinetd.conf 
	[ -e /etc/krb5.conf   ] && mv /etc/krb5.conf   $TCTMP/
	[ -e /etc/krb5.keytab   ] && cp /etc/krb5.keytab   $TCTMP/

	# create krb5.conf for these tests
	cat > /etc/krb5.conf <<-EOF
		[logging]
			kdc = FILE:/var/log/krb5/krb5kdc.log
			admin_server = FILE:/var/log/krb5/kadmind.log
			default = SYSLOG:NOTICE:DAEMON

		[libdefaults]
			ticket_lifetime = 24000
			default_realm = $MYREALM
			dns_lookup_realm = false
			dns_lookup_kdc = false

		[realms]
			$MYREALM = {
				kdc = $KDC_SERVER:88
				admin_server = $KDC_SERVER:749
				# default_domain = $domain
			}

		 [domain_realm]
			.$domain = $MYREALM
			$domain = $MYREALM

		# [appdefaults]
		# pam = {
		#   debug = false
		#   ticket_lifetime = 36000
		#   renew_lifetime = 36000
		#   forwardable = true
		#   krb4_convert = false
		# }
	EOF

	# add user1 and user2 as remote login users
	echo "$user1@$MYREALM"        > /home/$user1/.k5login
	chown $user1.users /home/$user1/.k5login
	chmod 600 /home/$user1/.k5login
	echo "$user2@$MYREALM"        > /home/$user2/.k5login
	chown $user2.users /home/$user2/.k5login
	chmod 600 /home/$user2/.k5login

	tc_info "original TERM=$TERM"
	if [ -z "$TERM" -o "$TERM" == "dumb" ] ; then
		export TERM=vt102
	fi
	tc_info "now TERM=$TERM"
	return 0
}

#
#	tc_local_cleanup	cleanup specific to this set of testcases
#
function tc_local_cleanup()
{
	# remove log files
	[ -e /var/log/krb5libs$$.log ] && rm /var/log/krb5libs$$.log

	# remove temporary users: user1 and user2 and files related
	local uid=`cat /etc/passwd | grep "^$user1" | cut -f3 -d:`
	rm -rf /tmp/krb5cc_$uid
	tc_del_user_or_break $user1 > /dev/null 2>&1
	local uid=`cat /etc/passwd | grep "^$user2" | cut -f3 -d:`
	rm -rf /tmp/krb5cc_$uid
	tc_del_user_or_break $user2 > /dev/null 2>&1

	# stop our instance of xinetd
	$inits/xinetd stop >/dev/null 2>&1

	# restore original /etc/krb5.conf and /etc/krb5.keytab, if saved
	[ -e $TCTMP/krb5.conf   ] && mv $TCTMP/krb5.conf   /etc/
	[ -e $TCTMP/krb5.keytab ] && mv $TCTMP/krb5.keytab /etc/
	[ -e $TCTMP/xinetd.conf ] && mv $TCTMP/xinetd.conf /etc/

	# restart xinetd if it was originaly running
	[ "$restart_xinetd" == "yes" ] && $inits/xinetd start >/dev/null 2>&1
}

################################################################################
# the testcase functions
################################################################################

#
#	test02	"create keytab"
#
# We must have a krb5 principal "admin" with password "admin"
function test02()
{
	tc_register	"add client/server principals and create keytab"

	local command="$sys_bin/kadmin -p admin"
	local expcmd=`which expect`
	cat > $TCTMP/expect02.scr <<-EOF
		#!$expcmd -f
		set timeout 3
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"assword for" { send "admin\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "addprinc $user1\r" }
		}
		expect {
			timeout { abort 2 }
			"$MYREALM\":" { send "$kdb_passwd\r" }
		}
		expect {
			timeout { abort 3 }
			"$MYREALM\":" { send "$kdb_passwd\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "addprinc $user2\r" }
		}
		expect {
			timeout { abort 2 }
			"$MYREALM\":" { send "$kdb_passwd\r" }
		}
		expect {
			timeout { abort 3 }
			"$MYREALM\":" { send "$kdb_passwd\r" }
		}

		expect {
			timeout { abort 1 }
			"kadmin:" { send "addprinc -randkey host/$app_server\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "ktadd host/$app_server\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "addprinc -randkey ftp/$app_server\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "ktadd ftp/$app_server\r" }
		}
		expect {
			timeout { abort 2 }
			"kadmin:" { send "quit\r" }
		}
		expect eof
	EOF
	tc_exist_or_break /etc/krb5.keytab || return 
	chmod +x $TCTMP/expect02.scr
	$TCTMP/expect02.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "did not create keytab"
}

function test02_rev()
{
	tc_register	"del client/server principals"

	local command="$sys_bin/kadmin -p admin"
	local expcmd=`which expect`
	cat > $TCTMP/expect02_rev.scr <<-EOF
		#!$expcmd -f
		set timeout 3
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"assword for" { send "admin\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "delprinc -force host/$app_server\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "delprinc -force ftp/$app_server\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "delprinc -force $user1\r" }
		}
		expect {
			timeout { abort 1 }
			"kadmin:" { send "delprinc -force $user2\r" }
		}
		expect {
			timeout { abort 2 }
			"kadmin:" { send "quit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect02_rev.scr
	$TCTMP/expect02_rev.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "did not delprinc"
}

#
#	test0c	ksu
#
function test0c()
{
	tc_register	"root ksu"
	local myname=`echo $USER`

	$sys_bin/ksu $user1 -e /usr/bin/id >$stdout 2>/dev/null
	grep $user1 $stdout | grep -q "uid="
	tc_fail_if_bad $? "did not switch to user $user1" || return

	[ "$USER" == "$myname" ]
	tc_pass_or_fail $? "did not exit properly from ksu session"
}

#
#	test0d	ktutil
#
function test0d()
{
	tc_register	"ktutil"

	local expcmd=`which expect`
	cat > $TCTMP/expect0d.scr <<-EOF
		#!$expcmd -f
		set timeout 3
		proc abort {n} { exit \$n }
		spawn $sys_bin/ktutil
		expect {
			timeout { abort 1 }
			"ktutil:" { send "clear\r" }
		}
		expect {
			timeout { abort 2 }
			"ktutil:" { send "rkt /etc/krb5.keytab\r" }
		}
		expect {
			timeout { abort 3 }
			"ktutil:" { send "l\r" }
		}
		expect {
			timeout { abort 4 }
			"ktutil:" { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect0d.scr
	$TCTMP/expect0d.scr >$stdout 2>$stderr
	tc_fail_if_bad $? "bad ktutil response" || return

	# see that list command gave reasonable output
	grep -q "$MYREALM" $stdout >/dev/null
	tc_pass_or_fail $? "expected to see \"$MYREALM\" in output"
}

#
#	test0a	kinit
#
function test0a()
{
	tc_register	"kinit"

	local expcmd=`which expect`
	cat > $TCTMP/expect0a.scr <<-EOF
		#!$expcmd -f
		set timeout 3
		proc abort {n} { exit \$n }
		spawn su - $user1
		expect {
			timeout { abort 1 }
			"$user1" { send "kdestroy\r" }
		}
		expect {
			timeout { abort 2 }
			"$user1" { send "kinit $user1\r" }
		}
		expect {
			timeout { abort 3 }
			"assword" { send "$kdb_passwd\r" }
		}
		expect {
			timeout { abort 4 }
			"$user1" { send "exit\r" }
		}

		spawn su - $user2
		expect {
			timeout { abort 1 }
			"$user2" { send "kdestroy\r" }
		}
		expect {
			timeout { abort 2 }
			"$user2" { send "kinit $user2\r" }
		}
		expect {
			timeout { abort 3 }
			"assword" { send "$kdb_passwd\r" }
		}
		expect {
			timeout { abort 4 }
			"$user2" { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect0a.scr
	$TCTMP/expect0a.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "did not kinit"
}

#
#	test0b	klist
#
# dependent of kinit test
function test0b()
{
	tc_register	"klist"
	echo "klist -5" | su - $user1 2>$stderr >$stdout
	tc_fail_if_bad $? "bad response from klist" || return

	grep -q "Expires" $stdout
	tc_pass_or_fail $? "did not list tickets"
}

#
# test0e rlogin
#
# dependent of kinit test
function test0e()
{
	tc_register	"rlogin"

	local command="su - $user1"
	local expcmd=`which expect`
	cat > $TCTMP/expect0e.scr <<-EOF
		#!$expcmd -f
		set timeout 10
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"$user1" { send "$krb5_bin/rlogin $app_server\r" }
		}
		expect {
			timeout { abort 1 }
			"$user1" { send "exit\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1" { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect0e.scr
	$TCTMP/expect0e.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "rlogin failed"
}

#
# test0f  client ksu
#
function test0f()
{
	tc_register     "client ksu"
	tc_exec_or_break sudo || return

	# ksu for non-root user, it must be set uid
 	cp $sys_bin/ksu $TCTMP; chmod u+s $sys_bin/ksu

	# allow password-less login from user2 to user1
	echo "$user2@$MYREALM" >> /home/$user1/.k5login
	sudo -u $user2 $sys_bin/ksu $user1 -n $user2 -e /usr/bin/id >$stdout 2>/dev/null
	grep $user1 $stdout | grep -q "uid="
	tc_pass_or_fail $? "$user2 -> $user1: Ensure ksu is root setuid!" 

	# restore the ksu executable
	mv $TCTMP/ksu $sys_bin/ksu
}

#
# test11 telnet
# telnet to user1 by its credential cache, no password needed
function test11()
{
	tc_register	"telnet"

	local command="su - $user1"
	local expcmd=`which expect`
	cat > $TCTMP/expect11.scr <<-EOF
		#!$expcmd -f
		set timeout 10
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"$user1" { send "$krb5_bin/telnet -a -x $app_server\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1" { send "exit\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1" { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect11.scr
	$TCTMP/expect11.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "telnet failed"
}

#
# test12 rsh
#
function test12()
{
	tc_register	"rsh"

	local command="su - $user1"
	local expcmd=`which expect`
	cat > $TCTMP/expect12.scr <<-EOF
		#!$expcmd -f
		set timeout 10
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"$user1" { send "$krb5_bin/rsh $app_server\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1" { send "exit\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1" { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect12.scr
	$TCTMP/expect12.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "rsh failed"
}

#
# test13 rcp
#
function test13()
{
	tc_register	"rcp"
	echo "$user1 temporary rcp file" > /home/$user1/rcp.src

	local command="su - $user1"
	local expcmd=`which expect`
	cat > $TCTMP/expect13.scr <<-EOF
		#!$expcmd -f
		set timeout 10
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"$user1" { send "$krb5_bin/rcp -x rcp.src $app_server:rcp.mid\r" }
		}
		expect {
			timeout { abort 1 }
			"$user1" { send "$krb5_bin/rcp -x $app_server:rcp.mid rcp.tgt\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1" { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect13.scr
	$TCTMP/expect13.scr >$stdout 2>$stderr && \
		diff /home/$user1/rcp.src /home/$user1/rcp.tgt
	tc_pass_or_fail $? "rcp failed"
}

#
# test14 ftp
# authorized by .k5login
function test14()
{
	tc_register	"ftp"
	echo "$user1 temporary ftp file" > /home/$user1/ftp.src

	local command="su - $user1"
	local expcmd=`which expect`
	cat > $TCTMP/expect14.scr <<-EOF
		#!$expcmd -f
		set timeout 10
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"$user1" { send "$krb5_bin/ftp -x $app_server\r" }
		}
		expect {
			timeout { abort 1 }
			"Name"  { send "$user1\r" }
		}
		expect {
			timeout { abort 5 }
			"ftp" { send "put ftp.src ftp.mid\r" }
		}
		expect {
			timeout { abort 5 }
			"ftp" { send "get ftp.mid ftp.tgt\r" }
		}
		expect {
			timeout { abort 5 }
			"ftp" { send "bye\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1" { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect14.scr
	$TCTMP/expect14.scr >$stdout 2>$stderr && \
		diff /home/$user1/ftp.src /home/$user1/ftp.tgt
	tc_pass_or_fail $? "ftp failed"
}

#
# test15 kpasswd
#
function test15()
{
	tc_register	"kpasswd"

	local command="su - $user1"
	local expcmd=`which expect`
	cat > $TCTMP/expect15.scr <<-EOF
		#!$expcmd -f
		set timeout 10
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"$user1"     { send "$sys_bin/kpasswd $user1\r" }
		}
		expect {
			timeout { abort 1 }
			"assword" { send "$kdb_passwd\r" }
		}
		expect {
			timeout { abort 5 }
			"new password:"    { send "$kdb_passwd\r" }
		}
		expect {
			timeout { abort 5 }
			"again:"           { send "$kdb_passwd\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1@$HOST"     { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect15.scr
	$TCTMP/expect15.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "change passwd failed"
}

#
# test16 kvno
#
function test16()
{
	tc_register	"kvno"

	local command="su - $user1"
	local expcmd=`which expect`
	cat > $TCTMP/expect16.scr <<-EOF
		#!$expcmd -f
		set timeout 10
		proc abort {n} { exit \$n }
		spawn $command
		expect {
			timeout { abort 1 }
			"$user1" { send "$sys_bin/kvno $user1 host/$app_server\r" }
		}
		expect {
			timeout { abort 5 }
			"$user1" { send "exit\r" }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect16.scr
	$TCTMP/expect16.scr >$stdout 2>$stderr
	tc_fail_if_bad $? "ticket version failed"

	# see that list command gave reasonable output
	cat $stdout | grep "$user1@$MYREALM" >/dev/null
	tc_pass_or_fail $? "expected to see \"$user1@$MYREALM\" in output"
}

#
# test00: start application services
#
function test00()
{
	tc_register	"start kerberized services on SUT"

	cat > /etc/xinetd.conf <<-EOF
		defaults
                {
                        instances      = 25
                        log_type       = FILE $TCTMP/servicelog
                        log_on_success = HOST PID
                        #log_on_failure = HOST RECORD
                }
		service klogin
		{
                        flags          = REUSE
                        socket_type    = stream
                        wait           = no
                        user           = root
                        server         = ${krb5_sbin}/klogind
                        server_args    = -5
                        disable        = no
                }
                service telnet
                {
                        flags          = REUSE
                        socket_type    = stream
                        wait           = no
                        user           = root
                        server         = ${krb5_sbin}/telnetd
                        disable        = no
                }
                service ftp
                {
                        socket_type    = stream
                        wait           = no
                        user           = root
                        server         = ${krb5_sbin}/ftpd
                        server_args    = -l -a
                        disable        = no
                }
                service kshell
                {
                        socket_type     = stream
                        wait            = no
                        user            = root
                        server          = ${krb5_sbin}/kshd
                        server_args     = -e -5
                        disable        = no
                }

	EOF
	# start application services
	/etc/init.d/xinetd restart >/dev/null 2>&1 
	tc_pass_or_fail $? "failed to start services thru xinetd" 
}

################################################################################
# main
################################################################################

TST_TOTAL=14

tc_setup

test00 || exit $? # start xinetd and krb5 services
test02 # addprinc and ktadd

test0c # root ksu
test0d # ktutil
test0a # kinit
test0b # klist
test0e # rlogin with credential cache by kinit
test0f # ksu need root setuid
test11 # telnet
test12 # rsh
test13 # rcp
test14 # ftp
test15 # kpasswd
test16 # kvno
test02_rev # del tempoary principals introduced
