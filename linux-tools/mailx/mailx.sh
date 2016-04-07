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
## File :        mailx.sh
##
## Description:  Tests basic functions of mail system.
##
## Author:       Robert Paulsen
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

IPV6=""

################################################################################
# local utility functions
################################################################################

#   
# Local setup
#
tc_local_setup()
{
    tc_root_or_break || exit
    tc_exec_or_break grep || exit
    rpm -q "sendmail" >$stdout 2>$stderr
    tc_break_if_bad $? "sendmail package is not installed"
    tc_add_user_or_break || return # sets TC_TEMP_USER
   
    rpm -q "postfix" &> /dev/null 
    if [ $? -eq 0 ]; then
	#check status of postfix and stop if its already running
        # so as to free port 25 for sendmail
	tc_service_status postfix
	if [ $? -eq 0 ]; then
		postfix_cleanup=1
		tc_service_stop_and_wait postfix
	fi
	
    fi

    tc_service_stop_and_wait sendmail

    tc_ipv6_info && {
	IPV6=yes
    	save_sendmailcfgs


	[ "$TC_IPV6_host_ADDRS" ] && {
		echo "[IPV6:$TC_IPV6_host_ADDRS]"   >> /etc/mail/local-host-names
		echo "$TC_IPV6_host_ADDRS   RELAY" >> /etc/mail/access
	}
        [ "$TC_IPV6_link_ADDRS" ] && {
		echo "[IPV6:$TC_IPV6_link_ADDRS]"   >> /etc/mail/local-host-names
        	echo "$TC_IPV6_link_ADDRS   RELAY" >> /etc/mail/access
	}
        [ "$TC_IPV6_global_ADDRS" ] && {
		echo "[IPV6:$TC_IPV6_global_ADDRS]" >> /etc/mail/local-host-names
		echo "$TC_IPV6_global_ADDRS RELAY" >> /etc/mail/access
	}
	
	mv /etc/mail/access.db /etc/mail/access.db.old
	make access.db -C /etc/mail >$stdout 2>$stderr
	tc_break_if_bad $? "Could not configure sendmail" || return
    }

    tc_service_start_and_wait sendmail

    content="Hello Sailor!"
    echo "$content" > $TCTMP/content.txt
}

#   
# Local cleanup
#   
tc_local_cleanup()
{
    restore_sendmailcfgs
    mv /etc/mail/access.db.old /etc/mail/access.db
    # Restore status of postfix prior to test execution
    if [ $postfix_cleanup ]; then
	tc_service_stop_and_wait sendmail 
	tc_service_start_and_wait postfix
    fi
    echo 'd*' | mail &>/dev/null
}

#   
# Save mail configs
#   
save_sendmailcfgs()
{
        [ -e /etc/mail/access ]           && cp /etc/mail/access  /etc/mail/access.testsave$$
        [ -e /etc/mail/local-host-names ] && cp /etc/mail/local-host-names  /etc/mail/local-host-names.testsave$$
}

#   
# Restore mail configs
#   
restore_sendmailcfgs()
{
        [ -e /etc/mail/access.testsave$$ ]           && mv /etc/mail/access.testsave$$  /etc/mail/access
        [ -e /etc/mail/local-host-names.testsave$$ ] && cp /etc/mail/local-host-names.testsave$$  /etc/mail/local-host-names
}

################################################################################
# test functions
################################################################################

#
# installation check
#
test01()
{
    tc_register "installation check"

    tc_executes mail mailx 
    tc_pass_or_fail $? "mailx not properly installed"
}

