#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
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
#
# File :	procmail.sh
#
# Description:	Tests procmail's ability to be inviked via $HOME/.forward
#		and direct mail to specific mailbox.
#
# Author:	Robert Paulsen, rpaulsen@us.ibm.com
#

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

home=""
message=""		# text to be in email placed here by tc_local_setup

################################################################################
# local utility function
################################################################################

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break mail cat sed chown || return

	tc_add_user_or_break &>/dev/null || return

	# get temp user's home directory
	#home=`sed -n "/^\$TC_TEMP_USER:/p" /etc/passwd | cut -d':' -f 6`
	home=$TC_TEMP_HOME

	# create forwarding file for temp user
	cat > $home/.forward <<-EOF
		"|exec /usr/bin/procmail"
	EOF
	chown $TC_TEMP_USER $home/.forward
	chgrp $TC_TEMP_USER $home/.forward
	chmod 664 $home/.forward

	# create procmailrc file for temp user
	cat > $home/.procmailrc <<-EOF
		:0
		* ^Subject:.*XXXX
		XXXX-mail
		:0
		* ^From.*$TC_TEMP_USER
		from_me
	EOF
	chown $TC_TEMP_USER $home/.procmailrc
	chgrp $TC_TEMP_USER $home/.procmailrc
	chmod 664 $home/.procmailrc

        # create message to be mailed
        message="A message from me $$"
        echo "$message" > $home/mailmessage
        chown $TC_TEMP_USER $home/mailmessage
	
	echo "d*" | mail &>/dev/null
	
	mv /var/spool/clientmqueue/ /var/spool/clientmqueue_orig/	
	mkdir /var/spool/clientmqueue/
	chown smmsp /var/spool/clientmqueue/
	chgrp smmsp /var/spool/clientmqueue/
	chmod 777 /var/spool/clientmqueue/

	# Check if postfix is running. If so, stop postfix
	tc_service_status postfix
        if [ $? -eq 0 ]; then
        	postfix_cleanup=1
        	tc_service_stop_and_wait postfix
	fi 
	
	# stop sendmail
	tc_service_stop_and_wait sendmail
	tc_wait_for_inactive_port 25
	tc_fail_if_bad $? "could not stop sendmail" || return

        # start sendmail
        tc_service_start_and_wait sendmail
        tc_break_if_bad $? "could not start sendmail" || return

        tc_wait_for_active_port 25
        tc_break_if_bad $? "sendmail did not bind to port 25"
}

#
# tc_local_cleanup
#
function tc_local_cleanup()
{
	rm -rf /var/spool/clientmqueue/
	mv /var/spool/clientmqueue_orig/ /var/spool/clientmqueue/

	#Restore status of postfix prior to test execution
	if [ $postfix_cleanup ]; then 
		tc_service_stop_and_wait sendmail
		tc_service_start_and_wait postfix
	fi
}

################################################################################
# the testcase functions
################################################################################

#
# test01	Test procmail's ability to be invoked via $HOME/.forward and
#		direct mail to a specific file based on sender's name.
#

function test01()
{
	tc_register "store mail by user"
	tc_exec_or_break cat chown su sleep || return

	# have temp user mail msg to self, subject not important
	local cmd1="mail -s \"fiv message\" $TC_TEMP_USER < mailmessage"
	2>$stderr echo "$cmd1" | su - $TC_TEMP_USER
	tc_fail_if_bad  $? "bad results from $cmd1" || return

	tc_info "Sleep for 100 seconds to get the mail"
	sleep 100

	tc_wait_for_file $home/from_me 30
	tc_fail_if_bad $? "forwarded mail did not reach $home/from_me" || return

	# check that from_me contents are correct
	tc_wait_for_file_text $home/from_me "$message" 30
	tc_pass_or_fail $? "message not forwarded correctly"
}

#
# test02	Test procmail's ability to be invoked via $HOME/.forward and
#		direct mail to a specific file based on subject
#
function test02()
{
	tc_register "store mail by subject"
	tc_exec_or_break grep cat echo || return

	# have temp user mail msg to self, special subject with XXXX
	local cmd2="mail -s \"fiv message XXXX\" $TC_TEMP_USER < mailmessage"
	2>$stderr echo "$cmd2" | su - $TC_TEMP_USER
	tc_fail_if_bad  $? "bad results from $cmd2" || return

	tc_info "Sleep for 100 seconds to get the mail"
	sleep 100

	tc_wait_for_file $home/XXXX-mail 30
	tc_fail_if_bad $? "forwarded mail did not reach $home/XXXX-mail" || return

	# check that XXXX-mail contents are correct
	tc_wait_for_file_text $home/XXXX-mail "$message" 30
	tc_pass_or_fail $? "message not forwarded correctly"
}

################################################################################
# main
################################################################################

TST_TOTAL=2

tc_setup

test01 &&
test02		# depends on mail sent in test01

