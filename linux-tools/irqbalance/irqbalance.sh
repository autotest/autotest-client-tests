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
## File :        irqbalance.sh
##
## Description:  Test the irqbalance command.
##
## Author:       Madhuri Appana, madhuria@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
irqd="irqbalance"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    rpm -q "irqbalance" >$stdout 2>$stderr
    tc_break_if_bad $? "irqbalance package is not installed"
	
    # Check if the machine is multiprocessor or not
    proc_no=`grep -c processor /proc/cpuinfo`
    if [ $proc_no -eq 1 ]; then
        tc_info "irqbalance is not supported on single cpu machines"
        exit	
    fi

    #Backup the irqbalance configuration file
    cp /etc/sysconfig/irqbalance /etc/sysconfig/irqbalance.orig

    tc_service_status $irqd
    irqbalance_status=$?
    if [ $irqbalance_status -ne 0 ]; then 
        tc_service_start_and_wait $irqd
    fi
}

function tc_local_cleanup()
{
	#Restrore the original configuration file
	mv /etc/sysconfig/irqbalance.orig /etc/sysconfig/irqbalance
	
	if [ $irqbalance_status -ne 0 ]; then	
        tc_service_stop_and_wait $irqd
        tc_fail_if_bad $? "Failed to disable irqbalance daemon"
    else
        tc_service_restart_and_wait $irqd
        tc_fail_if_bad $? "Failed to restart irqbalance daemon"
    fi
}

function test01()
{
    tc_register "Test irqbalance command"
    # execute the test
    irqbalance  >$stdout 2>$stderr
    tc_pass_or_fail $? "Failed to start irqbalance"
    tc_service_stop_and_wait $irqd
    tc_fail_if_bad $? "Failed to stop irqbalance daemon"
}

function test02()
{
    tc_register "Testing irqbalance --oneshot"
    # execute the test
    irqbalance  --oneshot >$stdout 2>$stderr
    tc_fail_if_bad $?  "Failed to start irqbalance --oneshot"

    irq_pid=`ps -ef | grep "irqbalance --oneshot" | grep -v grep | awk  '{print $2}'`

    # wait for irqbalance --oneshot process to expire
    tc_wait_for_no_pid $irq_pid 20
    tc_break_if_bad $? "irqbalance --oneshot failed"
    
    # service irqbalance exits with non-zero status when it is inactive.
    tc_service_status $irqd  
    if [ $? -ne 0 ]; then
	    tc_pass
    else
	    tc_fail "irqbalance --oneshot failed"
    fi

}

function test03()
{
    tc_register "Check the functionality of irqbalance by enabling IRQBALANCE_ONESHOT=yes in configuration file "
    sed -e 's/^#IRQBALANCE_ONESHOT=/IRQBALANCE_ONESHOT=yes/' -i /etc/sysconfig/irqbalance 
    # execute the test
    tc_service_restart_and_wait $irqd
    tc_fail_if_bad $? "Failed to start irqbalance with IRQBALANCE_ONESHOT configuration" || return   
 
    # wait for irqbalance --oneshot daemon to exit
    tc_wait_for_no_service $irqd 20
    tc_pass_or_fail $? "Failed to check the functionality of irqbalance --oneshot with IRQBALANCE_ONESHOT=yes"
}

################################################################################
################################################################################
# main
################################################################################
tc_setup
TST_TOTAL=3
test01
test02
test03
