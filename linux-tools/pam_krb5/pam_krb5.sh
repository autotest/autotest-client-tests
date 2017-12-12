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
## File :	pam_krb5.sh
##
## Description:	Tests for pam_krb5
##
## Author:	Suzuki K P <suzukikp@in.ibm.com>
###########################################################################################

###########cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/pam_krb5
source $LTPBIN/tc_utils.source
testdir=${LTPBIN%/shared}/pam_krb5

PATH=${PATH}:/usr/sbin:/usr/local/sbin:/usr/kerberos/sbin

principal=`id -nu`
cd $testdir

PATH=${PATH}:${testdir}/tools
export KRB5_BINDIR=/usr/kerberos/bin/

#TODO: Fix the lib
pam_krb5=`rpm -ql pam_krb5 | grep pam_krb5.so 2>/dev/null`

export KDC_DIR=$testdir/kdc
export KRB5_CONFIG=$testdir/config/krb5.conf
export KRBCONFDIR=$testdir/config
export KRB_CONF=$testdir/config/krb.conf
export KRB_REALMS=$testdir/config/krb.realms
export KRB5_KDC_PROFILE=$testdir/config/kdc.conf
export KRB5CCNAME=/dev/bogus-missing-file
export KRBTKFILE=/dev/bogus-missing-file
flags=unsecure_for_debugging_only

create_configs()
{
	cat > $KRB5_CONFIG <<-EOF
[logging]
 default = FILE:$KDC_DIR/krb5libs.log
 kdc = FILE:$KDC_DIR/krb5kdc.log
 admin_server = FILE:$KDC_DIR/kadmind.log

[libdefaults]
  ticket_lifetime = 24000
  default_realm = EXAMPLE.COM
  renew_lifetime=0
  forwardable = true
  proxiable = true
  noaddresses = true
	
[realms]
  EXAMPLE.COM = {
      kdc = $HOSTNAME:8800
      admin_server = $HOSTNAME:8801
      kpasswd_server = $HOSTNAME:8802
  }

[kdc]
  profile = $KRB5_KDC_PROFILE

[appdefaults]
 pam = {
   debug = true
   krb4_convert = true
   boolean_parameter_1 = true
   boolean_parameter_2 = false
   string_parameter_1 = ""
   string_parameter_2 = blah foo woof
   list_parameter_1 = ample sample example
 }
EOF

# create kdc.conf
	cat > $KRB5_KDC_PROFILE <<-EOF
[kdcdefaults]
 v4_mode = nopreauth
  kdc_ports = 8800

[realms]
 EXAMPLE.COM = {
   acl_file = $KRBCONFDIR/kadm5.acl
   admin_keytab = $KDC_DIR/kadm5.keytab
   dict_file = /usr/share/dict/words
   database_name = $KDC_DIR/principal
   key_stash_file = $KDC_DIR/stash_file
   master_key_type = des-cbc-crc
   supported_enctypes = des3-cbc-sha1:normal des-cbc-crc:normal
   kadmind_port = 8801
   kpasswd_port = 8802
 }
EOF

# create krb.conf
	cat > $KRB_CONF <<-EOF
EXAMPLE.COM
EXAMPLE.COM $HOSTNAME:8800
EOF

}
settle() {
	sleep 1
}

k524start() {
	if test x$K524DPID != x ; then
		kill $K524DPID
		unset K524DPID
	fi

	krb524d -m -r EXAMPLE.COM -nofork 2>/dev/null &
	K524DPID=$!

	kill -CONT $K524DPID
}

