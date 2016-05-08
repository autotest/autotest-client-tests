#!/bin/bash
# vi: set ts=4 sw=4 expandtab:
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
# File:         psacct.sh
# Description:  This program tests basic functionality of psacct program
# Author:       Athira Rajeev<atrajeev@in.ibm.com>

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTDIR=/opt/fiv/ltp/testcases/fivextra/psacct

################################################################################
# Utility functions
################################################################################

#
# local setup
#        
function tc_local_setup()
{       
    tc_root_or_break || return
    tc_exec_or_break grep ac lastcomm accton sa dump-acct dump-utmp || return

    [ -e /var/account/pacct ] || exit
    tc_service_start_and_wait psacct
    tc_break_if_bad $? "failed to start psacct service"

    tc_add_user_or_break || return # sets TC_TEMP_USER
    USER1=$TC_TEMP_USER
    PASSWORD1=$TC_TEMP_PASSWD

    tc_add_user_or_break || return # sets TC_TEMP_USER
    USER2=$TC_TEMP_USER 
    PASSWORD2=$TC_TEMP_PASSWD

	cat >> $TCTMP/login.sh <<-EOF
	#!/usr/bin/expect -f
	set timeout 5
	proc abort {} { exit 1 }
 	spawn ssh $USER1@localhost
	expect "Are you sure you want to continue connecting (yes/no)?" { send "yes\r" }
	# Look for passwod prompt
	expect "*?assword:*"
	# Send password aka $password
	send -- "$PASSWORD1\r"
	expect eof
	EOF
 
    chmod +x $TCTMP/login.sh
}

################################################################################
# Tesytcase functions
################################################################################

#
# test01        installation check
#
function test01()
{
    tc_register     "ac command"
    ac &>$stdout 2>$stderr
    tc_fail_if_bad $? "ac command failed" || return
     
    grep -wq total $stdout
    tc_fail_if_bad $? "ac command didnt display total"

    ac -d &>$stdout 2>$stderr
    grep -wq Today $stdout
    tc_fail_if_bad $? "ac -d command didnt display total"

    $TCTMP/login.sh    
    ac -p &>$stdout 2>$stderr
    tc_fail_if_bad $? "ac -p command failed" || return
  
    grep -wq $USER1 $stdout
    tc_pass_or_fail $? "ac -p command failed"
}

#
# test02        lastcomm
#
function test02()
{
    tc_register     "lastcomm command"
 
    su - $USER1 -c "uname -a" &>$stdout
    tc_fail_if_bad $? "failed to execute command as $USER1" || return

    lastcomm $USER1 &>$stdout 2>$stderr
    tc_fail_if_bad $? "failed to execute lastcomm command" || return

    grep -wq uname $stdout
    tc_fail_if_bad $? "lastcomm failed to display the user command" || return

    lastcomm uname &>$stdout 2>$stderr
    grep -wq $USER1 $stdout
    tc_pass_or_fail $? "lastcomm command failed to display user"

}

#
# test03        accton command
#
function test03()
{
    tc_register     "accton command"

    /usr/sbin/accton /var/account/pacct &>$stdout 2>$stderr 
    tc_fail_if_bad $? "failed to start accton" || return

    su - $USER1 -c "users" &>$stdout
   
    dump-acct /var/account/pacct &>$stdout 2>$stderr 
    tc_fail_if_bad $? "dump-acct failed" || return

    grep -wq users $stdout
    tc_pass_or_fail $? "dump-acct failed to read pacct" 
}

#
# test04 sa command
#
function test04()
{
    tc_register "sa command"

    $TCTMP/login.sh

    sa &>$stdout 2>$stderr
    tc_fail_if_bad $? "sa command failed to execute" || return

    sa -s &>$stdout 2>$stderr
    tc_fail_if_bad $? "failed to merge information to usracct and savacct files"

    [ -e /var/account/savacct ]
    if [ $? -ne 0 ]; then
        tc_fail "/var/account/savacct doesnot exist" || return
    fi

    sa -u &>$stdout 2>$stderr
    tc_fail_if_bad $? " sa -u failed" || return

    #check if it displays the users command executed by $USER1
    echo `grep -w users $stdout` | grep -wq $USER1 2>$stderr
    tc_fail_if_bad $? "sa command failed to print user info" || return

    [ -e /var/account/usracct ]
    tc_pass_or_fail $? "/var/account/usracct doesnt exist"

}

#
#test05	accton to stop service
#
function test05()
{
    tc_register	"accton to stop service"
    
    /usr/sbin/accton off &>$stdout 2>$stderr 
    tc_fail_if_bad $? "failed to stop accounting activity"

    su - $USER2 -c "who" &>$stdout
    dump-acct /var/account/pacct &>$stdout
    tc_fail_if_bad $? "dump-acct failed" || return

    grep -wq who $stdout
    if [ $? -eq 0 ]; then
    tc_fail "accton failed" || return
    fi
   
    tc_pass
}
 
#
# test06 dump-utmp test
#
function test06()
{
    tc_register "dump-utmp test"
    dump-utmp /var/log/wtmp &>$stdout
    tc_fail_if_bad $? "dump-utmp failed" || return

    grep -w $USER1 $stdout
    tc_pass_or_fail $? "dump-utmp failed to display login record for $USER1"

    PROCESS_LIST=`ps -ef|grep $USER1|awk '{print $2}'`
    for PID in $PROCESS_LIST
    do
         kill -9 $PID >/dev/null 2>&1
    done
}
    
################################################################################
# main
################################################################################

TST_TOTAL=6

tc_setup

test01 
test02
test03
test04
test05
test06
