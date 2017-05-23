#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
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
### File :        device-mapper-persistent-data                                           ##
##
### Description: This testcase tests device-mapper-persistent-datapackage                 ##
##
### Author: Ramya BS , ramya@linux.vnet.ibm.com                                           ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/device_mapper_persistent_data
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/device_mapper_persistent_data"

function tc_local_setup()
{

	# install check
        tc_check_package device-mapper-persistent-data
        tc_break_if_bad $? "device-mapper-persistent-data package  not installed"
	

}

################################################################################
# testcase functions                                                           #
################################################################################
#
# Function:             runtests
#
# Description:          - test device-mapper-persistent-data
#
# Parameters:           - none
#
# Return                - zero on success
#                       - return value from commands on failure
################################################################################

function run_test()
{
	pushd $TESTS_DIR/unit-tests &>/dev/null
	test="unit_tests"
	tc_register "Test $test"
	./$test >$stdout 2>$stderr
	RC=$?
	grep -q "FAILED" $stderr || cat /dev/null > $stderr
	tc_pass_or_fail $RC "$test failed"	
	popd &>/dev/null
}


##############################################
#MAIN                                        #
##############################################
TST_TOTAL=1
tc_setup && \
run_test

