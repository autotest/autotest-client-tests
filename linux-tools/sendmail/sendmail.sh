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
## File :        sendmail.sh
##
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

## source the utility functions
## Author: Athira Rajeev
###########################################################################################


MSG_DIR=/var/spool/mail

################################################################################
# local utility function
################################################################################

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break grep cat || return
		
	tc_add_user_or_break || return # sets TC_TEMP_USER
	USER1=$TC_TEMP_USER
	tc_add_user_or_break || return # sets TC_TEMP_USER
	USER2=$TC_TEMP_USER
	# stop sendmail
	systemctl stop sendmail
	tc_wait_for_inactive_port 25
	tc_fail_if_bad $? "could not stop sendmail" || return
	
	save_sendmailcfgs

	# start sendmail
	systemctl start sendmail
	tc_break_if_bad $? "could not start sendmail" || return

	tc_wait_for_active_port 25
        tc_break_if_bad $? "sendmail did not bind to port 25"

	content="TEST MAIL"
	echo "$content" > $TCTMP/content.txt
}
#
# Local cleanup
#
tc_local_cleanup()
{
	restore_sendmailcfgs
	rm -rf $TCTMP/content.txt
	systemctl restart sendmail &>/dev/null
}

#
# Save mail configs
#
save_sendmailcfgs()
{
	[ -e /usr/lib/systemd/system/sendmail.service ] && cp /usr/lib/systemd/system/sendmail.service /usr/lib/systemd/system/sendmail.service.testsave$$
	[ -e /etc/mail/access ] && cp /etc/mail/access  /etc/mail/access.testsave$$
	[ -e /etc/mail/local-host-names ] && cp /etc/mail/local-host-names  /etc/mail/local-host-names.testsave$$
	[ -e /etc/mail/virtusertable ] && cp /etc/mail/virtusertable /etc/mail/virtusertable.testsave$$
	[ -e /etc/aliases ] && cp /etc/aliases /etc/aliases.testsave$$
}

#
# Restore mail configs
#
restore_sendmailcfgs()
{
	[ -e /usr/lib/systemd/system/sendmail.service.testsave$$ ] && mv /usr/lib/systemd/system/sendmail.service.testsave$$ /usr/lib/systemd/system/sendmail.service
	[ -e /etc/mail/access.testsave$$ ] && mv /etc/mail/access.testsave$$  /etc/mail/access
	[ -e /etc/mail/local-host-names.testsave$$ ] && mv /etc/mail/local-host-names.testsave$$  /etc/mail/local-host-names
	[ -e /etc/mail/virtusertable.testsave$$ ] && mv /etc/mail/virtusertable.testsave$$ /etc/mail/virtusertable
	[ -e /etc/aliases.testsave$$ ] && mv /etc/aliases.testsave$$ /etc/aliases
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

	tc_executes sendmail
	tc_pass_or_fail $? "sendmail not properly installed"
}

#
# adding one entry in local-host-names
#
test02()
{
	tc_register "Mail to $USER1@mydomain.com delivered"
	echo "mydomain.com" >> /etc/mail/local-host-names

	systemctl restart sendmail &>/dev/null

	# Mail from USER2 to USER1@mydomain.com
	sendmail -f"$USER2" $USER1@mydomain.com < $TCTMP/content.txt
	tc_fail_if_bad $? "Failed to sendmail to $USER1@mydomain.com" || return

	# Add sleep for mail in mailbox
	# Check for mail content in /var/spool/mail/user
	sleep 2
	grep -q -f $TCTMP/content.txt $MSG_DIR/$USER1
	tc_pass_or_fail $? "Mail didnt reach $USER1 mailbox"
}

#
# adding entry for multiple domains in local-host-names
#
test03()
{
	tc_register "Mail to $USER1@seconddomain.com delivered"
	echo "seconddomain.com" >> /etc/mail/local-host-names

	echo "MAIL TO SECONDDOMAIN" > $TCTMP/content.txt

	systemctl restart sendmail &>/dev/null

	# Mail from USER2 to USER1@seconddomain.com
	sendmail -f"$USER2" $USER1@seconddomain.com < $TCTMP/content.txt
	tc_fail_if_bad $? "Failed to sendmail to $USER1@seconddomain.com" || return

	# Add sleep for mail in mailbox
	# Check for mail content in /var/spool/mail/user
	sleep 2
	grep -q -f $TCTMP/content.txt $MSG_DIR/$USER1
	tc_pass_or_fail $? "Mail didnt reach $USER1 mailbox"
}

