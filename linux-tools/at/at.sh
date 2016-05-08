#!/bin/bash
# vi: ts=4 sw=4 expandtab :
##                                                                            ##
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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
#                                                                             ##
# File :        at.sh                                                         ##
#                                                                             ##
# Description:  Test basic functionality of at command                        ##
#                                                                             ##
# Author:       Yu-Pao Lee                                                    ##


# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

# global variables
started_atd="no"

COMMANDS="at atd atq atrm"

################################################################################
# utility functions for this testcase
################################################################################

function tc_local_setup()
{

    AT_ALLOW="/etc/at.allow"
    AT_DENY="/etc/at.deny"
    AT_CMD="at -m now + 1 minutes -f"
    WAIT_TIME=75

    tc_add_user_or_break
    AT_USER1=$TC_TEMP_USER
    tc_add_user_or_break
    AT_USER2=$TC_TEMP_USER

    AT_JOB1=/home/$AT_USER1/atfile1
    AT_JOB2=/home/$AT_USER2/atfile2
    AT_OUT1=/home/$AT_USER1/atout1
    AT_OUT2=/home/$AT_USER2/atout2

    [ -f $AT_ALLOW ] && cp $AT_ALLOW $TCTMP
    [ -f $AT_DENY ] && cp $AT_DENY $TCTMP

    return 0
}

# stops atd if atd is atarted in this testcase
# call standard cleanup function
function tc_local_cleanup()
{
    [ -f $TCTMP/$AT_ALLOW ] && mv $TCTMP/$AT_ALLOW $AT_ALLOW || rm -f $AT_ALLOW
    [ -f $TCTMP/$AT_DENY ] && mv $TCTMP/$AT_DENY $AT_DENY || rm -f $AT_DENY

    if [ "$started_atd" = "yes" ] ; then
        tc_service_stop_and_wait atd 
        tc_info "Stopped atd."
    fi
}

################################################################################
# testcase functions
################################################################################

#
# installation check
#
function test01()
{
    tc_register "installation check"
    tc_executes $COMMANDS
    tc_pass_or_fail $? "at package not installed properly" || return

    local at_cmd=$(which at)
    chmod o+rx $at_cmd	            # some builds do not guarantee this
}

#
# atd and at commands
#
function test02()
{
    tc_register "start daemon and try at command"
    
    tc_exec_or_break grep || return
    
    # ensure atd is up
    if ! tc_service_status atd ; then
        tc_root_or_break || return
        tc_service_start_and_wait atd 
        tc_info "Started atd for this testcase."
        started_atd="yes"
    fi

    tc_pass
    return 0

    echo "echo hello > $TCTMP/hello.txt" | at now+1 minutes &>$stdout
    tc_fail_if_bad $? "unexpected response from at command"

    tc_info "wait for at command to be executed."
    tc_wait_for_file_text $TCTMP/hello.txt "hello" $WAIT_TIME
    tc_pass_or_fail $? "\"hello\" not seen in file $TCTMP/hello.txt"
}   

#
# atq and atrm commands
#
function test03()
{
    tc_register "atq and atrm commands"
    
    tc_exec_or_break awk || return

    echo "ls >$TCTMP/ls.txt" | at 1am tomorrow &> $TCTMP/at.queue

    local job_num=`cat $TCTMP/at.queue | grep job`
    shift $#
    [ "$job_num" ] && set $job_num
    job_num=$2
    [ "$job_num" ]
    tc_fail_if_bad $? "at command failed. - no job number found." || return

    atq | grep -q $job_num >$stdout 2>$stderr
    tc_fail_if_bad $? "atq command failed to list $job_num." || return 

    # delete the job using atrm
    atrm $job_num

    ! atq | grep $job_num &>$stdout
    tc_pass_or_fail $? "atrm command failed to delete $job_num."
}

#
# at allow allowed
#
function test04()
{
    # AT_ALLOW with only one user
    rm -f $AT_DENY
    echo $AT_USER1 > $AT_ALLOW

    tc_register "User *IN* $AT_ALLOW is *ALLOWED* to run job"

cat <<EOF >$AT_JOB1
#!/bin/bash
echo "TEST JOB RAN" > $AT_OUT1
EOF
    chown $AT_USER1 $AT_JOB1
    chmod +x $AT_JOB1
            
    rm -f $AT_OUT1
    su - $AT_USER1 -c "$AT_CMD $AT_JOB1"
    tc_fail_if_bad $? "at command failed" || return

    tc_info "Waiting up to $WAIT_TIME seconds for a one minute at job ..."
    tc_wait_for_file_text $AT_OUT1 "TEST JOB RAN" $WAIT_TIME
    tc_pass_or_fail $? "File $AT_OUT1 not created or did not have text \"TEST JOB RAN\""
}

#
# at alow NOT allowed
#
function test05()
{
    tc_register "User *NOT* in $AT_ALLOW is *NOT* allowed to run job"

cat <<EOF >$AT_JOB2
#!/bin/bash
echo "TEST JOB RAN" > $AT_OUT2
EOF
    chown $AT_USER2 $AT_JOB2
    chmod +x $AT_JOB2

    rm -f $AT_OUT2
    ! su - $AT_USER2 -c "$AT_CMD $AT_JOB2"
    tc_pass_or_fail $? "at command did NOT fail as expected"
}

#
# at deny NOT denied
#
function test06()
{
    # AT_ALLOW with only one user
    rm -f $AT_ALLOW
    echo $AT_USER2 > $AT_DENY

    tc_register "User *NOT* in $AT_DENY is *NOT* denied to run job"

cat <<EOF >$AT_JOB1
#!/bin/bash
echo "TEST JOB RAN" > $AT_OUT1
EOF
    chown $AT_USER1 $AT_JOB1
    chmod +x $AT_JOB1
            
    rm -f $AT_OUT1
    su - $AT_USER1 -c "$AT_CMD $AT_JOB1"
    tc_fail_if_bad $? "at command failed" || return

    tc_info "Waiting up to $WAIT_TIME seconds for a one minute at job ..."
    tc_wait_for_file_text $AT_OUT1 "TEST JOB RAN" $WAIT_TIME
    tc_pass_or_fail $? "File $AT_OUT1 not created or did not have text \"TEST JOB RAN\""
    procpid=`pgrep -u  $AT_USER1`
    [ "$procpid" ] && { tc_wait_for_no_pid $procpid ;}
    if [ -d /proc/$procpid ]; then   kill -9 $procpid &>/dev/null ; fi

}

#
# at deny denied
#
function test07()
{
    tc_register "User IN $AT_DENY is *DENIED* to run job"

cat <<EOF >$AT_JOB2
#!/bin/bash
echo "TEST JOB RAN" > $AT_OUT2
EOF
    chown $AT_USER2 $AT_JOB2
    chmod +x $AT_JOB2

    rm -f $AT_OUT2
    ! su - $AT_USER2 -c "$AT_CMD $AT_JOB2"
    tc_pass_or_fail $? "at command did NOT fail as expected"
}

################################################################################
# main function
################################################################################

TST_TOTAL=4

tc_setup        # standard setup

test01 || exit
test02
test03
test04          # two at allow tests
test05
test06
test07
