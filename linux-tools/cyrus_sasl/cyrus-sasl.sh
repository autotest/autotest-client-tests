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
##########################################################################################
#
# File :	cyrus_sasl.sh
#
# Description:	Check that cyrus-sasl2 can manage users, domains, passwords.
#
# Author:	Jue Xie, xiejue@cn.ibm.com	
#		Robert Paulsen, rpaulsen@us.ibm.com
#
############################################################################################
# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/cyrus_sasl
source $LTPBIN/tc_utils.source
MYDIR=${LTPBIN%/shared}/cyrus_sasl

# global variables used by all tests
test_user="sasluser$$"
test_pass="saslpass$$"
test_app="saslapp$$"
test_domain="sasldomain$$"

# Environment variables:    SASL_SERVER, SASL_USER, SASL_PASS
# SASL_SERVER is running authentication server on port 12345,
# it also act as kerberos kdc and kadmin server, see test environment setup document


#changeme: pass by environment
SASL_SERVER=10.0.0.1
SASL_USER=rende
SASL_PASS=password

function tc_local_setup()
{
	[ -n "$SASL_SERVER" -a -n "$SASL_USER" -a -n "$SASL_PASS" ]
	tc_break_if_bad $? "required environment variables not set" || return 

	if [ "$MECH" == "GSSAPI" ] ; then
        	# copy configuration files from the server and setup user credentials.
		[ -e /etc/krb5.conf ] && mv /etc/krb5.conf $TCTMP/
		scp $SASL_SERVER:/etc/krb5.conf /etc &>/dev/null
	
		tc_executes kinit || exit
		echo "$SASL_PASS" | kinit "$SASL_USER" &>/dev/null # get the right credential
	fi

	return 0
}

function tc_local_cleanup()
{
	if [ "$MECH" == "GSSAPI" ] ; then
		# restore original config file
		[ -e $TCTMP/krb5.conf ] && mv $TCTMP/krb5.conf /etc
		kdestroy >/dev/null 2>&1 # clean up the credential
	fi
}

################################################################################
# the testcase functions
################################################################################

#
# test01	check that cyrus-sasl2 is installed 
#
function test01()
{
	tc_register "cyrus-sasl installation check"
	
        installed_commands="sasldblistusers2 saslpasswd2"
	tc_executes $installed_commands 
        tc_pass_or_fail $? "cyrus-sasl not installed properly" || return
}

#
# test02	create a cyrus-sasl2 user
#
function test02()
{
	tc_register "create cyrus-sasl user"

	echo $test_pass | saslpasswd2 -a $test_app -p -c -u $test_domain $test_user >$stdout 2>$stderr
	tc_pass_or_fail $? "failed to add sasl user"
}

#
# test03	list the cyrus-sasl2 user
#
function test03()
{
	tc_register "list the cyrus-sasl2 user"
	sasldblistusers2 2>$stderr >$stdout
	tc_fail_if_bad $? "Bad response from sasldblistusers2" || return
	cat $stdout | grep $test_user >/dev/null
	tc_pass_or_fail $? "sasldblistusres2 didn't list sasl user $test_user"
}

#
# test04	can not delete user without specifying the domain name
#
function test04()
{
	tc_register "user can not be deleted w/o domain"
	saslpasswd2 -d $test_user >$stdout 2>&1    # stderr expected
	[ $? -ne 0 ]	# bad response expected
	tc_fail_if_bad $? "unexpected response from \"saslpasswd2 -d user\"" || return
	cat $stdout | grep "user not found" >/dev/null
	tc_pass_or_fail $? "expected to see \"user not found\" in stdout"
}

#
# test05	delete the user with domain name specified
#
function test05()
{
	tc_register "user can be deleted w/domain"
	saslpasswd2 -u $test_domain -d $test_user 2>$stderr >$stdout
	tc_pass_or_fail $? "bad response from \"saslpasswd2 -u domain -d user\""
}

#
# test06	the deleted user should not show in list of users
#
function test06()
{
	tc_register "the deleted user should not exist"
	sasldblistusers2 | grep -q $test_user
	[ $? -ne 0 ]
	tc_pass_or_fail $? "the deleted user still exists in the list"
}

