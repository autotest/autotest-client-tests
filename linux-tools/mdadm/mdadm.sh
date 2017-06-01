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
## File :    mdadm.sh
##
## Description:  Test mdadm package
##
## Author:   Hu Chenli, huchenli@cn.ibm.com
###########################################################################################

commands="create start manage grow monitor"

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TST_TOTAL=5
REQUIRED="dd losetup echo grep cut"
sendmail_service="sendmail"
postfix_service="postfix"
mail_service=""

#
# stop md device passed in $1
#
function stopmd()
{
    local md_dev=$1
    [ "$md_dev" ]
    tc_break_if_bad $? "md device not passed to stopmd" || exit
    local count=10
    while ((--count)) ; do
        mdadm -S $md_dev &>$stdout && return    # OK, it stopped
        tc_info "Waiting to try stop again ..."
        sleep 1
    done
    ((count==0))
}

function tc_local_setup()
{
    dd if=/dev/zero of=$TCTMP/1 bs=10240 count=2048 &>/dev/null
    dd if=/dev/zero of=$TCTMP/2 bs=10240 count=2048 &>/dev/null
    dd if=/dev/zero of=$TCTMP/3 bs=10240 count=3072 &>/dev/null
    part1=`losetup --show -f $TCTMP/1 2>$stderr`
    part2=`losetup --show -f $TCTMP/2 2>>$stderr`
    part3=`losetup --show -f $TCTMP/3 2>>$stderr`

    [ "x$part1" != "x" -a "x$part2" != "x" -a "x$part3" != "x" ] || tc_break_if_bad 1 "Unable to allocate loop devices" || exit
    [ -e /etc/mdadm.conf ] && mv /etc/mdadm.conf /etc/mdadm.conf.bak

      tc_check_package $sendmail_service
    if [ $? -eq 0 ]; then
	mail_service="sendmail"
	restore_service="postfix"
    else
      tc_check_package $sendmail_service
	if [ $? -eq 0 ]; then
		mail_service="postfix"
	fi
    fi

    		
    # Check if postfix is running   
    if [ $restore_service ]; then
    	tc_service_status $restore_service
    	if [ $? -eq 0 ]; then
        	service_cleanup=1
        	tc_service_stop_and_wait $restore_service
    	fi 
    fi
    tc_service_status $mail_service
    if [ $? -ne 0 ]; then
    	tc_service_start_and_wait $mail_service
        mail_service_cleanup=1
    fi
   
    return 0
}

function tc_local_cleanup()
{
    stopmd /dev/md0
    stopmd /dev/md1
    stopmd /dev/md2
    stopmd /dev/md3
    losetup -d $part1 &>/dev/null
    losetup -d $part2 &>/dev/null
    losetup -d $part3 &>/dev/null
    [ -e /etc/mdadm.conf.bak ] && mv /etc/mdadm.conf.bak /etc/mdadm.conf

    if [ $mail_service_cleanup ]; then
	tc_service_stop_and_wait $mail_service
    fi

    # Restore status of postfix prior to test execution
    if [ $service_cleanup ]; then
        tc_service_stop_and_wait $mail_service
        tc_service_start_and_wait $restore_service
    fi
 
}

################################################################################
# testcase functions
################################################################################

function TC_create()
{   
    # make sure /dev/md0 is not active
    stopmd /dev/md0
    tc_fail_if_bad $? "Unexpected response from \"mdadm -S /dev/md0\"" || return
        
    tc_info "create an array with level raid0"  
    yes|mdadm -Cv /dev/md0 -l0 -n2 -c128 $part1 $part2 &>$stdout
    tc_fail_if_bad $? "Unexpedcted response from \"mdadm -Cv /dev/md0 -l0 -n2 -c128 $part1 $part2\"" || return

    grep -q started $stdout
    tc_fail_if_bad $? "Didn't see \"started\" in output" || return

    tc_info "create file:/etc/mdadm.conf"   
    echo -e "DEVICE  $part1 $part2 $part3" >/etc/mdadm.conf 
    mdadm --detail --scan >> /etc/mdadm.conf
    tc_fail_if_bad $? "unexpected response from \"mdadm --detail --scan \"" || return

    grep -q "md0" /etc/mdadm.conf
    tc_pass_or_fail $? "mdadm --detail --scan failed"
}

