#!/bin/sh
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
## File :        sysstat.sh
##
## Description:  This testcase tests the sysstat package, and sar, iostat subpackages.
##
## Author:       CSDL ldy (liudeyan@cn.ibm.com)
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

CMD_sar=/usr/bin/sar
CMD_iostat=/usr/bin/iostat
CMD_mpstat=/usr/bin/mpstat
CMD_sadf=/usr/bin/sadf
CMD_sadc=/usr/lib/sa/sadc ; [ -e /usr/lib64/sa/sadc ] && CMD_sadc=/usr/lib64/sa/sadc
DATAFILE=${TCTMP}/sar$$

ALL_CMDS="$CMD_sar $CMD_iostat $CMD_mpstat $CMD_sadf $CMD_sadc"

REQUIRED="grep wc tail df"

ROOT_PRTN=""
ROOT_PRTN_NAME=""
ROOT_DEV=""
ROOT_DEV_NAME=""

#
# sets global variables for root device. Examples:
#
#       ROOT_PRTN=/dev/sda3
#       ROOT_PRTN_NAME=sda3
#       ROOT_DEV=/dev/sda
#       ROOT_DEV_NAME=sda
#       
function get_root_dev()
{
        df -P / >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response from \"df -P / \"" || return

        local zzz="$(cat $stdout | tail -1)"
        [ "$zzz" ]
        tc_break_if_bad $? "Could not determine ROOT_PRTN frrom stdout" || return
        tc_info "Root partition info: $zzz"

        ROOT_PRTN=$(set $zzz ; echo $1)
        ROOT_PRTN_NAME=$(basename $ROOT_PRTN)
        tc_info "ROOT_PRTN=$ROOT_PRTN"
        tc_info "ROOT_PRTN_NAME=$ROOT_PRTN_NAME"

	find /sys/block -name $ROOT_PRTN_NAME >$stdout 2>$stderr
        find /sys/devices -name $ROOT_PRTN_NAME >>$stdout 2>>$stderr
        tc_break_if_bad $? "could not find $ROOT_PRTN_NAME in /sys/block nor /sys/devices" || return

        local xxx="$(cat $stdout | tail -1)"
        [ "$xxx" ]
        tc_break_if_bad $? "Could not find device info in /sys/block nor /sys/devices" || return

        set $(IFS=/ ; set $xxx ; echo $@)
        local n=$(($#-1))
        ROOT_DEV_NAME=$(echo ${!n})
        ROOT_DEV=/dev/$ROOT_DEV_NAME
        tc_info ROOT_DEV=$ROOT_DEV
        tc_info ROOT_DEV_NAME=$ROOT_DEV_NAME
}

function tc_local_setup()
{
        tc_exec_or_break $REQUIRED || exit

        get_root_dev

        if ! [ "$PKG" = "iostat" ] ; then
                we_start_sysstat=""
                #sysstatinit="/etc/init.d/boot.sysstat"
                sysstatinit="sysstat"
                sysstatconf="/etc/sysstat/sysstat.cron"
                sysstatcron="/etc/cron.d/sysstat"
        fi
}

function tc_local_cleanup()
{
        if ! [ "$PKG" = "iostat" ] ; then
                if [ "$we_start_sysstat" = "yes" ]; then
                        systemctl stop $sysstatinit >/dev/null 2>&1
                fi
        fi
}

function test_install()
{
        tc_register "installation check"

        tc_executes $ALL_CMDS
        tc_pass_or_fail $? "some commands are missing in the sysstat package." || return
}

function test_service()
{
        tc_register "sar service start script" 

        systemctl status $sysstatinit >/dev/null  || {
                we_start_sysstat="yes"
                tc_service_start_and_wait $sysstatinit
        }

        #[ -h $sysstatcron ]
        #tc_fail_if_bad $? "symbolic link file $sysstatcron not found." || return

        #symlink=$(readlink $sysstatcron)
        #[ "$symlink" = $sysstatconf ]
        tc_pass_or_fail $? "Sar service does not start correctly." 
}

function test_sadc()
{
        tc_register "sadc"
        
        # Test that sadc can generate the datafile, 
        # the data file is also used by the following sar testcases.
        tc_is_busybox $CMD_sadc
        [ $? -ne 0 ]
        tc_break_if_bad_rc $? "$CMD_sadc is from busybox" || return 
        $CMD_sadc -F 1 10 $DATAFILE &>/dev/null && [ -f "$DATAFILE" ]
        tc_pass_or_fail $? "sadc can not create the system activity data file."
}

function test_sar()
{
        tc_register "sar"
        tc_is_busybox $CMD_sar
        [ $? -ne 0 ]
        tc_break_if_bad_rc $? "$CMD_sar is from busybox" || return
        $CMD_sar -f $DATAFILE >$stdout 2>$stderr &&
                grep -q -E "CPU|%user|Average" $stdout
        tc_pass_or_fail $? "cpu activity is not found in the default output of sar."

        tc_register "sar -u 2 5"
        $CMD_sar -u 2 5 >$stdout 2>$stderr
        tc_fail_if_bad $? "sar -u 2 5 failed."
        set `grep -w all $stdout|wc -l`
        [ $1 -eq 6 ]
        tc_pass_or_fail $? "incorrect output counts of sar -u 2 5."
}

function test_iostat()
{
        tc_register "iostat"
        tc_is_busybox $CMD_iostat
        [ $? -ne 0 ]
        tc_break_if_bad_rc $? "$CMD_iostat is from busybox" || return
        $CMD_iostat >$stdout 2>$stderr &&
                grep -q "idle" $stdout && grep -q "avg-cpu" $stdout
        tc_pass_or_fail $? "Incorrect output of cpu status."

        tc_register "iostat -d"
        $CMD_iostat -d >$stdout 2>$stderr &&
                grep -q "Device" $stdout 
        tc_pass_or_fail $? "Incorrect output of disk device status."

        tc_register "iostat -d 2 6"
        $CMD_iostat -d 2 6 >$stdout 2>$stderr &&
                grep "Device" $stdout | wc -l | grep -q "6"
        tc_pass_or_fail $? "Incorrect output counts of iostat -d 2 6."
        
        tc_register "iostat -x $ROOT_PRTN"
        $CMD_iostat -x $ROOT_PRTN >$stdout 2>$stderr &&
                grep -q $ROOT_PRTN_NAME $stdout
        tc_pass_or_fail $? "failed to find extended disk statistics for $ROOT_PRTN."

        tc_register "iostat -p $ROOT_DEV"
        $CMD_iostat -p $ROOT_DEV >$stdout 2>$stderr &&
                grep -q $ROOT_PRTN_NAME $stdout
        tc_pass_or_fail $? "failed to find $ROOT_PRTN_NAME."
}

function test_mpstat()
{
        tc_register "mpstat -A"
        tc_is_busybox $CMD_mpstat
        [ $? -ne 0 ]
        tc_break_if_bad_rc $? "$CMD_mpstat is from busybox" | return
        $CMD_mpstat -A >$stdout 2>$stderr &&
                grep -q "intr/s" $stdout && grep -q "all" $stdout
        tc_pass_or_fail $? "failed to get status report."       
        tc_register "mpstat 2 5"
        $CMD_mpstat 2 5 >$stdout 2>$stderr && 
                grep -w "all" $stdout | wc -l | grep -q "6"
        tc_pass_or_fail $? "Incorrect counts of output lines."
}

function test_sadf()
{
        tc_register "sadf -d"       
        tc_is_busybox $CMD_sadf
        [ $? -ne 0 ]
        tc_break_if_bad_rc $? "$CMD_sadf is from busybox" || return            
        $CMD_sadf -d $DATAFILE >$stdout 2>$stderr &&
                grep -q ";" $stdout
        tc_pass_or_fail $? "failed to generate database friendly outputs."

        tc_register "sadf -x"
        $CMD_sadf -x $DATAFILE >$stdout 2>$stderr &&
                grep -q "<sysstat>" $stdout && grep -q "</sysstat>" $stdout
        tc_pass_or_fail $? "failed to generate xml formated outputs."
}

#########################
#  main
#########################

TST_TOTAL=14
tc_setup
test_install &&
test_service &&
test_sadc &&
test_sar &&
test_iostat &&
test_mpstat &&
test_sadf