#
# mail to domain not listed in /etc/mail/local-host-names fails
#
test04()
{
	tc_register "Mail to $USER1@baddomain.com fails"

	echo "MAIL TO BADDOMAIN" > $TCTMP/content.txt

	# Mail from USER2 to USER1 where domain is not
	# added in /etc/mail/local-host-names
	sendmail -f"$USER2" $USER1@baddomain.com < $TCTMP/content.txt
	tc_fail_if_bad $? "Failed to sendmail to $USER1@baddomain.com" || return

	sleep 2
	grep -q -f $TCTMP/content.txt $MSG_DIR/$USER1
	if [ $? -eq 0 ]; then
	tc_fail "Mail delivered to bad domain"
	fi

	tc_pass
}
#
#adding entry in virtusertable
#
test05()
{
	tc_add_user_or_break || return # sets TC_TEMP_USER
	USER3=$TC_TEMP_USER
	tc_add_user_or_break || return # sets TC_TEMP_USER
	USER4=$TC_TEMP_USER
	echo "TEST FOR VIRTUSERTABLE" > $TCTMP/content.txt

	tc_register "Direct the mail for $USER1@mydomain.com to $USER3
                     and mail for $USER1@seconddomain.com to $USER4"

	echo "$USER1@mydomain.com    $USER3" >> /etc/mail/virtusertable
	echo "$USER1@seconddomain.com    $USER4" >> /etc/mail/virtusertable
	makemap hash /etc/mail/virtusertable.db < /etc/mail/virtusertable

	systemctl restart sendmail &>/dev/null
	sendmail -f"$USER2" $USER1@mydomain.com < $TCTMP/content.txt
	tc_fail_if_bad $? "Failed to sendmail to $USER1@mydomain.com" || return

	sendmail -f"$USER2" $USER1@seconddomain.com < $TCTMP/content.txt
	tc_fail_if_bad $? "Failed to sendmail to $USER1@seconddomain.com" || return

	sleep 2
	grep -q -f $TCTMP/content.txt $MSG_DIR/$USER3
	tc_fail_if_bad $? "mail not delivered from mydomain to $USER3" || return

	grep -q -f $TCTMP/content.txt $MSG_DIR/$USER4
	tc_pass_or_fail $? "mail not delivered from seconddomain to $USER4"
}
#
#adding entry in aliases file
#
test06()
{
	tc_register "Redirecting $USER1 to root"
	echo "$USER1:    root" >> /etc/aliases
	newaliases &>/dev/null
	tc_fail_if_bad $? "Failed to run newaliases command"

	echo "TEST FOR ALIASES" > $TCTMP/content.txt
	systemctl restart sendmail
	sendmail -f"$USER2" $USER1 < $TCTMP/content.txt
	tc_fail_if_bad $? "Failed to send mail to $USER1" || return

	sleep 2
	grep -q -f $TCTMP/content.txt $MSG_DIR/root
	tc_pass_or_fail $? "mail not delivered from mydomain to root"
}
#
# preventing spam by adding to /etc/mail/access
#
test07()
{
	tc_register "Adding entry to prevent mail from USER1 to /etc/mail/access"
	echo "To:$USER1@mydomain.com    REJECT" >> /etc/mail/access
	makemap hash /etc/mail/access.db < /etc/mail/access

	echo "SPAM MAIL" > $TCTMP/content.txt
	sendmail -f"$USER2" $USER1@mydomain.com < $TCTMP/content.txt
	if [ $? -eq 0 ]; then
		tc_fail $? "Spam mail is not prevented"
	fi
	tc_pass
}

#
# main
#
TST_TOTAL=1

tc_setup

test01
test02
test03
test04
test05
test06
test07
