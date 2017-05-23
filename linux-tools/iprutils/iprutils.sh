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
## File :    iprutils.sh
##
## Description:  Test iprutils package
##
## Author:   snehal@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TESTDIR=${LTPBIN%/shared}/iprutils
REQUIRED=lspci

# environment functions
################################################################################
#
# local setup
#
function tc_local_setup()
{
        tc_exec_or_break $REQUIRED || return
      tc_check_package iprutils
        tc_break_if_bad $? "iprutils is not installed properly"
}

function tc_check_raid_card()
{
        tc_register "Checkin RAID controller"
        lspci  | grep -i raid | grep -i ibm 1>$stdout 2>$stderr
        if [ $? -ne 0 ]; then
            tc_conf "raid bus controller not present"
            return 1
        fi
        tc_pass_or_fail 0

        tc_check_kconfig CONFIG_SCSI_IPR_TRACE        
        tc_break_if_bad $? "CONFIG_SCSI_IPR_TRACE kernel configuration not enabled"

        tc_check_kconfig CONFIG_SCSI_IPR_DUMP
        tc_break_if_bad $? "CONFIG_SCSI_IPR_DUMP kernel configuration not enabled"

}

################################################################################
# Testcase functions
################################################################################
function run_test()
{

        # Read model name
        model_1_name=`iprconfig -c show-alt-config | awk '{print $1}' | sed -n 3p`
        product_id_1=`iprconfig -c show-alt-config | awk '{print $4}' | sed -n 3p`
        ios_model_1=`iprconfig -c show-ioas | awk '{print $1}' | sed -n 3p`

        # Read model number of first model name
        model_1_number=`iprconfig -c show-details $model_1_name  | sed -n 3p | awk '/Machine Type/ {print $NF}'`

        ############# iprconfig tests #################
        tc_register "iprconfig -c show-config "
        #Check if iprconfig -c show-config is not blank 
        test $model_1_name != ""
        tc_pass_or_fail $? "Model Name is blank"
          
        tc_register "iprconfig -c show-alt-config " 
        #Check if iprconfig -c show-alt-config is not blank 
        test $product_id_1 != ""   
        tc_pass_or_fail $? "Product Id is blank"

        tc_register "iprconfig -c show-ioas"
        #Check if iprconfig -c show-ioas is not blank 
        test $ios_model_1 != ""   
        tc_pass_or_fail $? "ios Model Name is blank"

        tc_register "iprconfig compare model number with product id"
        test $product_id_1 == $model_1_number
        tc_pass_or_fail $? "'Product ID' and 'Machine Type and Model' does not match"

        tc_register "iprconfig -c query-ucode-level<>"
        #check if iprconfig -c query-ucode-level is not blank 
        micro_code_1=`iprconfig -c query-ucode-level $model_1_name`
        test $micro_code_1 != ""   
        tc_pass_or_fail $? "micro-code is blank"
        
        tc_register "iprconfig adapter operational"
        # Check if Adapter is operational
        adapter_status=`iprconfig -c show-config | sed -n 3p | awk '/RAID Adapter/ {print $NF}'`
        test $adapter_status == "Operational"
        tc_pass_or_fail $? "Adapter is not operational" 


        ############# iprupdate tests ####################
        tc_register "iprupdate"
        iprupdate_version=`iprupdate --version | awk '{print $2}'`
        test $iprupdate_version != ""
        tc_pass_or_fail $? "iprupdate version is blank" 
        

        ############# iprdump tests ###################
        tc_register "iprdump version check"
        iprdump_version=`iprdump --version | awk '{print $2}'`
        test $iprdump_version != ""
        tc_break_if_bad $? "iprdump version is blank" 


        #Check if iprdump deamon is running
        tc_register "iprdump deamon status"
	tc_service_restart_and_wait iprdump
        ps -ef | grep -v grep | grep iprdump
        tc_pass_or_fail $? "iprdump deamon is not running"

        ############# iprinit tests ####################
        tc_register "iprinit version check"
        iprinit_version=`iprinit --version | awk '{print $2}'`
        test $iprinit_version != ""
        tc_break_if_bad $? "iprinit version is blank" 

        #Check if iprinit deamon is running
        tc_register "iprinit deamon status"
	tc_service_restart_and_wait iprinit
        ps -ef | grep -v grep | grep iprinit
        tc_pass_or_fail $? "iprinit deamon is not running"

        ############# iprdbg tests ####################
        tc_register "iprbg"
        iprdbg_adapter_1=`expect -c 'spawn iprdbg;expect Selection:; send 4\r' |  awk '{print $NF}' | sed -n 4p | sed 's/.$//'`
        ios_model_1=/dev/$ios_model_1
        test $iprdbg_adapter_1 == $ios_model_1
        tc_pass_or_fail $? "Adapter does not match"
}
tc_setup
tc_check_raid_card || exit
TST_TOTAL=12
run_test