#
# mail to/from root
#	$1 must be valid host name or IP
#
test02()
{
    [ $# -eq 1 ] 
    tc_break_if_bad $? "Internal testcase error wrong number of args to $FUNCNAME" || exit
    local destination=$1	

    tc_register    "mail to root@$destination is delivered"

    tc_wait_for_no_mail root
    tc_fail_if_bad $? "Could not delete old mail for root" || return

    mail -s "Test simple mail" root@$destination < $TCTMP/content.txt 2>$stderr 1>$stdout
    tc_fail_if_bad $? "unable to send email to root@$destination" || return

    cat /dev/null > $stdout
    local n=3
    while ((--n>0)) ; do
        tc_wait_for_mail root
        tc_fail_if_bad $? "email to root@$destination was not received" || return
        tc_wait_for_mail_text root "$content" && break
    done
    ((n>0))
    tc_pass_or_fail $? "email to root@$destination was received but data miscompared" \
                       "expected to see $content in stdout"

}

#
# mail to bad host gets undelivered report
#	$1 must be invalid host name or IP
#
test03()
{
    [ $# -eq 1 ] 
    tc_break_if_bad $? "Internal testcase error wrong number of args to $FUNCNAME" || exit
    local destination=$1	

    tc_register    "mail to root@$destination gets undelivered report (550 host unknown)"

    tc_wait_for_no_mail root
    tc_fail_if_bad $? "Could not delete old mail for root" || return

    mail -s "Test bad host" root@$destination < $TCTMP/content.txt 2>$stderr 1>$stdout
    tc_fail_if_bad $? "failed to attempt sending" || return

    cat /dev/null > $stdout
    local n=3
    while ((--n)) ; do
    	# wait for 5sec as the error report may delay from mail daemon bug 118943
    	sleep 5
        tc_wait_for_mail root
        tc_fail_if_bad $? "no error report received from mail daemon" || return
        tc_wait_for_mail_text root '550.*host unknown' && break
    done
    ((n>0))
    tc_pass_or_fail $? "received mail but it wasn't an unknown host report"

    # May get two responses so we wait for second but don't care if it doesn't come
    tc_wait_for_mail root 10
    tc_wait_for_no_mail root
    return 0
}

#
# mail to nonexistent user gets undelivered report
#	$1 must be valid host name or IP
#
test04()
{
    [ $# -eq 1 ]
    tc_break_if_bad $? "Internal testcase error wrong number of args to $FUNCNAME" || exit
    local destination=$1
    user=bad_user
    tc_register    "mail to $user@$destination gets undelivered report (550 user unknown)"

    tc_wait_for_no_mail root
    tc_fail_if_bad $? "Could not delete old mail for root" || return

    mail -s "Test bad user" $user@$destination < $TCTMP/content.txt 2>$stderr 1>$stdout
    tc_fail_if_bad $? "failed sending email to $user@$destination" || return

    cat /dev/null > $stdout
    local n=3
    while ((--n)) ; do
        tc_wait_for_mail root
        tc_fail_if_bad $? "no error report received from mail daemon" || return
        tc_wait_for_mail_text root '550.*user unknown' && break
    done
    ((n>0))
    tc_pass_or_fail $? "received mail but it wasn't an unknown user report"
}

#
# carbon copy
#	$1 must be valid host name or IP
#
test05()
{
    [ $# -eq 1 ]
    tc_break_if_bad $? "Internal testcase error wrong number of args to $FUNCNAME" || exit
    local destination=$1
    tc_register    "mail to root@$destination CC user $TC_TEMP_USER"

    tc_wait_for_no_mail root
    tc_fail_if_bad $? "Could not delete old mail for root" || return

    tc_wait_for_no_mail $TC_TEMP_USER
    tc_fail_if_bad $? "Could not delete old mail for $TC_TEMP_USER" || return

    mail -c $TC_TEMP_USER -s "Test CC" root@$destination < $TCTMP/content.txt 2>$stderr 1>$stdout
    tc_fail_if_bad $? "unable to send email to root@$destination" || return

    cat /dev/null > $stdout
    local n=3
    while ((--n)) ; do
        tc_wait_for_mail root
        tc_fail_if_bad $? "email to root@$destination was not received" 
        tc_wait_for_mail_text root "$content" && break
    done
    ((n>0))
    tc_fail_if_bad $? "email to root@$destination was received but data miscompared" \
                       "expected to see $content in stdout"

    cat /dev/null > $stdout
    local n=3
    while ((--n)) ; do
        tc_wait_for_mail $TC_TEMP_USER
        tc_fail_if_bad $? "CC to $TC_TEMP_USER@$destination was not received" 
        tc_wait_for_mail_text $TC_TEMP_USER "$content" && break
    done
    ((n>0))
    tc_pass_or_fail $? "CC to $TC_TEMP_USER@$destination was received but data miscompared" \
                       "expected to see $content in stdout"
}

#
# blind carbon copy
#	$1 must be valid host name or IP
#
test06()
{
    [ $# -eq 1 ]
    tc_break_if_bad $? "Internal testcase error wrong number of args to $FUNCNAME" || exit
    local destination=$1
    tc_register    "mail to root@$destination BCC user $TC_TEMP_USER"

    tc_wait_for_no_mail root
    tc_fail_if_bad $? "Could not delete old mail for root" || return

    mail -s "Test BCC" -b root@$destination $TC_TEMP_USER@$destination < $TCTMP/content.txt 2>$stderr 1>$stdout
    tc_fail_if_bad $? "unable to send email to $TC_TEMP_USER@$destination" || return

    cat /dev/null > $stdout
    local n=3
    while ((--n)) ; do
        tc_wait_for_mail root
        tc_fail_if_bad $? "email to root@$destination was not received" 
        tc_wait_for_mail_text root "$content" && break
    done
    ((n>0))
    tc_fail_if_bad $? "email to root@$destination was received but data miscompared" \
                       "expected to see $content in stdout"

    cat /dev/null > $stdout
    local n=3
    while ((--n)) ; do
        tc_wait_for_mail $TC_TEMP_USER
        tc_fail_if_bad $? "BCC to $TC_TEMP_USER@$destination was not received" 
        tc_wait_for_mail_text $TC_TEMP_USER "$content" && break
    done
    ((n>0))
    tc_pass_or_fail $? "BCC to $TC_TEMP_USER@$destination was received but data miscompared" \
                       "expected to see $content in stdout"
}

#
# main
#
TST_TOTAL=6

tc_run_me_only_once	# exits if test was already run by the scenario file.

tc_setup

test01

test03 "bad_host" &&

tc_info "IPv4 localhost tests"
test02 "localhost" &&
test04 "localhost" &&
test05 "localhost" &&
test06 "localhost"

my_hostname=$(hostname)
[ "$my_hostname" ] && {
	((TST_TOTAL+=4))
	tc_info "IPv4 $my_hostname tests"
	test02 $my_hostname &&
	test04 $my_hostname &&
	test05 $my_hostname &&
	test06 $my_hostname
}

[ "$IPV6" = "yes" ] && {
	[ "$TC_IPV6_host_ADDRS" ] && {
		((TST_TOTAL+=4))
		tc_info "IPv6 local addr tests"
		test02 "[IPv6:$TC_IPV6_host_ADDRS]" &&
		test04 "[IPv6:$TC_IPV6_host_ADDRS]" && 
		test05 "[IPv6:$TC_IPV6_host_ADDRS]" && 
		test06 "[IPv6:$TC_IPV6_host_ADDRS]"
	}
	[ "$TC_IPV6_link_ADDRS" ] && {
		((TST_TOTAL+=4))
		tc_info "IPv6 link addr tests"
		test02 "[IPv6:$TC_IPV6_link_ADDRS]" &&
		test04 "[IPv6:$TC_IPV6_link_ADDRS]" && 
		test05 "[IPv6:$TC_IPV6_link_ADDRS]" && 
		test06 "[IPv6:$TC_IPV6_link_ADDRS]"
	}
	[ "$TC_IPV6_global_ADDRS" ] && {
		((TST_TOTAL+=4))
		tc_info "IPv6 global addr tests"
		test02 "[IPv6:$TC_IPV6_global_ADDRS]" &&
		test04 "[IPv6:$TC_IPV6_global_ADDRS]" && 
		test05 "[IPv6:$TC_IPV6_global_ADDRS]" && 
		test06 "[IPv6:$TC_IPV6_global_ADDRS]" 
	}
}
 
