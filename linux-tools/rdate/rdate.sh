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
### File :       rdate.sh                                                      ##
##
### Description: Test for rdate package                                        ##
##
### Author:      Kingsuk Deb <kingsdeb@linux.vnet.ibm.com>                     ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/rdate"
required="rdate"
test_opt_l=""


function tc_local_setup()
{
    # Check installation
    tc_exec_or_break $required

    tc_service_status xinetd
    [ $? -ne 0 ] && stop_xinetd=yes
    tc_service_status rsyslog
    [ $? -ne 0 ] && stop_rsyslog=yes

    # Check time server conf files
    [ -f /etc/xinetd.d/time-dgram ] && [ -f /etc/xinetd.d/time-stream ]
    tc_break_if_bad $? "No time service configuartion files found"

    cp /etc/xinetd.d/time-dgram /etc/xinetd.d/time-dgram.bak
    cp /etc/xinetd.d/time-stream /etc/xinetd.d/time-stream.bak

    # Enable RFC868 Time server
    sed -i 's/disable[\t]*= yes/disable = no/' /etc/xinetd.d/time-dgram
    sed -i 's/disable[\t]*= yes/disable = no/' /etc/xinetd.d/time-stream

    tc_service_restart_and_wait xinetd
    tc_break_if_bad $? "Not able to restart xinetd service"

    # rsyslogd will create cron log, so decide if to test rdate -l
    tc_executes "rsyslogd"  && { 
        test_opt_l=yes
        [ -f /var/log/cron ] && mv /var/log/cron /var/log/cron.bak
        touch /var/log/cron
	tc_service_restart_and_wait rsyslog
        [ $? -ne 0 ] && test_opt_l=no
    }
    
    # Choose an IP which the system is not able to connect for timeout test
    local i=2
    while [ $i -le 100 ]; 
    do
       IPADDR=192.168.122.$i 
       ping -c1 $IPADDR &>/dev/null
       [ $? -ne 0 ] && break
       ((++i))
    done
}

function tc_local_cleanup()
{
    [ -f /etc/xinetd.d/time-dgram.bak ] && mv /etc/xinetd.d/time-dgram.bak \
        /etc/xinetd.d/time-dgram
    [ -f /etc/xinetd.d/time-stream.bak ] && mv /etc/xinetd.d/time-stream.bak \
        /etc/xinetd.d/time-stream

    if [[ `echo $stop_xinetd` = yes ]]
    then
	tc_service_stop_and_wait xinetd
    else
	tc_service_restart_and_wait xinetd
    fi

    mv /var/log/cron.bak /var/log/cron
   
    if [[ `echo $stop_rsyslog` = yes ]]
    then
	tc_service_stop_and_wait rsyslog
   else
	tc_service_restart_and_wait rsyslog
    fi 
}

function run_test()
{
    tc_register "Test rdate -p"
    rdate -p localhost >$stdout 2>$stderr
    tc_pass_or_fail $? "rdate -p failed" || return

    tc_register "Test rdate -s"
    rdate -s localhost >$stdout 2>$stderr
    tc_pass_or_fail $? "rdate -s failed"

    tc_register "Test rdate -l"
    if [ `echo $test_opt_l` = "yes" ]
    then
        rdate -l $IPADDR &>$stdout 
	grep rdate /var/log/cron | grep -q "couldn't connect to host $IPADDR" || grep rdate /var/log/cron | grep -q "timeout"
        tc_pass_or_fail $? "rdate -l failed"
    else
        tc_conf "No rsyslog in system to test rdate -l"
    fi

    tc_register "Test rdate -u"
    rdate -u localhost >$stdout 2>$stderr
    tc_pass_or_fail $? "rdate -u failed"

    tc_register "Test rdate -t"
    before="$(date +%s)"
    rdate -t 3 $IPADDR &>$stdout
    after="$(date +%s)"
    elapsed_time="$(expr $after - $before)"
    [ $elapsed_time -eq 3 ]
    tc_pass_or_fail $? "rdate -t failed"
}

#
# main
#
tc_setup
TST_TOTAL=5
run_test
