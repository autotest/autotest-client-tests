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
### File :        powerpc-utils.sh
##
### Description:  This testcase tests utilities in the powerpc-utils,
##
###               see 00_Descriptions.txt for those not tested.
##
### Author:       rende@cn.ibm.com
###########################################################################################
### source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/powerpc_utils
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/powerpc_utils
EVENT=$TESTDIR/rtas_events/v6_memory_info
NUM=0
WIDTH=8

## Removing vscsisadmin from commands list as it is removed from spec

commands="lsprop nvsetenv activate_firmware bootlist hvcsadmin nvram ofpathname rtas_dump rtas_event_decode rtas_ibm_get_vpd serv_config  set_poweron_time  uesensor update_flash"

function test00()
{
	tc_register "installation check"
	## Add check vscsisadmin if its later added to spec
	which vscsisadmin &>/dev/null
	[ $? -eq 0 ] && commands="$commands vscsisadmin" 
	tc_executes $commands
	tc_pass_or_fail $? "powerpc-utils not installed properly"
}

# bootlist calls nvram and ofpathname, which are treat as implicitly tested
function test_bootlist()
{
	tc_register "bootlist"
	subtest=("-r -m normal" "-r -m service" "-r -m both" "-o -m normal") 

	i=0
	while [ $i -lt 4 ] ; do
		tc_info "bootlist ${subtest[$i]}"
		bootlist ${subtest[$i]} >$stdout 2>$stderr 
		tc_fail_if_bad $? "failed" || return
		let i+=1
	done

	tc_pass_or_fail 0
}

function test_nvsetenv()
{
        tc_register "nvsetenv"

        nvsetenv input-device >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response from nvsetenv input-device" || return

        OrigVal=${stdout#input-device=}

        nvsetenv input-device comx
        nvsetenv input-device | grep comx | grep -vq grep
        tc_fail_if_bad $? "failed to set nvram input-device" || return

        nvsetenv input-device $OrigVal
        tc_pass_or_fail $? "failed to restore nvram input-device" || return
}

function test_activate_firmware()
{
	tc_info "activate_firmware: not for manual invoke"
}



function test_rtas_dump()
{
	tc_register "rtas_dump"
 	subtest=("-f $EVENT -w $WIDTH" "-f $EVENT -d" "-f $EVENT -n $NUM" "-f $EVENT -v")

        i=0
        while [ $i -lt 4 ] ; do
                tc_info "rtas_dump ${subtest[$i]}"
                rtas_dump ${subtest[$i]} >$stdout 2>$stderr
                tc_fail_if_bad $? "failed" || return
                let i+=1
        done

	rtas_dump -f $EVENT >$stdout 2>$stderr
	tc_pass_or_fail $? "rtas_dump failed"
} 
################################################################################
# main
################################################################################
TST_TOTAL=1

tc_setup

test00 || exit	# installation check
test_bootlist
test_nvsetenv
test_activate_firmware
test_rtas_dump