#
# test07        test the saslauthd service script
#
function test07()
{
        tc_register "test the saslauthd service script"


        servrunning=0
	tc_service_status saslauthd && {
            servrunning=1
	    tc_service_stop_and_wait saslauthd
        }

	tc_service_start_and_wait saslauthd
	[ $servrunning -eq 0 ] && tc_service_stop_and_wait saslauthd

	return 0

}

#
# test08	test the saslauthd authentication server	
#
function test08()
{
	tc_register "test the saslauthd service"

	local password="password"
	# add new user with password set to "password"
	tc_add_user_or_break &>/dev/null || return 

	servrunning=0
	tc_service_status saslauthd && {
	    servrunning=1
	    tc_service_stop_and_wait saslauthd
	}

	# the default sock path is /var/run/sasl2, we override it explicitly for testing
	saslauthd -a shadow -m $TCTMP
	sleep 5   # wait the server to be ready

	# give a wrong password to saslauthd, expect authentication failure 
	/usr/sbin/testsaslauthd -u $temp_user -p "x$password" -f $TCTMP/mux >$stdout 2>$stderr
	[ $? -ne 0 ]
	tc_fail_if_bad $? "expecting failure but pass" || return

	# give a right password, expect authentication success 
	/usr/sbin/testsaslauthd -u $temp_user -p $password -f $TCTMP/mux >$stdout 2>$stderr
	tc_pass_or_fail $? "expecting success but failure"

	killall -q saslauthd
	[ $servrunning -eq 1 ] && tc_service_start_and_wait saslauthd
	tc_del_user_or_break &>/dev/null 
	
	return 0
}

# Parameter: mech
# Teset cyrus-sasl plugins
function test_plugin()
{
	local mymech=$1;

	if [ $mymech == "ANONYMOUS" -o $mymech == "GSSAPI" ] ; then
		step1=0; step2=1; step3=0;
	elif [ $mymech == "LOGIN" -o $mymech == "CRAM-MD5" ] ; then
		step1=1; step2=0; step3=1;
	else  # i.e. DIGEST-MD5, PLAIN, OTP
		step1=1; step2=1; step3=1;
	fi

	tc_register "test sasl plugin $mymech"

	expcmd=`which expect` 
	cat > $TCTMP/exp$$ <<-EOF
	#!$expcmd -f
	set timeout 5
	proc abort {n} { exit \$n }
	spawn /usr/bin/sasl2-sample-client -m $mymech $SASL_SERVER

	if { $step1 } {
	expect {
		timeout { abort 1 }
		"authentication id:" { send "$SASL_USER\r" }
	} 
	}

	if { $step2 } {
	expect {
		timeout { abort 2 }
		"authorization id:" { send "$SASL_USER\r" }
	}
	}

	if { $step3 } {
	expect {
		timeout { abort 3 }
		"Password:" { send "$SASL_PASS\r" }
	}
	}

	sleep 2
	expect {
		timeout { abort 4 }
		"successful authentication" { exit 0 }
	}
	exit 1
	EOF

	chmod a+x $TCTMP/exp$$
	cp $TCTMP/exp$$ /home/test$$
	$TCTMP/exp$$ >$stdout 2>$stderr
	tc_pass_or_fail $? "authentication failed via plugin $mymech"

	return 0
}

# Test the function of cyrus-sasl 
function test_sasl()
{
	# basic test
	# Two plugins(ANONYMOUS and LOGIN) are provided in the base package cyrus-sasl, 
        # test them too.

	# test01 && test02 && test03 && test04 && test05 && test06 && test07 && test08 &&
	test01 && test02 && test03 && test04 && test05 && test06 &&
	test_plugin ANONYMOUS &&
	test_plugin LOGIN
}


################################################################################
# main
################################################################################

MECH=$1
tc_setup	# standard tc_setup

tc_root_or_break || exit
tc_exec_or_break grep expect || exit

if [ $# -eq 0 ] ; then
	test_sasl
elif [ $# -eq 1 ]; then
	test_plugin $1
else 
	tc_break_if_bad $? "Usage error: $0 <mech>"
fi
