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
### File :        libhbaapi.sh                                                 ##
##
### Description: This testcase tests libhbaapi  package                        ##
##
### Author:      Madhuri Appana <maappana@in.ibm.com>                          ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libhbaapi
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libhbaapi/Tests"
mod_ixgbe=0
mod_zfcp=0
function tc_local_setup()
{
        rpm -q "libhbaapi" >$stdout 2>$stderr
        tc_break_if_bad $? "libhbaapi package is not installed"
	tc_get_os_arch
    #Load zfcp module for s390x arch
    if [ "$TC_OS_ARCH" == "s390x" ]; then
        lsmod | grep zfcp >$stdout 2>$stderr
            if [ $? -ne 0 ]; then
                    modprobe zfcp >$stdout 2>$stderr
                    tc_break_if_bad $? "Failed to load zfcp module"
                    mod_zfcp=1
            fi
    else
	#Load the ixgbe kernel module
	lsmod | grep ixgbe >$stdout 2>$stderr
        if [ $? -ne 0 ]; then
                modprobe ixgbe >$stdout 2>$stderr
                tc_break_if_bad $? "Failed to load ixgbe module"
		mod_ixgbe=1
        fi
   fi

    tc_register "checking the environment for testing"
    grep -v ^# /etc/hba.conf | grep -i ".so"
    RC=$?
    if [ $RC -eq 1 ]; then
    tc_info " libraries are not mentioned in /etc/hba.conf to load "
    exit 0
    fi
}

function tc_local_cleanup()
{
        if [ $mod_ixgbe -ne 0 ]; then
                rmmod ixgbe >$stdout 2>$stderr
                tc_break_if_bad $? "Failed to remove ixgbe module"
        fi
	if [ $mod_zfcp -ne 0 ]; then
                rmmod zfcp >$stdout 2>$stderr
                tc_break_if_bad $? "Failed to remove zfcp module"
        fi
}

function run_test()
{
        pushd $TESTS_DIR &>/dev/null
      	tc_register "Test the functionality of different libhba api's"
       	./hbaapitest >$stdout 2>$stderr
	#hbaapitest binary displays Number of HBA's is 0 and not enough adapters message if HBA card is absent 
	grep -q "Number of HBA's is 0" $stdout
	if [ $? -eq 0 ]; then
		if [ `grep -ivc "not enough adapters"  $stderr` -eq 0 ]; then
        		cat /dev/null > $stderr
			tc_conf "HBA card is absent" || return
		else
			tc_fail "Failed to display. not enough adapters message"
        	fi
		exit
	fi
	#Flushing out HBA_GetFcpTargetMapping and HBA_GetFcpPersistantBinding error messages which are expected
	if [ `grep -ivc "failure of HBA_GetFcpTargetMapping"  $stderr` -eq 0 ] || [ `grep -ivc "HBA_GetFcpPersistantBinding is not supported"  $stderr` -eq 0 ]; then
                cat /dev/null > $stderr
        fi
	#Check for Adapter Attributes information
	for Adapter in "Manufacturer" "DriverName" "NumberofDiscoveredPorts" "InvalidCRCCount"
	do
		Adapter_info=`grep $Adapter $stdout | cut -d : -f2`
		if [ ! -n "$Adapter_info" ]; then
			tc_fail "Failed to display Adapter Attributes info" || return
		fi
        done
	tc_pass
        popd &>/dev/null
}
#
# main
#
TST_TOTAL=1
tc_setup
run_test 