function TC_start()
{
    stopmd /dev/md0
    tc_fail_if_bad $? "Unexpected response from \"mdadm -S /dev/md0\"" || return
    
    tc_info "start an array"
    mdadm -A /dev/md0 &>$stdout
    tc_fail_if_bad $? "unexpected response from \"mdadm -A /dev/md0\"" || return

    grep -q start $stdout
    tc_fail_if_bad $? "expected to see \"start\" in output" || return

    tc_info "waiting for device to settle down"
    sleep 1
    
    tc_info "start an array using UUID"
    stopmd /dev/md0
    tc_fail_if_bad $? "Unexpected response from \"mdadm -S /dev/md0\"" || return

    mdadm -E $part1 >$stdout 2>$stderr
    tc_fail_if_bad $? "Unexpected response from \"mdadm -E $part1\"" || return
    
    UUID=`grep 'Array UUID' $stdout | awk '{print $4}'`
    tc_info "UUID for the device : $UUID"
    mdadm -Av /dev/md0 -u $UUID &>$stdout
    tc_fail_if_bad $? "Unexpected response from \"mdadm -Av /dev/md0 -u $UUID\"" || return

    grep -q start $stdout
    tc_fail_if_bad $? "expected to see \"start\" in output" || return

    tc_info "waiting for device to settle down"
    sleep 1

    stopmd /dev/md0
    tc_pass_or_fail $? "Unexpected response from \"mdadm -S /dev/md0\"" || return
}

function TC_manage()
{
    stopmd /dev/md1
    tc_fail_if_bad $? "Unexpected response from \"mdadm -S /dev/md1\"" || return

    tc_info "create an array with multipath level"
    #yes|mdadm -Cv /dev/md1 -c128 --level=multipath --raid-devices=2 $part1 $part2 #&>$stdout
    yes|mdadm -Cv /dev/md1 --level=1 --raid-devices=2 $part1 $part2 &>$stdout
    tc_fail_if_bad $? "Unexpedcted response from \"mdadm -Cv /dev/md1 -c128 --level=multipath --raid-devices=2 $part1 $part2\"" || return

    grep -q start $stdout
    tc_fail_if_bad $? "expected to see \"start\" in output" || return

    mdadm --detail /dev/md1 &>$stdout
    tc_fail_if_bad $? "unexpected response from \"mdadm --detail --scan \"" || return

    #grep -q multipath $stdout
    grep -q raid1 $stdout
    tc_fail_if_bad $? "Expected to see \"multipath\" in stdout" || return

    tc_info "waiting for device to settle down"
    sleep 1

    tc_info "fail $part1 from /dev/md1"
    mdadm /dev/md1 --fail $part1 &>$stdout
    tc_fail_if_bad $? "fail $part1 failed" || return

    tc_info "waiting for device to settle down"
    sleep 1

    tc_info "remove $part1 from /dev/md1"
    mdadm /dev/md1 --remove $part1 &>$stdout
    tc_fail_if_bad $? "remove $part1 failed" || return  

    tc_info "waiting for device to settle down"
    sleep 1

    tc_info "add $part1 to /dev/md1"
    #making the super block zeros. Ref: http://permalink.gmane.org/gmane.linux.raid/34977 
    mdadm --zero-superblock $part1
    mdadm /dev/md1 --add $part1 &>$stdout
    tc_fail_if_bad $? "mdadm add array failed" || return

    tc_info "waiting for device to settle down"
    sleep 1
    
    stopmd /dev/md1
    tc_pass_or_fail $? "unexpected response from \"mdadm -S /dev/md1\""
}

