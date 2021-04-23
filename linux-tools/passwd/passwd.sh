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
## File :        passwd.sh
##
## Description:  Test the passwd command.
##
## Author:       Kumuda G, kumuda@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

REQUIRED="passwd"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    tc_root_or_break
    tc_exec_or_break $REQUIRED
    tc_add_user_or_break 1>$stdout 2>$stderr
}

function test01()
{
    grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
    if [ $? -ne 0 ];then  # Start of OS check
        tc_register "passwd --stdin"
    	echo PASSW0RD | passwd --stdin $TC_TEMP_USER 1>$stdout 2>$stderr
    	tc_pass_or_fail $? "Password setting using --stdin failed for $TC_TEMP_USER"
    fi

    tc_register "passwd --lock"
    passwd --lock $TC_TEMP_USER 1>$stdout 2>$stderr
    tc_pass_or_fail $? "Passwd lock failed for $TC_TEMP_USER"

    tc_register "passwd --unlock"
    passwd --unlock $TC_TEMP_USER 1>$stdout 2>$stderr
    tc_pass_or_fail $? "Failed to unlock passwd for $TC_TEMP_USER"
}

function test02()
{
    grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
    if [ $? -ne 0 ];then  # Start of OS check
    	tc_register "passwd --maximum"
    	passwd --maximum=90 $TC_TEMP_USER 1>$stdout 2>$stderr
    	tc_pass_or_fail $? "Setting maximum password lifetime to 90 Days failed"

    	tc_register "passwd --minimum"
    	passwd --minimum=30 $TC_TEMP_USER 1>$stdout 2>$stderr
    	tc_pass_or_fail $? "Setting minimum password lifetime to 30 days failed"

    	tc_register "passwd --warning"
    	passwd --warning=9 $TC_TEMP_USER 1>$stdout 2>$stderr
    	tc_pass_or_fail $? "settings to warn user before 9 days of password expiration failed"
    fi

    tc_register "passwd --inactive"
    passwd --inactive=2 $TC_TEMP_USER 1>$stdout 2>$stderr
    tc_pass_or_fail $? "Disabling user account after password inactive failed"
}
function test03()
{
    grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
    if [ $? -ne 0 ];then  # Start of OS check
    	#--keep-tokens is used to indicate that the update should only
    	#be for  expired  authentication  tokens(passwords)
    	tc_register "passwd --keep-tokens"
    	tc_info "Expecting \"Authentication token manipulation error\""
    	echo PASSW0RD |    passwd --keep-tokens $TC_TEMP_USER 1>$stdout
    	if [ $? -eq 0 ]; then
    	    tc_fail "Non expired password got changed using option --keep-tokens!"||return
    	fi
    	tc_pass
	
	#Force to unlock user password which is empty
    	tc_register "passwd --force"
    	passwd --unlock --force $TC_TEMP_USER 1>$stdout 2>$stderr
    	tc_pass_or_fail $? "Failed to force unlock passwd for $TC_TEMP_USER"
    fi


    tc_register "passwd --delete"
    passwd --delete $TC_TEMP_USER 1>$stdout 2>$stderr
    tc_pass_or_fail $? "Passwd deletion failed for $TC_TEMP_USER"

}
################################################################################
# main
################################################################################
tc_setup
grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
if [ $? -ne 0 ];then 
	TST_TOTAL=10
else
	TST_TOTAL=4
fi
test01
test02
test03