kdcstart() {
	if test x$KDCPID != x ; then
		kill $KDCPID
		unset KDCPID
	fi

	rm -rf $testdir/kdc;  mkdir -p $testdir/kdc
	(echo .; echo .) | kdb5_util create -s 2>$stderr > /dev/null
	
	tc_fail_if_bad $? "Unable to create kdb5 database" || exit

	kadmin.local -q 'addpol -minlength 6 minimum_six' 2> $stderr > /dev/null &&
	kadmin.local -q 'ank -pw foo '$principal 2>>$stderr > /dev/null && 
	kadmin.local -q 'modprinc -maxrenewlife "1 day" krbtgt/EXAMPLE.COM' 2>>$stderr > /dev/null &&
	kadmin.local -q 'modprinc -maxrenewlife "1 day" '$principal 2>> $stderr  > /dev/null
	
	tc_fail_if_bad_rc $? "Unable to initialize the krb5 settings" || exit

	rm -f $testdir/kdc/krb5kdc.log
	rm -f $testdir/kdc/kadmind.log
	rm -f $testdir/kdc/krb5libs.log
	krb5kdc -r EXAMPLE.COM -n -port 8002 &
	KDCPID=$!

	if test x$KADMINDPID != x ; then
		kill $KADMINDPID
		unset KADMINDID
	fi

	kadmind -r EXAMPLE.COM -nofork &
	KADMINDPID=$!

	k524start

	settle

	kill -CONT $KDCPID
	kill -CONT $KADMINDPID

	tc_wait_for_pid $KDCPID $KADMINDPID
}

k524stop() {
	if test x$K524DPID != x ; then
		kill $K524DPID
		unset K524DPID
	else
		echo "echo error: no running krb524d"
		exit 1
	fi
}

kdcstop() {
	k524stop
	if test x$KADMINDPID != x ; then
		kill $KADMINDPID
		unset KADMINDID
	else
		echo "echo error: no running kadmind"
		exit 1
	fi
	if test x$KDCPID != x ; then
		kill $KDCPID
		unset KDCPID
		kdb5_util destroy -f 2> /dev/null > /dev/null
	else
		echo "echo error: no running KDC"
		exit 1
	fi
}

run() {
	# Filter out the module path.
	pam_harness "$@" 2>&1 | sed s,"\`.*pam",'\`pam',g  > $stdout 2>$stderr
}

generate_random_bits()
{
	# Find the "disk" drive. Disk always has minor num "0".
	disk=`cat /proc/partitions | grep " 0 " | head -n 1 | awk '{print $4}' 2>/dev/null`

	gateway=`route -n | awk '{print $2}' | grep [1-9] | head -n 1`
	tc_info "Found gateway $gateway"
	cat > $TCTMP/gen_random.sh <<EOF
	#!/bin/sh
	ping $gateway &>/dev/null &
	while true; do dd if=/dev/$disk of=/dev/null bs=512 &>/dev/null ; done
EOF

	if [ "$disk" != "" ]; then
		sh $TCTMP/gen_random.sh &
		RANDOM_PID=$!
		tc_info "Using /dev/$disk to generate random data(pid=$RANDOM_PID)"
	else
		t_info "Couldn't find a disk to perform I/O to generate random bits"
		RANDOM_PID=0
	fi
}
 
# kadmind servers take a long time to initialize depending on
# the availability of random bits on the machine.
# Wait for 5 mins (max)
wait_for_krb_server()
{
	local t;
	
	tc_info "Waiting for KRB5 servers"
	for ((t=0; t<60; t=$((t+1))))
	do
		sleep 20
#  This is a hack to determine if the kadmind has started. 
#  Kadmind listens on the socket before initializing it properly.
#		tc_wait_for_active_port 8802 60 
		grep "starting" $KDC_DIR/kadmind.log &>/dev/null
		[ $? -eq 0 ] && return
	done
	tc_fail "Unable to start krb5kdc in 5 mins. This could mean a problem with your krb5 servers" \
		"Try increasing the delay in wait_for_krb5_server()"
	exit 1
}
tc_local_setup()
{       	
	### krb524d is missing in RHEL . Removing it from the list. 
	### Failure in test "No Expiration Warning". Check Bug #67587.
	tc_executes "krb5kdc kadmind kadmin.local" || exit 1
	HOSTNAME=`hostname 2>/dev/null`
	[ x$HOSTNAME == x ] && HOSTNAME="localhost"

	HOSTIP=`hostname --all-ip-addresses 2>/dev/null | awk '{print $1}' 2>/dev/null`
	[ x$HOSTIP != x ] ||  tc_break "Unable to find ip using hostname -i"  || exit

	[ x$pam_krb5 != x ] || tc_break "Unable to find pam_krb5.so" || exit
	tc_info "Creating configs"
	create_configs
	generate_random_bits
	tc_info "Starting krb5 servers"
	kdcstart
	tc_info "Setting password to \"foo\"."
	kadmin.local -q 'cpw -pw foo '$principal 2>$stderr > /dev/null
	tc_fail_if_bad $? "Unable to set the password" || exit
	wait_for_krb_server
	# kill the random bit generator
	tc_info "Killing the random bit generator(pid=$RANDOM_PID)"
	[ "$RANDOM_PID" != "0" ] && kill -9 $RANDOM_PID 2>/dev/null
	# If we are here, then KRB5 has started and RANDOM_PID is killed.
	RANDOM_PID=0

        if [ -e /etc/krb5.keytab ]; then
            keytab=1
            mv /etc/krb5.keytab /etc/krb5.keytab.bckup
        fi
}

