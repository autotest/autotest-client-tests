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
## File:		python-ldap.sh
##
## Description:	Test python-ldap package
##
## Author:	Athira Rajeev<atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TSTDIR=${LTPBIN%/shared}/python_ldap/Tests
REQUIRED="python"
TST_TOTAL=5

################################################################################
# testcase functions
################################################################################

function tc_local_setup()
{
      tc_check_package python-ldap
	tc_break_if_bad $? "python-ldap required, but not installed" || return 


	cp $TSTDIR/../sasl.py $TSTDIR/../slapd.conf $TSTDIR/../t_setupslapd.py $TSTDIR

	host_name=`hostname -f`
	set $host_name
	host_name=$1

	krb5kdc_cleanup=0
	kadmin_cleanup=0
	rngd_cleanup=0

	service krb5kdc status &> /dev/null
	[ $? -eq 0 ] && \
		krb5kdc_cleanup=1

	service kadmin status &> /dev/null
	[ $? -eq 0 ] && \
		kadmin_cleanup=1

	service rngd status &> /dev/null
	[ $? -eq 0 ] && \
		rngd_cleanup=1

	# Backup krb5 conf files
	cp -r /etc/krb5.conf /etc/krb5.conf.org
	cp -r /var/kerberos/krb5kdc/kdc.conf /var/kerberos/krb5kdc/kdc.conf.org
	cp $TSTDIR/sasl.py $TSTDIR/sasl.py.org

	sed -i "s:127.0.0.1:$host_name:g" $TSTDIR/sasl.py

	# Script to create realm TEST.COM
	cat >> $TCTMP/krb5.sh <<-EOF
	#!/usr/bin/expect -f
	set timeout 5
	proc abort {} { exit 1 }
	spawn kdb5_util create -r TEST.COM -s -W
	expect "*key:*"
	send -- "password\r"
	expect "*key to verify:*"
	send -- "password\r"
	expect eof
	EOF

	# Scripts to add Principals for ldap
	# to KDC database
	cat >> $TCTMP/kadmin.sh <<-EOF
	#!/usr/bin/expect -f
	set timeout 5
	proc abort {} { exit 1 }
	spawn kadmin.local
	expect "kadmin.local:"
	send -- "addprinc admin\r"
	expect "Enter password for principal \"admin@TEST.COM\":"
	send -- "password\r"
	expect "*password for principal \"admin@TEST.COM\":"
	send -- "password\r"
	expect "kadmin.local:"
	send -- "addprinc -randkey host/$host_name\r"
	expect "kadmin.local:"
	send -- "ktadd host/$host_name\r"
	expect "kadmin.local:"
	send -- "addprinc -randkey ldap/$host_name\r"
	expect "kadmin.local:"
	send -- "ktadd ldap/$host_name\r"
	expect "kadmin.local:"
	send -- "addprinc ldap\r"
	expect "Enter password for principal \"ldap@TEST.COM\":"
	send -- "password\r"
	expect "*password for principal \"ldap@TEST.COM\":"
	send -- "password\r"
	expect "kadmin.local:"
	send -- "exit"
	expect eof
	EOF

	chmod +x $TCTMP/krb5.sh $TCTMP/kadmin.sh

	tc_exec_or_break $REQUIRED || return

}

function tc_local_cleanup()
{
	# Restore the krb5 configuration files
	mv /etc/krb5.conf.org /etc/krb5.conf
	mv /var/kerberos/krb5kdc/kdc.conf.org /var/kerberos/krb5kdc/kdc.conf
	mv $TSTDIR/sasl.py.org $TSTDIR/sasl.py

	# restart krb5kdc and kadmin
	# after restore of configuration files
	service krb5kdc restart &>$stdout
	service kadmin restart &>$stdout

	# REstore the status of krb5kdc and kadmin
	if [ $krb5kdc_cleanup -eq 0 ]; then
		service krb5kdc stop &>$stdout
		tc_break_if_bad $? "failed to stop krb5kdc"
	fi

	if [ $kadmin_cleanup -eq 0 ]; then
		service kadmin stop &>$stdout
		tc_break_if_bad $? "failed to stop kadmin"
	fi

	if [ $rngd_cleanup -eq 0 ]; then
		service rngd stop &>$stdout
		tc_break_if_bad $? "failed to stop rngd"
	fi

	# Remove the ldap directory
	rm -rf /var/tmp/python-ldap-test/

	# Kill the running slapd process
	pid=`ps ax|grep slapd | grep -v grep | awk '{ print $1}'`
	kill $pid
}

# Function:		runtest
# 		This executes tests that comes with source
function runtest()
{
	# Create one ldap directory
	# where the ldap files will be generated like ldif schema
	mkdir /var/tmp/python-ldap-test/

	sed -i 's:/etc/ldap/schema/core.schema:/etc/openldap/schema/core.schema:g' $TSTDIR/slapd.py

	# Excluding execution of runtest due to bug 127316
	#tc_register "python-ldap test"
	#pushd $TSTDIR 2>$stderr
	#$TSTDIR/runtests.sh
	#tc_pass_or_fail $? "python-ldap test"
	#popd 2>$stderr
}

