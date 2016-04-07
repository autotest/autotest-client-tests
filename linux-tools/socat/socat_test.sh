#!/bin/sh
############################################################################################
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
## File :    socat_test.sh
##
## Description:  Wrapper script for community test scripts for socat package
##
## Author:   Amit Gupta , amgupta9@in.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

REQUIRED_UTILS="echo grep"

REQUIRED_SCRIPTS="  proxy.sh readline-test.sh  socat_test.sh   socks4a-echo.sh  testcert.conf \
                    proxyecho.sh  readline.sh  socks4echo.sh   test.sh"

# Installation Check
function installation_check()
{
    tc_exec_or_break $REQUIRED_UTILS || return
    tc_exec_or_fail socat || return
}

function tc_local_setup ()
{
    tc_add_user_or_break || continue
}

function tc_local_cleanup ()
{
    # Make sure all the pgms by the user are killed
    ps -ef | grep "^$TC_TEMP_USER" | awk '{print $2}' | xargs kill -9
}    
function process_stdout()
{
    if grep -q FAILED $stdout ; then
       tc_fail "$test_name failed"
    elif grep -q OK $stdout ; then
       tc_pass 
    elif grep -q SKIP $stdout ; then
       tc_conf "$test_name is skipped"
    else
       tc_break "$test_name is broken"
    fi
    echo -n > $stdout
}

# Analyse output
function analysis_output()
{ 
    local newline=""
    local test_name=""
    local test_status=""
 
    TST_TOTAL=0
   
# The following is tricky. When there is a failure, the following lines
# contain some information about the failure. Capture it into stdout

# READY=1 indicates we have read a newline which could be the starting of a new test 
    READY=0
    while true; do
        read -t25 newline
        [ $? -ne 0 ] && process_stdout && break;

        # Set positional parameters to newline
	if [ "${newline:0:1}" == "-" ];
	then
		set ""
	else 
        	set $newline
	fi
        
        # If line does not being with "test ", it does not describe the status of 
        # a particular test so move on to next line.
        if [ "$1" == "test" ]; then

            # if we are processing a test output already, finish it :)
            [ "$test_name" != "" ] && process_stdout

            # If it does, then start the test logging and capture the test name.
            test_name=${3%:}

            let "TST_TOTAL++"       
        
            tc_register "$test_name"
        
        fi
        echo $newline >>$stdout
    done
} 
 
################################################################################
# main
################################################################################

cd ${LTPBIN%/shared}/socat/

tc_setup || exit           # standard tc_setup

export TC_TEMP_USER TC_TEMP_HOME
installation_check || exit
# Use process substitution instead of simple pipe as the pipe causes changes
# to variables to be lost, causing LTP/PAN/tc_utils.source to lose track
# of status and always report PASS.
analysis_output  < <(./test.sh 2>&1)
