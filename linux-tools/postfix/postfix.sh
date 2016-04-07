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
### File : postfix.sh                                                          ##
##
### Description: This testcase tests the postfix package                       ##
##
### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
POSTFIX_TESTS_DIR="${LTPBIN%/shared}/postfix"
REQUIRED="postalias postcat postconf postdrop postfix postkick postlock postlog postmap\
          postmulti postqueue postsuper expect"
SENDMAIL_STAT="/etc/init.d/sendmail status"
SENDMAIL_START="/etc/init.d/sendmail start"
SENDMAIL_STOP="/etc/init.d/sendmail stop"

# keep track of things that might need to be cleaned up in "tc_local_cleanup"
needsmail_stop=""
needsmail_start="no"
needpostfix_stop="no"
needpostfix_start="no"

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED 

	# remember to start senmail in cleanup if it was running upon entry
	$SENDMAIL_STAT &>/dev/null && needsmail_start="yes"
	sleep 2
	#stop sendmail if it was running
	[ "$needsmail_start" == "yes" ] && $SENDMAIL_STOP &>/dev/null

	#start postfix if it was not running
	(service postfix status &>/dev/null && needpostfix_start="no" ) || needpostfix_start="yes"

	#If postfix was stopped before this testcase, then stop postfix 
	#in tc_local_cleanup
	[ "$needpostfix_start" == "yes" ] && needpostfix_stop="yes"
	
	# Start postfix if it was not running
	( [ "$needpostfix_start" == "yes" ] && service postfix start ) || [ "$needpostfix_start" == "no" ] &>/dev/null
	tc_fail_if_bad $? "Failed to start postfix" || return

	tc_add_user_or_break testuser1 || return
	tc_add_user_or_break testuser2 || return
	cp /etc/aliases /etc/aliases.orig
}

function tc_local_cleanup()
{
	# start sendmail if it was running before this testcase started
	[ "$needsmail_start" = "yes" ] && $SENDMAIL_START &>/dev/null

	# stop this testcase instance of postfix
	[ "$needpostfix_stop" = "yes" ] && service postfix stop &>/dev/null

	mv -f /etc/aliases.orig /etc/aliases
}

function run_test()
{
	pushd $POSTFIX_TESTS_DIR >$stdout 2>$stderr

	tc_register "Test postfix mail delivery"
	user="testuser1@localhost"
	./deliver_mail.exp $user >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to deliver mail"
	tc_info "Check the deliverd mail"
	echo 1 | su - testuser1 -c mail | grep "This is a Test Mail" >$stdout 2>$stderr
	tc_pass_or_fail $? "Postfix mail delivery failed"

	tc_register "Test postalias"
	user="tt"
	echo "tt:testuser2@localhost" >> /etc/aliases
	postalias /etc/aliases >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to run postalias"
	./deliver_mail.exp $user >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to deliver mail"
	tc_info "Check the deliverd mail"
	echo 1 | su - testuser2 -c mail | grep "This is a Test Mail" >$stdout 2>$stderr
	tc_pass_or_fail $? "Postfix mail delivery through postalias failed"

	tc_register "Test postlog"
	# Bug - 122931 rsyslog is not enabled on zkvm, so check and start
        tc_service_status rsyslog || tc_service_start_and_wait rsyslog
        ## This command allows an external program to write to the mail log
	# Anything written after the postlog command will be written to the maillog file
	postlog testing this command >$stdout 2>$stderr
	cat /var/log/maillog | grep testing >$stdout 2>$stderr
	tc_pass_or_fail $? "postlog command could not write to the maillog file"

	tc_register "Test postconf"
	postconf | grep smtpd >$stdout 2>$stderr
	tc_pass_or_fail $? "postconf command failed to display the postfix parameters"

	popd >$stdout 2>$stderr	
	

}

#
# main
#
TST_TOTAL=4
tc_setup
run_test 