function TC_grow()
{
    stopmd /dev/md2
    tc_fail_if_bad $? "Unexpected response from \"mdadm -S /dev/md2\"" || return
        
    tc_info "create md /dev/md2 -n2 -z 1024 $part1 $part2"
    yes|mdadm -Cv /dev/md2 -l1 -n2 -z 1024 $part1 $part2 &>$stdout
    tc_fail_if_bad $? "Unexpedcted response from \"mdadm -Cv /dev/md2 -l1 -n2 -z 1024 $part1 $part2\"" || return

    grep -q start $stdout
    tc_fail_if_bad $? "expected to see \"start\" in output" || return

    mdadm --detail --scan >>/etc/mdadm.conf
    tc_fail_if_bad $? "unexpected response from \"mdadm --detail --scan \"" || return
        
    tc_info "add a new device $part3"
    mdadm --add /dev/md2 $part3 &>$stdout
    tc_fail_if_bad $? "unexpected response from \"mdadm --add /dev/md2 $part3\"" || return

    cat /proc/mdstat|grep -q -e '\[UU\]$' &>/dev/null
    tc_fail_if_bad $? "expect to see [UU] in /proc/mdstat" || return

    sleep 5	# let the --add settle down so md2 not busy for next test

    tc_info "mdadm grow -n 3"
    mdadm --grow -n 3 /dev/md2 &>$stdout
    tc_fail_if_bad $? "unexpected response from \"mdadm --grow -n 3 /dev/md2\"" || return

    cat /proc/mdstat >$stdout
    grep -e '\[UU_\]$' $stdout &>/dev/null || grep -e '\[UUU\]$' $stdout  &>/dev/null
    tc_fail_if_bad $? "expected to see \"UU_\" or \"UUU\" in output" || return

    cat /proc/mdstat | grep -e '\[UU_\]$' &>/dev/null
    tmp=$?
    if [ "$tmp" -eq "0" ];
    then
        tc_info "rebuild ..." 
        while [ $tmp -eq "0" ]
        do 
        sleep 5
        cat /proc/mdstat | grep -e '\[UU_\]$' &>/dev/null
        tmp=$?
        done
    fi

    tc_info "mdadm grow -z 1024 to 2048"        
    mdadm --grow -z 2048 /dev/md2 &>$stdout
    tc_fail_if_bad $?  "unexpected response from \"mdadm --grow -z 2048 /dev/md2\"" || return

    tc_info "waiting for device to settle down"
    sleep 2 # RCP Don't know if this is needed
            # failed on PPC but ran OK by hand (even w/o sleep)
            # so there might be a timing problem

    mdadm -D /dev/md2 >$stdout 2>$stderr
    tc_fail_if_bad $?  "unexpected response from \"mdadm -D /dev/md2\"" || return

    grep -e 'Dev.* Size' $stdout | grep 2048 &>/dev/null
    tc_fail_if_bad $? "mdadm grow size -z failed" || return

    tc_info "waiting for device to settle down"
    sleep 1
    
    stopmd /dev/md2
    tc_pass_or_fail $? "unexpected response from \"mdadm -S /dev/md2\""
}


function TC_monitor()
{

    # create an array with raid1 level
    stopmd /dev/md3
    tc_fail_if_bad $? "Unexpected response from \"mdadm -S /dev/md3\"" || return

    yes|mdadm -Cv /dev/md3 -l1 -n2 -c128 $part1 $part2 &>$stdout
    tc_fail_if_bad $? "Unexpedcted response from \"mdadm -Cv /dev/md3 -l1 -n2 -c128 $part1 $part2\"" || return

    grep -q start $stdout
    tc_fail_if_bad $? "expected to see \"start\" in output" || return

    mdadm --detail --scan >> /etc/mdadm.conf
    tc_fail_if_bad $? "unexpected response from \"mdadm --detail --scan \"" || return

    tc_info "monitor /dev/md3"
    tc_add_user_or_break "monitor" &>/dev/null

    # before checkingmail function, be sure the mail system is working
    tc_wait_for_no_mail monitor
    tc_break_if_bad $? "Could not delete old mail for monitor" || return
    mail -s "Test simple mail" monitor@$(hostname -f) <<< 'Hello Sailor' 2>$stderr 1>$stdout
    tc_break_if_bad $? "unable to send email to monitor@$(hostname -f)" || return
    tc_wait_for_mail monitor
    tc_break_if_bad $? "trial email to monitor@$(hostname -f) was not received" || return
    tc_wait_for_mail_text monitor "Sailor"
    tc_break_if_bad $? "expected to see Sailor in stdout" || return
    tc_wait_for_no_mail monitor
    tc_break_if_bad $? "Could not delete old mail for monitor after trial run system" || return
    tc_info "Mail system is working for monitor"

    mdadm --monitor -m monitor -d 30 -f /dev/md3 >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"mdadm --monitor -m monitor -d 30 -f /dev/md3\"" || return

    PID=`cut -d" " -f1 $stdout`
    mdadm /dev/md3 --fail $part1 &>$stdout

    tc_wait_for_mail monitor
    tc_fail_if_bad $? "Mail for monitor not received" || return
    tc_wait_for_mail_text monitor mdadm &&
    tc_wait_for_mail_text monitor monitor &&
    tc_wait_for_mail_text monitor md3
    tc_fail_if_bad $? "expected to see \"mdadm\", \"monitor\" and \"md3\" in email" || return

    tc_info "kill the monitor process: $PID"
    kill -9 $PID &>/dev/null

    tc_info "waiting for device to settle down"
    sleep 1
    
    stopmd /dev/md3
    tc_pass_or_fail $? "unexpected response from \"mdadm -S /dev/md3\""
}

################################################################################
# main
################################################################################

tc_setup

tc_exec_or_break  $REQUIRED || exit

for cmd in $commands
do
    tc_register "$cmd"
    TC_$cmd || exit
done