# Function	ldap_test
#		This covers tests for other ldap modules
#		like ldap.async, resiter, sasl
function ldap_test()
{
	#Setup slapd with cn=Manager,dc=python-ldap,dc=org
	# cn=Foo1 and cn=Foo2
	python $TSTDIR/t_setupslapd.py &>$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to add entries to ldap database" || return
	
	# Start ldap server on ldap://127.0.0.1
	cp -r $TSTDIR/slapd.conf /var/tmp/python-ldap-test/
	
	/usr/sbin/slapd -f /var/tmp/python-ldap-test/slapd.conf -h ldap://localhost &>$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to start slapd on ldap://127.0.0.1" || return

	# Start ldap server on ldap://127.0.0.1:1390
	/usr/sbin/slapd -f /var/tmp/python-ldap-test/slapd.conf -h ldap://localhost:1390 &>$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to start slapd on ldap://127.0.0.1:1390" || return

	#start ldap server on ldaps://localhost:1391
	/usr/sbin/slapd -f /var/tmp/python-ldap-test/slapd.conf -h ldaps://localhost:1391 &>$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to start slapd on ldaps://localhost:1391" || return

	#start ldap server on ldap://host_name
	/usr/sbin/slapd -f /var/tmp/python-ldap-test/slapd.conf -h ldap://$host_name &>$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to start slapd on ldap://host_name" || return

	# start ldap server domain socket /tmp/openldap-socket
	/usr/sbin/slapd -f /var/tmp/python-ldap-test/slapd.conf -h ldapi://%2ftmp%2fopenldap-socket &>$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to start slapd on ldapi://%2ftmp%2fopenldap-socket" || return

	tc_register "ldap connection over domain socket"
	python $TSTDIR/initialize.py &>$stdout 2>$stderr
	rc=$?
	sed -i 's:0x[0-9,a-z]*:0x:g' $stderr
	cmp $TSTDIR/../stderr_exp $stderr && cat /dev/null > $stderr
	tc_pass_or_fail $rc "Failed ldap connection over domain socket"

	tc_register "Using ldap.control for matching value for attribute ObjectClass"
	python $TSTDIR/matchedvalues.py &>$stdout
	grep -q "dc=python-ldap,dc=org" $stdout 2>$stderr
	tc_pass_or_fail $? "ldap.control failed to list matched value for attribute ObjectClass"

	tc_register "Test for resiter module"
	python $TSTDIR/resiter.py &>$stdout
	grep -q "cn=Manager,dc=python-ldap,dc=org" $stdout
	tc_pass_or_fail $? "Test for resiter module module"

	tc_register "Test for ldap.async"
	python $TSTDIR/ldifwriter.py &>$stdout
	grep -q "dn: cn=Foo1,dc=python-ldap,dc=org" $stdout 2>$stderr
	tc_pass_or_fail $? "Test for ldap.async module"

	tc_register "Test for ldap sasl module"

      tc_check_package python-ldap
	tc_fail_if_bad $? "krb5-server not present for SASL GSSAPI" || return

	# Start rngd to create entropy
	service rngd restart &>$stdout
	tc_fail_if_bad $? "Failed to start rngd" || return

	$TCTMP/krb5.sh &>$stdout
	tc_fail_if_bad $? "Failed to create TEST.COM realm" || return

	sed -i '/^#.* kdc /s/^#//' /etc/krb5.conf
	sed -i '/^#.* admin_server /s/^#//' /etc/krb5.conf
	sed -i '/^#.* EXAMPLE.COM /s/^#//' /etc/krb5.conf
	sed -i '/^# }/s/^#//' /etc/krb5.conf
	sed -i '/^# default_realm/s/^#//' /etc/krb5.conf
	sed -i 's:EXAMPLE.COM:TEST.COM:g' /var/kerberos/krb5kdc/kdc.conf
	sed -i "s/kdc = kerberos.example.com/kdc = $host_name:88/g" /etc/krb5.conf
	sed -i "s/admin_server = kerberos.example.com/admin_server = $host_name:749/g" /etc/krb5.conf
	sed -i 's:EXAMPLE.COM:TEST.COM:g' /etc/krb5.conf

	$TCTMP/kadmin.sh &>$stdout
	tc_fail_if_bad $? "Failed to create principal for KDC database" || return

	service krb5kdc restart &>$stdout
	tc_fail_if_bad $? "Failed to start krb5kdc" || return

	service kadmin restart &>$stdout
	tc_fail_if_bad $? "Failed to start kadmin" || return

	kinit -k -t /etc/krb5.keytab ldap/$host_name@TEST.COM &>$stdout
	tc_fail_if_bad $? "Failed to create krb5 credentials" || return

	python $TSTDIR/sasl.py &>$stdout
	grep -q "cn=Foo1,dc=python-ldap,dc=org" $stdout && grep "cn=Foo2,dc=python-ldap,dc=org" $stdout
	tc_pass_or_fail $? "Test for ldap sasl failed"
		
}	
####################################################################################
# MAIN
####################################################################################

# Function:	main
#
tc_setup
runtest
ldap_test
