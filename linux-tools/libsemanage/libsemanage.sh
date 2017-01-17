#!/bin/bash
############################################################################################
## copyright 2003, 2016 IBM Corp                                                          ##
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
## File       : libsemanage.sh                                                		  ##
##                                                                            		  ##
## Description: This testcase tests "libsemanage" package                     		  ##
##                                                                            		  ##
## Author     : Ramesh YR, rameshyr@linux.vnet.ibm.com                        		  ##
##              Athira Rajeev, atrajeev@in.ibm.com                                        ##
############################################################################################
#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libsemanage
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libsemanage/tests"

function tc_local_setup()
{
    ls /usr/lib*/libsemanage.so* /etc/selinux/semanage.conf &>/dev/null
    tc_break_if_bad $? "libsemanage not installed" || return

    # create user
    tc_add_user_or_break
    USER=$TC_TEMP_USER
}

function run_test()
{
    pushd $TESTS_DIR &>/dev/null
    TEST=libsemanage-tests
    tc_register "libsemanage-tests"

    cp * /home/$USER
    su - $USER -c "./libsemanage-tests" 1>$stdout 2>$stderr
    RC=$?
    ##Test returns with return code 0 on failure so grep stdout for FAILS
    if [ $RC -ne 0 ];then
       tc_fail "$TEST failed"
    else
    	grep -q FAIL $stdout
	if [ $? -eq 0 ];then
          tc_fail "$TEST failed"
	else
          tc_pass "$TEST passed"
       fi
    fi
}

#
# main
#
tc_setup && \
run_test

