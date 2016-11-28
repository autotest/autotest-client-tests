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
## File :        userhelper.sh
##
## Description:  Test the userhelper command.
##
## Author:       Madhuri Appana, madhuria@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/usermode
source $LTPBIN/tc_utils.source

REQUIRED="userhelper expect"
################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    tc_exec_or_break $REQUIRED
    tc_add_user_or_break 1>$stdout 2>$stderr
    ls -l `which userhelper` | grep -q rws
    tc_break_if_bad $? "userhelper command needs setuid to root"
}

function test01()
{
    tc_register "Change user password using userhelper"
    local expcmd=`which expect`
    cat > $TCTMP/exp$TCID <<EOF >$stdout 2>$stderr
                #!$expcmd -f
                proc abort {} { exit 1 }
		spawn -noecho userhelper -t -c $TC_TEMP_USER
                expect "New password:" 
                send "password\r"
                expect "Retype new password:"
                send "password\r"
		expect eof
EOF
    chmod +x $TCTMP/exp$TCID

    # execute the test
    $TCTMP/exp$TCID >$stdout 2>$stderr
    tc_pass_or_fail $? "Password setting failed for $TC_TEMP_USER"

}

function test02()
{
    tc_register "Change Gecos information using userhelper"
    userhelper -t -f $TC_TEMP_USER -o ibm -h 999 -p 123 -s /bin/ksh $TC_TEMP_USER
    RC=$?
    gecos_info=`grep $TC_TEMP_USER /etc/passwd | cut -d: -f 5 | cut -d, -f2`
    if [ $gecos_info == ibm ];
    then
    	tc_pass_or_fail $RC "Successfully updated users Gecos information"
    fi

}

function test03()
{
    tc_register "Change shell type using userhelper"
    userhelper -t -s /bin/bash $TC_TEMP_USER 
    RC=$?
    test_shell_name=`grep $TC_TEMP_USER /etc/passwd | cut -d : -f 7`
    if [ $test_shell_name == /bin/bash ];
    then
    	tc_pass_or_fail $RC "Successfully updated shell information in /etc/passwd file"
    fi	
}

function test04()
{
    tc_register "Invoke userhelper with a invalid shell name"
    userhelper -t -s /bin/korn $TC_TEMP_USER
    if [ $? -ne 0 ]; then
	tc_pass_or_fail $? "The shell provided is not valid (i.e., does not exist in /etc/shells)"
    fi
}	

function test05()
{
    tc_register "Invoke userhelper with a invalid user name"
    userhelper -t -c USER_TEMP 
    if [ $? -ne 0 ]; then
	tc_pass_or_fail $? "The user name provided is not valid"
    fi
}	

function test06()
{
    tc_register "Execute userhelper as a Normal user"
    local expcmd=`which expect`
    cat > $TCTMP/exp$TCID <<EOF >$stdout 2>$stderr
                #!$expcmd -f
                proc abort {} { exit 1 }
                spawn -noecho su -c "userhelper -t -s /bin/sh $TC_TEMP_USER" $TC_TEMP_USER
                expect "Password:"
                send "password\r"
                expect eof
EOF
    chmod +x $TCTMP/exp$TCID

    # execute the test
    $TCTMP/exp$TCID >$stdout 2>$stderr
    tc_pass_or_fail $? "Failed to execute userhelper as normal user"
}
################################################################################
# main
################################################################################
tc_setup
TST_TOTAL=6
test01
test02
test03
test04
test05
test06