function tc_local_cleanup()
{
	tc_info "Stoping krb5 servers"
	kdcstop
	[ "$RANDOM_PID" != "0" ] && kill -9 $RANDOM_PID 2>/dev/null

        if [ $keytab -eq 1 ]; then
            mv /etc/krb5.keytab.bckup /etc/krb5.keytab
        fi
}

test_password()
{
	tc_register "Incorrect password - bar"
	run -auth $principal $pam_krb5 $flags -- bar
	tc_fail_if_bad_rc $? || return
	grep -i "Authentication failure" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected Authentication Failure" || return
	
	tc_register "Incorrect password - foolong"
	run -auth $principal $pam_krb5 $flags -- foolong
	tc_fail_if_bad_rc $? || return
	grep -i "Authentication failure" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected Authentication Failure" || return

	tc_register "Correct password - foo"
	run -auth -setcred -session $principal $pam_krb5 $flags -- foo
	tc_fail_if_bad_rc $? || return
	N=`grep -i "Success" $stdout | wc -l`
	if [ $N -ne 5 ]
	then
		tc_fail "Expected to see 5 Success messages"
	else
		tc_pass
	fi

	tc_register "Correct password, incorrect first attempt"
	#echo Succeed: correct password, incorrect first attempt.
	run -auth -setcred $principal $pam_krb5 $flags use_first_pass -- foo
	tc_fail_if_bad_rc $? || return
	grep -i "Success" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected success" \
	"$(< $stdout)" || return

	#echo Succeed: correct password, maybe use incorrect second attempt.
	tc_register "incorrect second attempt"
	run -auth -session $principal $pam_krb5 $flags -authtok foo -- bar
	tc_fail_if_bad_rc $? || return
	grep -i "Success" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected success" \
	"$(< $stdout)" || return

	#echo "";echo Succeed: correct password, ignore second attempt.
	tc_register "Ignore second attempt"
	run -auth -setcred -session $principal $pam_krb5 $flags -authtok foo use_first_pass -- bar
	tc_fail_if_bad_rc $? || return
	grep -i "Success" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected success" \
	"$(< $stdout)" || return


}
test_expire()
{
	## Check for expired password detection (both right and wrong), and "nowarn".
	#echo "";echo Expiring password.
	tc_register "Incorrect password after expire"
	tc_info "Expiring password"
	kadmin.local -q 'cpw -pw foo '$principal 2>$stderr > /dev/null &&
	kadmin.local -q 'modprinc -pwexpire now '$principal 2>>$stderr > /dev/null
	tc_fail_if_bad_rc $? "Unable to expire the password" || return
	settle

	#echo "";echo Fail: incorrect password.
	kadmin.local -q 'cpw -pw foo '$principal 2>$stderr > /dev/null &&
	kadmin.local -q 'modprinc -pwexpire now '$principal 2>> $stderr > /dev/null
	tc_fail_if_bad_rc $? "Unable to expire the password" || return
	settle
	run -auth -account $principal $pam_krb5 $flags -- bar
	tc_fail_if_bad_rc $? || return
	grep -i "failure" $stdout &>/dev/null
	tc_pass_or_fail $? "Unexpected success" \
	"$(< $stdout)" || return

	#echo "";echo Succeed: correct password, warn about expiration.
	tc_register "Warning about expiration"
	kadmin.local -q 'cpw -pw foo '$principal 2>$stderr > /dev/null &&
	kadmin.local -q 'modprinc -pwexpire now '$principal 2>> $stderr > /dev/null
	tc_fail_if_bad_rc $? "Unable to set the options using kadmin.local" || return
	settle
	run -auth -account $principal $pam_krb5 $flags -- foo bar bar
	tc_fail_if_bad_rc $? || return
	grep -i "Warning: password has expired" $stdout &>/dev/null && grep -i "Success" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected a success with warning message" \
	"$(< $stdout)" || return


	tc_register "No Expiration warning"
	#echo "";echo Succeed: correct password, do not warn about expiration.
	kadmin.local -q 'cpw -pw foo '$principal 2>$stderr > /dev/null
	kadmin.local -q 'modprinc -pwexpire now '$principal 2>>$stderr > /dev/null
	tc_fail_if_bad_rc $? "Unable to set the options using kadmin.local" || return
	settle
	run -auth -account $principal $pam_krb5 $flags no_warn -- foo
	tc_fail_if_bad_rc $? || return
	grep -i "Warning: password has expired" $stdout&>/dev/null
	if [ $? -eq 0 ]; then
		tc_fail "Unexpected warning" \
		"$(< $stdout)" || return
	fi
	grep -i "Success" $stdout &>/dev/null
	tc_pass_or_fail $? "Unexpected failure" \
	"$(< $stdout)" || return
	
	#echo "";echo Succeed: correct password, expired, change.
	#Though the authentication should pass, the passwd changing should fail.
	tc_register "Prompt for password change"
	kadmin.local -q 'cpw -pw foo '$principal 2>$stderr  > /dev/null &&
	kadmin.local -q 'modprinc -pwexpire now '$principal 2>>$stderr > /dev/null
	tc_fail_if_bad_rc $? "Unable to set the options using kadmin.local" || return
	settle
	run -auth -account -chauthtok -setcred -session $principal $pam_krb5 $flags no_warn -- foo bar bar bar baz baz
	tc_fail_if_bad_rc $? || return
	#  We should get the following lines in o/p. The first two for authentication success, next for password change
	# AUTH NUM Success
	# ACCT NUM "Authentication token is no longer valid; new one required"
	# CHAUTHTOK1 NUM Authentication Failure
	# CHAUTHTOK2 NUM User not known to the underlying authentication module
	grep "^AUTH\>" $stdout | grep "Success" &>/dev/null  && 
		grep "^ACCT\>" $stdout | grep -i "Authentication token is no longer valid; new one required" &>/dev/null
	tc_fail_if_bad $? "Expected Success with prompt for new password" || return

	grep "^CHAUTHTOK1\>" $stdout | grep -i "Authentication failure" &>/dev/null &&
		grep "^CHAUTHTOK2" $stdout | grep -i "User not known to the underlying authentication module" &>/dev/null
	tc_pass_or_fail $? "Expected Authentication failure" || return
}

