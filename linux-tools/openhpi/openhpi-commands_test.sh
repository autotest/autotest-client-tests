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
## File :   openhpi-commands_test.sh
##
## Description: This program tests basic functionality of openhpi-commands .
##
## Author:   Dang En Ren <rende@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/openhpi
source $LTPBIN/tc_utils.source

declare -a TESTLIST

# installed commands
INSTALLED="hpialarms hpievents hpireset hpiinv hpiel hpisensor hpisettime hpiwdt hpitree hpitop hpipower"

IPMI_PORT=4743

################################################################################
#   Utility functions
################################################################################

#
# local setup
#
function tc_local_setup()
{
    # save original openhpi.conf
    [ -e /etc/openhpi/openhpi.conf ] && mv /etc/openhpi/openhpi.conf $TCTMP
    cat > /etc/openhpi/openhpi.conf <<-EOF
        plugin  libsimulator
        handler libsimulator {
            entity_root = "{SYSTEM_CHASSIS,1}"
            name = "test"
        }
	EOF
    chmod 600 /etc/openhpi/openhpi.conf
    # These eliminated so as not to mess up system
    #   "hpipower -d"
    #   "hpipower -p"
    #   "hpipower -r"

    TESTLIST=(
        "hpialarms"
        "hpialarms -c 1"
        "hpialarms -c 0"
        "hpialarms -m 1"
        "hpialarms -m 0"
        "hpievents "
        "hpievents -X"
        "hpireset"
        "hpiinv"
        "hpiinv -X"
        "hpiel"
        "hpiel -c"
        "hpiel -d"
        "hpiel -p"
        "hpiel -r"
        "hpisensor -t"
        "hpisettime -d 06/28/2004 -t 18:00:00 -X"
        "hpiwdt -r"
        "hpiwdt -e"
        "hpiwdt -d"
        "hpitree"
        "hpitop"
        "hpitop -w"
        "hpitop -i"
        "hpitop -a"
    )
    TST_TOTAL=${#TESTLIST[*]}
    ((TST_TOTAL+=1))            # Account forr test01

    tc_service_start_and_wait openhpid
    tc_break_if_bad $? "Bad status from tc_service_start_and_wait openhpid" || return
    tc_wait_for_active_port $IPMI_PORT
    tc_break_if_bad $? "openhpid not listening to port $IPMI_PORT" || return
}

function tc_local_cleanup()
{
    # restore saved files
    tc_service_stop_and_wait openhpid
    [ -e $TCTMP/openhpi.conf ] && mv $TCTMP/openhpi.conf /etc/openhpi/
}

################################################################################
#   Test functions
################################################################################

#
# test01    Installation check
#
function test01()
{
    tc_register "openhpi-commands installation check"
    tc_executes $INSTALED
    tc_pass_or_fail $? "openhpi-commands not installed properly"
}

#
# test02    Test openhpi-commands 
#
function test02()
{
    for cmd in "${TESTLIST[@]}" ; do
        tc_register "$cmd"
        $cmd >$stdout 2>$stderr
        tc_pass_or_fail $? "$cmd failed"
    done
}

#
#  test03   Verify hpisettime
#
function test03()
{
    tc_register hpisettime
    tc_exec_or_break date || return

    # get current date and time
    set $(date +"%m %d %Y %H %M %S")
    month=$1; day=$2; year=$3; hour=%4; min=$5; sec=$6

    # set date forward 1 year
    (( ++year ))
    hpisettime -d $month/$day/$year -t $hour:$min$sec >$stdout 2>$stderr
    set $(date +%Y)
    [ "$1" -eq $year ]
    tc_fail_if_bad $? "Expected year to be set to $year but it was $1" || return

    # restore date
    (( --year ))
    hpisettime -d $month/$day/$year -t $hour:$min$sec >$stdout 2>$stderr
    tc_pass_or_fail $? "Unexpected response while restoring date"
}

################################################################################
#   main
################################################################################

tc_setup

tc_root_or_break || exit

test01 &&
test02

#  dummy plugin does not actually set system time, ignored
#test03
