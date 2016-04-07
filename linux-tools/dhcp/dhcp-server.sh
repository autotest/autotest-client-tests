#!/bin/bash
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
#
# File :        dhcp-server.sh
#
# Author:       Robert Paulsen, rpaulsen@us.ibm.com
#               Based on ideas from Manoj Iyer.
#
# Description:  Test dhcp server daemon.
################################################################################
# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

# global variabes
dhcpd_server_started="no"
mac_addr=""
subnet=$(hostname -i |cut -d" " -f2| cut -d"." -f1-3)
HOSTIP=$(hostname -i|cut -d" " -f2)
declare -i acnt=0       # count aliases
declare -a ALIASIPS     # aliased ip addresses
declare -a ALIASDEVS    # matching aliased devices
DEV=""                  # device for active interface
OMPORT=""               # port to use for omserver

################################################################################
# local utility functions
################################################################################

# tc_local_setup specific to this testcase.
#
function tc_local_setup()
{
    tc_root_or_break || return
        tc_exec_or_break ifconfig route killall || return
    acnt=0

    # kill any existing dhcp server
    killall dhcpd &>/dev/null

    # find an active network interface's device; put it in global DEV
    local route_data=$(route | grep default)
    [ "$route_data" ]
    tc_break_if_bad $? "No default route so can't find network interface" || return
    set $route_data
    DEV=$8
    [ "$DEV" ]
    tc_break_if_bad $? "can't find network interface" || return

    # find ort to use for omserver. Default is 7911
    tc_find_port 7911
    tc_break_if_bad $? "could not find free port" || exit
    OMPORT=$TC_PORT
}

#
# Cleanup specific to this testcase.
#
function tc_local_cleanup()
{
    ifconfig
    netstat -apen

    killall dhcpd &>/dev/null


}

################################################################################
# the testcase functions
################################################################################

#
#   Ensure dhcp-server package is installed
#
function test01()
{
    tc_register "is dhcp installed?"
    rpm -q dhcp &>/dev/null 
    tc_pass_or_fail $? "dhcpd package is not installed"
}

#
#   Start the dhcp server
#
function test02()
{
    tc_register "start dhcpd server"
    tc_exec_or_break cat grep || return

    # set up alias network

    # create dhcpd.conf file for this test
    cat > $TCTMP/dhcpd.conf <<-EOF
        omapi-port $OMPORT;
        ddns-update-style none;
        subnet $subnet.0 netmask 255.255.255.0 {
            range $HOSTIP $HOSTIP;
            default-lease-time 600;
            max-lease-time 1200;
            option routers $subnet.1;
            option subnet-mask 255.255.255.0;
            option domain-name-servers $subnet.1;
            option domain-name "dhcptest.net";
        }
EOF

    cp $TCTMP/dhcpd.conf .

    # create a empty leases file
    touch $TCTMP/dhcpd.leases

    # start the dhcpd server
    sleep 1                                                         # be sure network is fully operational
    dhcpd -cf $TCTMP/dhcpd.conf -lf $TCTMP/dhcpd.leases &>$stdout   # dhcpd stupidly puts normal
                                                                    # output in stderr.
    tc_fail_if_bad $? "bad response from dhcpd"

    tc_wait_for_active_port 7911
    tc_fail_if_bad $? "dhcpd server not listening on omapi port" || exit

    cat $stdout | grep -qi "Listening.*$subnet.*24" && \
    cat $stdout | grep -qi "Sending.*$subnet.*24"
    tc_pass_or_fail $? "cannot start dhcpd server"
}

#
#   test omshell using expect
#       $1 is the host to use
#
function omshell_test()
{
    local omserver=localhost
    [ "$1" ] && omserver=$1

    tc_register "omshell $1"
    tc_exec_or_break expect || return

    # get hardware (MAC) address for the device
    hwaddr=$(cat /sys/class/net/$DEV/address)
    [ "$hwaddr" ]
    tc_break_if_bad $? "cannot find $DEV in ifconfig output" || return
    [ "$hwaddr" ]
    tc_break_if_bad $? "cannot find MAC Adddress for $DEV in ifconfig output" || return

    # create expect script
    local expcmd=`which expect`
    local exp_script="$TCTMP/omshell_exp"
    cat > $exp_script <<-EOF
#!$expcmd -f
proc abort {} { exit 1 }
set timeout 10
spawn omshell
# connect to server
expect {
    timeout abort
    "> " { send "server $omserver \r" }
}
expect {
    timeout abort
    "> " { send "port $OMPORT \r" }
}
expect {
    timeout abort
    "> " { send "connect\r" }
}
# new local host object
expect {
    timeout abort
    "obj: <null>" { sleep 2; send "new host\r" }
}
expect {
    timeout abort
    "obj: host" { sleep 2; send "set hardware-address = $hwaddr\r" }
}
# check if there is already a host with desired hwaddr on server
expect {
    timeout abort
    "hardware-address = $hwaddr" { sleep 2; send "open\r" }
}
expect {
    timeout abort
    "not found" {
	# create the host remote object
	sleep 2; send "set hardware-type = 1 \r";
	expect {
	    timeout abort
	    "hardware-type = 1" { sleep 2; send "set name = \"$hwaddr\"\r" }
	}
	expect {
	    timeout abort
	    "name = \"$hwaddr\"" { sleep 2; send "create\r" }
	}
	exp_continue
    }
    # desired host exist
    "name =" { sleep 2; send "remove\r" }
}
expect {
    timeout abort
    "obj: <null>" { exit 0 }
}
expect eof
EOF
    chmod +x $exp_script 

    $exp_script >$stdout 2>$stderr
    tc_pass_or_fail $? "failed to produce expected output."
}

################################################################################
# main
################################################################################

TST_TOTAL=2

tc_setup                # standard setup
test01 &&
test02 &&
[ "$OMSHELL" = "yes" ] && {
    omshell_test localhost
    omshell_test $(hostname -i)
}