test_change_password()
{
	tc_register "change password"
	#echo "";echo Succeed.
	# Set password to foo
	kadmin.local -q 'cpw -pw foo '$principal 2>$stderr > /dev/null
	tc_fail_if_bad_rc $? "Unable to set the options using kadmin.local" || return
	# Try to change it to bar
	run -chauthtok $principal $pam_krb5 $flags -- foo bar bar
	tc_fail_if_bad_rc $? || return
	# Now we should see Success for CHAUTHTOK1 and CHAUTHTOK2
	rc=`grep "^CHAUTHTOK1\|^CHAUTHTOK2" $stdout | grep "Success" | wc -l`
	if [ $rc -ne 2 ] ; then
		tc_fail "Expected to see Success for CHAUTHTOK1 and CHAUTHTOK2" ||return
	else
		tc_pass
	fi
	
	tc_register "wrong initial password"
	#echo "";echo Fail: wrong initial password. 
	# Password is reset to foo
	kadmin.local -q 'cpw -pw foo '$principal 2> /dev/null > /dev/null
	# Now try to change it to "bar". But "Foo" is wrong password
	run -chauthtok $principal $pam_krb5 $flags -- Foo bar bar
	tc_fail_if_bad_rc $? || return
	grep "^CHAUTHTOK1" $stdout | grep "Authentication failure" &>/dev/null
	tc_pass_or_fail $? "Expected the Authentication failure for CHAUTHTOK1" \
	"$(< $stdout)" || return

	tc_register "mismatched new password"
	#echo "";echo Fail: mismatched new password. 
	# CHAUTHTOK1 passes. But CHAUTHTOK2 fails
	kadmin.local -q 'cpw -pw foo '$principal 2> /dev/null > /dev/null
	tc_fail_if_bad_rc $? "Unable to set the options using kadmin.local" || return
	run -chauthtok $principal $pam_krb5 $flags -- foo bar bAr
	tc_fail_if_bad_rc $? || return
	
	grep "^CHAUTHTOK1" $stdout | grep Success &>/dev/null &&
	 	grep "^CHAUTHTOK2" $stdout | grep "Failed preliminary check by password service" &>/dev/null
	tc_pass_or_fail $? "Expected failure for password mismatch" \
	"$(< $stdout)" || return

	tc_register "unacceptable password"
	#echo "";echo Fail: unacceptable password.
	kadmin.local -q 'cpw -pw foo '$principal 2> /dev/null > /dev/null
	kadmin.local -q 'modprinc -policy minimum_six '$principal 2> /dev/null > /dev/null
	run -chauthtok $principal $pam_krb5 $flags -- foo bar bar
	tc_fail_if_bad_rc $? || return
	kadmin.local -q 'modprinc -clearpolicy '$principal 2> /dev/null > /dev/null
	kadmin.local -q -f 'delprinc '$principal 2> /dev/null > /dev/null
	kadmin.local -q 'ank -pw foo '$principal 2> /dev/null > /dev/null
	grep "Authentication token manipulation error" $stdout&>/dev/null
	tc_pass_or_fail $? "Expected failure for short password" || return

	tc_register "use_authtok"
	kadmin.local -q 'cpw -pw foo '$principal 2> /dev/null > /dev/null
	run -chauthtok $principal -oldauthtok foo -authtok bar $pam_krb5 $flags use_authtok
	tc_fail_if_bad_rc $? || return
	rc=`grep "CHAUTHTOK" $stdout | grep "Success" | wc -l 2>/dev/null`
	if [ $rc -ne 2 ]; then
		tc_fail "Expected success" \
		"$(< $stdout)" || return
	else
		tc_pass
	fi
}

