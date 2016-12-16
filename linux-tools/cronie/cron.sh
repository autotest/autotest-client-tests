#!/bin/bash
#############################################################################################
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
# File:            cron.sh
#
# DESCRIPTION:  quick test of cron capability
#
# AUTHOR:   RC Paulsen
#
##############################################################################################################
#

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/cronie
source $LTPBIN/tc_utils.source

#
#   logging_message_to_file  Start recording snapshot of syslog
#
#   $1 the name of a file to capture the snapshot. A required argument.
#   The testcase will be BROK and aborted if the name of a writable file
#   is not passed as first and only argument.
#
#   Only one instance of the capture process is allowed. If an instance is
#   already running, it will be killed before a new instance is started.
#   If the same filename is specified the file will be overwritten.
#
#   If the file is not under $TCTMP it is the caller's responsibility to
#   eventually delete it.
#
#   Use tc_cap_log_stop to stop capturing the snapshot.
#
#   Breaks testcase and exits if there is an error.
#   Returns true otherwise.
#

function logging_message_to_file()
{
    [ $# -eq 1 ] && touch $1 && rm -f $1 && tc_wait_for_no_file $1
    tc_break_if_bad_rc $? "$FUNCNAME: Internal script error: Must pass writable file." || exit
    local snapshot=$1

    tc_cap_log_stop

    # "-n 0" is needed to ensure we don't include extraneous log data in snapshot.
    # "sync" is needed but I'm not sure why.
    tail -n 0 -f /var/log/cron > $snapshot &
    local tc_cap_log_pid=$!
    echo $tc_cap_log_pid > $TC_SAVE/tc_cap_log_pid
    tc_wait_for_pid $tc_cap_log_pid && tc_wait_for_file $snapshot
    tc_break_if_bad_rc $? "$FUNCNAME: Internal script error: could not tail /var/log/cron" || exit
    sync 
    
    return 0
}

#
# Local setup
#
function tc_local_setup()
{
    MY_SYSLOG=$TCTMP/MY_SYSLOG
    cronjob_file=$TCTMP/cronjob_file
    cronout_file=$TCTMP/cronout_file

    tc_root_or_break || exit
    tc_exec_or_break  tail sleep || exit

    CRON_ALLOW="/etc/cron.allow"
    CRON_DENY="/etc/cron.deny"
    CRON_CMD="crontab"
    CRON_DAEMON="crond"
    WAIT_TIME=75

    [ -e /var/log/cron ] || ( touch /var/log/cron \
    && tc_service_restart_and_wait rsyslog )

    tc_add_user_or_break
    CRON_USER1=$TC_TEMP_USER
    tc_add_user_or_break
    CRON_USER2=$TC_TEMP_USER

    CRON_JOB1=/home/$CRON_USER1/cronfile1
    CRON_JOB2=/home/$CRON_USER2/cronfile2
    CRON_OUT1=/home/$CRON_USER1/cronout1
    CRON_OUT2=/home/$CRON_USER2/cronout2

    [ -f $CRON_ALLOW ] && cp $CRON_ALLOW $TCTMP
    [ -f $CRON_DENY ] && cp $CRON_DENY $TCTMP

    logging_message_to_file $MY_SYSLOG

    return 0
}

#
# local cleanup
#
tc_local_cleanup()
{
    [ $? -ne 0 ] && cat $MY_SYSLOG

    # remove all cron jobs
    crontab -r 2>$stderr 1>$stdout

    tc_info "Waiting a minute for final instance of cronjob to run before deleting its output directory."
    sleep 61
}

#
# installation check
#
function test01()
{
    tc_register    "installation check"

    tc_service_start_and_wait $CRON_DAEMON
    tc_fail_if_bad $? "cron daemon not working" || return
    tc_executes crontab 
    tc_pass_or_fail $? "cron package not installed properly" || return
    crontab -r &>/dev/null  # flush crontab
    return 0
}

#
# install cronjob from file
#
function test02()
{
    tc_register    "install cronjob from file"

    echo "* * * * * echo hello > $cronout_file" > $cronjob_file
    crontab $cronjob_file 2>$stderr 1>$stdout
    tc_fail_if_bad $? "Broke while installing cronjob" || return
    tc_wait_for_file_text $MY_SYSLOG REPLACE $WAIT_TIME
    tc_pass_or_fail $? "crontab REPLACE not recorded in var/log/cron"
}

#
# Look for cronjob activity
# (assumes test02 has run)
#
function test03()
{
    tc_register "cronjob executes"

    tc_wait_for_file_text $MY_SYSLOG "echo hello" $WAIT_TIME
    tc_fail_if_bad $? "cronjob did not run" || return

    tc_wait_for_file_text $cronout_file hello
    tc_pass_or_fail $? "Did not see \"hello\" in output file"
}

#
# list cronjob
# (assumes test02 has run)
#
function test04()
{
    tc_register    "crontab -l (list cronjob)"
    
    crontab -l 2>$stderr | tail -1 >$stdout
    tc_fail_if_bad $? "Unexpected output from crontab -l" || return

    diff $cronjob_file $stdout &>/$TCTMP/diff.out
    tc_pass_or_fail $? "Failed to list installed cronjob" \
    "diff output is" \
    "$(cat /$TCTMP/diff.out)"
}

#
# remove cronjob
# (assumes test02 has run)
#              
function test05()
{
    tc_register    "crontab -r (remove cronjob)"

    crontab -r  2>$stderr 1>$stdout
    tc_fail_if_bad $? "broke while removing crontab" || return

    tc_wait_for_file_text $MY_SYSLOG DELETE $WAIT_TIME
    tc_pass_or_fail $? "no /var/log/cron entry for removed crontab"
}

#
# cron allow allowed
#
function test06()
{
    # CRON_ALLOW with only one user
    rm -f $CRON_DENY
    echo $CRON_USER1 > $CRON_ALLOW

    tc_register "User *IN* $CRON_ALLOW is *ALLOWED* to run job"

cat <<EOF >$CRON_JOB1
* * * * * echo "TEST JOB RAN" > $CRON_OUT1
EOF
    chown $CRON_USER1 $CRON_JOB1
            
    rm -f $CRON_OUT1
    su - $CRON_USER1 -c "$CRON_CMD $CRON_JOB1"
    tc_fail_if_bad $? "cron command failed" || return

    tc_info "Waiting up to $WAIT_TIME seconds for a one minute cron job ..."
    tc_wait_for_file_text $CRON_OUT1 "TEST JOB RAN" $WAIT_TIME
    tc_pass_or_fail $? "File $CRON_OUT1 not created or did not have text \"TEST JOB RAN\""
}

#
# cron alow NOT allowed
#
function test07()
{
    tc_register "User *NOT* in $CRON_ALLOW is *NOT* allowed to run job"

cat <<EOF >$CRON_JOB2
* * * * * echo "TEST JOB RAN" > $CRON_OUT2
EOF
    chown $CRON_USER2 $CRON_JOB2

    ! su - $CRON_USER2 -c "$CRON_CMD $CRON_JOB2"
    tc_pass_or_fail $? "cron command did NOT fail as expected"
}

#
# cron deny NOT denied
#
function test08()
{
    # CRON_ALLOW with only one user
    rm -f $CRON_ALLOW
    echo $CRON_USER2 > $CRON_DENY

    tc_register "User *NOT* in $CRON_DENY is *NOT* denied to run job"

cat <<EOF >$CRON_JOB1
* * * * * echo "TEST JOB RAN" > $CRON_OUT1
EOF
    chown $CRON_USER1 $CRON_JOB1
            
    rm -f $CRON_OUT1
    su - $CRON_USER1 -c "$CRON_CMD $CRON_JOB1"
    tc_fail_if_bad $? "cron command failed" || return

    tc_info "Waiting up to $WAIT_TIME seconds for a one minute cron job ..."
    tc_wait_for_file_text $CRON_OUT1 "TEST JOB RAN" $WAIT_TIME
    tc_pass_or_fail $? "File $CRON_OUT1 not created or did not have text \"TEST JOB RAN\""
}

#
# cron deny denied
#
function test09()
{
    tc_register "User IN $CRON_DENY is *DENIED* to run job"

cat <<EOF >$CRON_JOB2
* * * * * echo "TEST JOB RAN" > $CRON_OUT2
EOF
    chown $CRON_USER2 $CRON_JOB2

    ! su - $CRON_USER2 -c "$CRON_CMD $CRON_JOB2"
    tc_pass_or_fail $? "cron command did NOT fail as expected"
}


#
# main
#

TST_TOTAL=5
tc_setup

test01 &&
test02 &&
test03 &&
test04 &&
test05
test06
test07
test08
test09
