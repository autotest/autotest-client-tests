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
## File :	mutt.sh
##
## Description:	Test mutt's ability to send mail via command-line invocation.
##
## Author:	RC Paulsen
###########################################################################################
## Source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# local utility functions
################################################################################

MUTT_DIR="/root/Mutt_test$$"
REAL_MAIL=0

#
# tc_local_setup
#
function tc_local_setup()
{
	# check if postfix is running

        /etc/init.d/postfix status &> /dev/null
        if [ $? -eq 0 ]; then
        	postfix_cleanup=1
        	/etc/init.d/postfix stop &>/dev/null
        fi

        tc_executes mail &&
        tc_executes /etc/init.d/sendmail &&
        /etc/init.d/sendmail start &&
        REAL_MAIL=1

	[ -f ~/.muttrc ] && mv ~/.muttrc ~/.muttrc-save$$

	return 0
}

#
# tc_local_cleanup
#
function tc_local_cleanup()
{
	tc_executes mail && tc_wait_for_no_mail root
	[ -f ~/.muttrc-save$$ ] && mv ~/.muttrc-save$$ ~/.muttrc 
	rm -rf $MUTT_DIR
	
	# restore the status of postfix prior to test execution
	if [ $postfix_cleanup ]; then
		/etc/init.d/sendmail stop &>/dev/null
		/etc/init.d/postfix start &>/dev/null
	fi

	return 0
}

################################################################################
# the testcase functions
################################################################################

#
# installation check
#
function test01()
{
	tc_register "installation check"

        tc_executes mutt
        tc_pass_or_fail $? "mutt package not properly installed"
}

#
# send mail
#
function test02()
{
	tc_register "send email via mutt"

	mkdir $MUTT_DIR
	echo  "set record=\"$MUTT_DIR/Sent\"" >   ~/.muttrc	

        local content="This is a test from mutt $$"

        ((REAL_MAIL)) && {
		tc_wait_for_no_mail root
		tc_break_if_bad $? "Could not clear root's mailbox" || return
	}

        echo "$content" | mutt -s "Test from mutt.sh $$" root >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response from mutt command" || return

        grep -q "$content" $MUTT_DIR/Sent >$stdout 2>$stderr
        tc_fail_if_bad $? "Mutt failed to put sent mail in $MUTT_DIR/Sent" || return

        ((REAL_MAIL)) && {
                tc_wait_for_mail root
                tc_fail_if_bad $? "Failed to receive mail sent by mutt." || return
                tc_look_for_mail_text root "$content"
                tc_fail_if_bad $? "Didn't find expected text in mail: \"$content\"." || return
        }

	tc_pass
}

################################################################################
# main
################################################################################

TST_TOTAL=2
tc_setup

test01 &&
test02
