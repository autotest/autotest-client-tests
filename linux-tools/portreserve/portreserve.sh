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
### File :        portreserve.sh                                               ##
##
### Description: This testcase tests portreserve package                       ##
##
### Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
lock_path=/var/lock

function tc_local_setup()
{
    tc_root_or_break
    tc_exec_or_break portreserve portrelease

    [ -d /etc/portreserve ]
    tc_break_if_bad $? "portreserve is not installed properly"

    ## find a free port to use
    #The Dynamic and/or Private Ports are those from 49152 through 65535
    tc_find_port 49152
    [ $? -eq 0 ] || {
        tc_info "No free port found...So exit"
        exit 0
    }
    ## Create a dummy service
    [ -e /etc/services ]
    tc_break_if_bad $? "/etc/services not found" || exit
    cp /etc/services /etc/services.bak
    echo "dummy_portreserve_srv $TC_PORT/tcp" >>/etc/services
    echo "dummy_portreserve_srv $TC_PORT/udp" >>/etc/services

    tc_service_start_and_wait xinetd 
    tc_break_if_bad $? "dummy_portreserve not started" || exit

    echo "dummy_portreserve_srv" >/etc/portreserve/dummy_portreserve
}

function tc_local_cleanup()
{
    rm -rf /etc/portreserve/dummy_portreserve
    tc_service_restart_and_wait portreserve
    mv /etc/services.bak /etc/services
    tc_service_restart_and_wait xinetd 
}

# Check portreserve which is called throuh portreserve initscript.
function test01()
{
    tc_register "Test portreserve"
    tc_service_start_and_wait portreserve
    tc_fail_if_bad $? "portreserve couldnt be started" || return
    sleep 1
    netstat -nlp | grep $TC_PORT| grep portreserve >$stdout 2>$stderr
    tc_pass_or_fail $? "portreserve failed to reserve port $TC_PORT"
}

# check portrelease
function test02()
{
    tc_register "Test portrelease"
    portrelease dummy_portreserve >$stdout 2>$stderr
    tc_wait_for_inactive_port $TC_PORT
    tc_pass_or_fail $? "portrelease failed to release port $TC_PORT"
}
#
# main
#
TST_TOTAL=2
tc_setup
test01 && test02 
