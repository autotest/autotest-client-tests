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
## File :        keyutils.sh
##
## Description:  Cursory test of keyutils package.
##
## Author:       Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################

ME=$(readlink -f -- $0)
#LTPBIN=${ME%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

MY_DESC=my_desc
MY_DATA=my_data
unset KILL_SLEEP USER_ID

tc_local_setup()
{
    :   # Noting yet
}

tc_local_cleanup()
{
    ((KILL_SLEEP)) && {
        kill $KILL_SLEEP || kill -9 $KILL_SLEEP
        tc_wait_for_no_pid $KILL_SLEEP
    }
}

################################################################################
# the testcase functions
################################################################################

function test01()
{
    tc_register "installation check"
    tc_executes keyctl
    tc_pass_or_fail $? "keyutils not properly installed"
}

function test02()
{
    local expected expected2

    tc_register "user's session"
    tc_add_user_or_break || return
    USER_ID=$(su - $TC_TEMP_USER -c "echo \$UID") 2>$stderr
    tc_break_if_bad $? "could nod su to user $TC_TEMP_USER" || return
    su - $TC_TEMP_USER -c "keyctl show" >$stdout 2>$stderr
    tc_fail_if_bad $? "Unexpected response from keyctl show" || return

    expected="keyring: _uid.$USER_ID"
    expected2="keyring: _ses"
    grep -q "$expected" $stdout || grep -q "$expected2" $stdout
    tc_pass_or_fail $? "expected to see either \"$expected\" or \"$expected2\" in stdout" || return
}

function test03()
{
    local cmd expected

    # keep session alive for rest of tests
    su - $TC_TEMP_USER -c "while true ; do sleep 4; done" &
    KILL_SLEEP=$!

    cmd="keyctl add user $MY_DESC $MY_DATA @u"
    tc_register "$cmd"

    su - $TC_TEMP_USER -c "$cmd" >$stdout 2>$stderr
    tc_pass_or_fail $? "unexpected response from \"$cmd\"" || return
    MY_KEY=$(<$stdout)
    sleep 2 # be sure everything settles down
}

function test04()
{
    local expected expected2

    cmd="keyctl show"
    tc_register "$cmd"

    su - $TC_TEMP_USER -c "$cmd" >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\""

    expected="$MY_KEY .* $USER_ID .* user: $MY_DESC"
    grep -q "$expected" $stdout || grep -q "$expected2" $stdout
    tc_pass_or_fail $? "expected to see either \"$expected\" or \"$expected2\" in stdout" || return
}

function test05()
{
    local cmd expected

    cmd="keyctl list @u"
    tc_register "$cmd"

    su - $TC_TEMP_USER -c "$cmd" >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return

    expected="$MY_KEY: .* $USER_ID .* user: $MY_DESC"

    grep -q "$expected" $stdout
    tc_pass_or_fail $? "expected to see \"expected\" in stdout"
}

function test06()
{
    local cmd expected

    cmd="keyctl print $MY_KEY"
    tc_register "$cmd"

    su - $TC_TEMP_USER -c "$cmd" >$stdout 2>$stderr
    grep -Eq "Last|$MY_DATA" $stdout
    rc=$?

    tc_fail_if_bad $rc "unexpected response from \"$cmd\"" || return

    expected="$MY_DATA"
    expected1="Last"
    grep -Eq "$expected|$expected1" $stdout
    tc_pass_or_fail $? "expected to see \"$expected\" \"$expected1\" in stdout"
}

################################################################################
# main
################################################################################

TST_TOTAL=6
tc_setup                        # standard tc_setup
tc_run_me_only_once

test01 &&
test02 &&
test03 &&
test04 &&
test05 &&
test06
