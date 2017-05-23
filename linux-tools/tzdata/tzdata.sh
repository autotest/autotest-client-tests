#!/bin/bash
############################################################################################
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
### File :       tzdata.sh                                                     ##
##
### Description: Test for tzdata package                                       ##
##
### Author:      Kingsuk Deb <kingsdeb@linux.vnet.ibm.com>                     ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/tzdata"
required="date zdump timedatectl"
settime=0
function tc_local_setup()
{
    tc_root_or_break || return
    tc_exec_or_break "$required" || return
    tc_check_package "tzdata"
    tc_break_if_bad $? "tzdata not installed" || return
    tc_check_package "systemd"
    tc_break_if_bad $? "systemd package is not installed" || return

    timedatectl status >$stdout 2>$stderr
    grep -iq "Time zone: n/a" $stdout || grep -iq "Time zone: UTC" $stdout
    if [ $? -eq 0 ]; then
    timedatectl set-timezone Asia/Kolkata >$stdout 2>$stderr
    settime=1
    fi
    [[ -d /usr/share/zoneinfo &&  -e /etc/localtime ]]
    tc_break_if_bad $? "tzdata not installed or set properly" || return
    cp /etc/localtime /etc/localtime.bak

    if [ -f /etc/sysconfig/clock ]; then
        cp /etc/sysconfig/clock /etc/sysconfig/clock.bak
    fi
}

function tc_local_cleanup()
{	
    if [ $settime -eq 1 ]; then 
    timedatectl set-timezone UTC >$stdout 2>$stderr 
    fi
    ## No /etc/sysconfig/clock in some distro, so remove it if backup not found.
    if [ -f /etc/sysconfig/clock.bak ]; then
        mv /etc/sysconfig/clock.bak /etc/sysconfig/clock
    else
        rm -f /etc/sysconfig/clock
    fi
    mv /etc/localtime.bak /etc/localtime
} 

### Check for correct TZ, date and time ###
function test01()
{
    tc_register "test with date"
    date >$stdout 2>$stderr
    grep -q -E "CEST|CET|IST|GMT|EDT|EST|CDT|CST" $stdout
    tc_pass_or_fail $? "Test with date fail" || return

    tc_register "test for correct time"
    date --utc -d '2026-08-07 12:34:56-06:00' >$stdout 2>$stderr
    grep UTC $stdout | grep -q "18:34:56"
    tc_pass_or_fail $? "test TZ and time fail"

    tc_register "test with TZ env variable"
    TZ=Europe/London date -d '2026-08-07 12:34:56-06:00' >$stdout 2>$stderr
    grep -E "BST|GMT" $stdout | grep -q "19:34:56"
    tc_pass_or_fail $? "test with TZ fail"
}

### Test with zdump ###
function test02()
{
    tc_register "test with zdump"
    zdump Australia/Canberra >$stdout 2>$stderr
    grep -qE "AEDT|AEST" $stdout
    tc_pass_or_fail $? "test with zdump fail"
}

### main ###
tc_setup
TST_TOTAL=4
test01
test02