test_options()
{
	#echo "";echo Checking handling of options.
	kadmin.local -q 'cpw -pw foo '$principal 2> /dev/null > /dev/null
	
	tc_register "test FPI or FPRI option"
	#echo "";echo FPI or FPRI
	run -auth -setcred $principal -run klist_f $pam_krb5 $flags renewable proxiable forwardable -- foo
	tc_fail_if_bad_rc $? || return
	grep "\<FPI\>\|\<FPRI\>" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected to see one of FPI or FPRI in stdout" \
	"$(< $stdout)"
	
	sed -i "s/forwardable = true/forwardable = false/" $KRB5_CONFIG
        sed -i "s/proxiable = true/proxiable = false/" $KRB5_CONFIG
        sed -i "s/renew_lifetime=0/#renew_lifetime=0/" $KRB5_CONFIG

	tc_register "test I or RI option"
	#echo "";echo I or RI
	run -auth -setcred $principal -run klist_f $pam_krb5 $flags not_renewable not_proxiable not_forwardable -- foo
	tc_fail_if_bad_rc $? || return
	grep "\<I\>\|\<RI\>" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected to see one of I or RI in stdout" \
	"$(< $stdout)"

	tc_register "no address"
	kadmin.local -q 'cpw -pw foo '$principal 2> /dev/null > /dev/null
	#echo "";echo No addresses.
	run -auth -setcred $principal -run klist_a $pam_krb5 $flags renewable proxiable forwardable addressless -- foo
	tc_fail_if_bad_rc $? || return
	grep "(none)"  $stdout &>/dev/null 
	tc_pass_or_fail $? "Expected no addresses in o/p" \
	"$(< $stdout)"
	
	sed -i "s/noaddresses = true/noaddresses = false/" $KRB5_CONFIG
	#
	tc_register "local address"
	#echo "";echo With local addresses.
	run -auth -setcred $principal -run klist_a $pam_krb5 $flags renewable proxiable forwardable not_addressless -- foo
	tc_fail_if_bad_rc $? || return
	grep $HOSTIP $stdout &>/dev/null 
	tc_pass_or_fail $? "expected local address in o/p" \
	"$(< $stdout)"
	
	
	#echo "";echo With krb4 via krb524.
	tc_register "krb4 via krb524"
	if  tc_executes "krb524d" ; then
	run -auth -setcred $principal -run klist_4 $pam_krb5 $flags renewable proxiable forwardable not_addressless krb4_convert -- foo
	tc_fail_if_bad_rc $? || return
	grep "krbtgt.EXAMPLE.COM@EXAMPLE.COM" $stdout &>/dev/null
	tc_pass_or_fail $? "expected to see krbtgt.EXAMPLE.COM@EXAMPLE.COM in o/p" \
	"$(< $stdout)"
	else
	tc_conf 1 "Skipping test as krb524d is not supported in this build"
	fi
	
	#
	k524stop
	#echo "";echo With krb4 via kdc.
	tc_register "krb4 via kdc"
	if  tc_executes "krb524d" ; then
	run -auth -setcred $principal -run klist_4 $pam_krb5 $flags renewable proxiable forwardable not_addressless krb4_convert -- foo
	tc_fail_if_bad_rc $? || return
	grep "krbtgt.EXAMPLE.COM@EXAMPLE.COM" $stdout &>/dev/null
	tc_pass_or_fail $? "expected to see krbtgt.EXAMPLE.COM@EXAMPLE.COM in o/p" \
	"$(< $stdout)"
	else
	tc_conf 1 "Skipping test as krb524d is not supported in this build"
	fi
	k524start ; settle

	#
	#echo "";echo Renewable lifetime 0.
	tc_register "Renewable life time 0"
	run -auth -setcred $principal -run klist_t $pam_krb5 $flags proxiable forwardable not_addressless -- foo
	tc_fail_if_bad_rc $? || return
	grep "Valid starting" $stdout | grep "Expires" &>/dev/null
	tc_fail_if_bad $? "Expected to see Validity dates"
	grep "renew until" $stdout &>/dev/null
	if [ $? -eq 0 ]; then
		tc_fail 1 "Unexpected \"renew time\" information in o/p" \
			"$(< $stdout)"
	else
		tc_pass
	fi
	
	sed -i "s/#renew_lifetime=0/renew_lifetime=36000/" $KRB5_CONFIG
	#
	#echo "";echo Renewable lifetime 1 hour.
	tc_register "Renewable lifetime non-zero"
	run -auth -setcred $principal -run klist_t $pam_krb5 $flags proxiable forwardable not_addressless -- foo
	tc_fail_if_bad_rc $? || return
	grep "renew until"  $stdout &>/dev/null
	tc_pass_or_fail $? "Expected to see renew life time in o/p" \
	"$(< $stdout)"
	
	
	tc_register "Change Ccache dir"
	#echo "";echo Ccache directory = testdir/kdc.
	run -auth -setcred $principal -run klist_c $pam_krb5 $flags ccache_dir=${testdir}/kdc -- foo
	tc_fail_if_bad_rc $? || return
	grep "FILE:$testdir/kdc"  $stdout &>/dev/null
	tc_pass_or_fail $? "Expected $testdir/kdc as the Ccache dir" \
	"$(< $stdout)"
	
	
	#
	#echo "";echo Banner = K3RB3R05 S
	tc_register "Change banner"
	kadmin.local -q 'cpw -pw foo '$principal 2> /dev/null > /dev/null
	run -chauthtok $principal $pam_krb5 $flags banner="K3RB3R05 S" -- foo bar bar
	tc_fail_if_bad_rc $? || return
	grep "K3RB3R05 S" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected banner : K3RB3R05 S in o/p" \
	"$(< $stdout)" || return
	
	#
	#echo "";echo Password-change Help Text
	tc_register "Password-change Help Text"
	echo "Please change your password soon!" > $testdir/pwhelp.txt
	kadmin.local -q 'cpw -pw foo '$principal 2> /dev/null > /dev/null
	run -chauthtok $principal $pam_krb5 $flags pwhelp=$testdir/pwhelp.txt -- foo bar bar
	tc_fail_if_bad_rc $? || return
	grep "Please change your password soon!" $stdout &>/dev/null
	tc_pass_or_fail $? "Expected Password-change help text in o/p" \
	"$(< $stdout)" || return
	rm -f $testdir/pwhelp.txt

}
#

	
tc_setup

# First, a wrong password, then the right one, then a wrong one.


test_password &&
test_expire &&
test_change_password &&
test_options
