#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##    1.Redistributions of source code must retain the above copyright notice,            ##
##        this list of conditions and the following disclaimer.                           ##
##    2.Redistributions in binary form must reproduce the above copyright notice, this    ##
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
## File :       libqb.sh                                                                  ##
##                                                                                        ##
## Description: Test for libqb package                                                    ##
##                                                                                        ##
## Author:      Abhishek Sharma < abhisshm@in.ibm.com >                                   ##
##                                                                                        ##
###########################################################################################


#=============================================
# Global variables used in this script
#=============================================
#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libqb
source $LTPBIN/tc_utils.source
PKG_NAME="libqb"
TESTS_DIR="${LTPBIN%/shared}/libqb/tests"


#=====================================================
# Function to check prerequisites to run this test
#=====================================================
function tc_local_setup()
{
        rpm -q $PKG_NAME >$stdout 2>$stderr
        tc_break_if_bad $? "$PKG_NAME is not installed"
	# Binary files required q or Quit command to come out
	echo "q" > /tmp/EOD_FILE
}

#=================================================
# Function to kill the process once test is done
#=================================================
function kill_pid_fn()
{
        DAEMON_NAME="$1"
        # Fetch the Process ID and killed the process
        PID=`ps -ef|grep "$DAEMON_NAME"|grep -v grep|awk -F" " '{print $2}'`
        if [ ! -z $PID ];then
                kill -9 $PID  >$stdout 2>$stderr
        fi
}

#=================================================
# Function to setup ipc client-server connections 
#=================================================
function ipc_server_client_fn()
{
        CLIENT="ipcclient"
        SERVER="ipcserver"
        # check already any ipcserver is running or not, if running stop it.
        kill_pid_fn "$SERVER" >$stdout 2>$stderr
        #Start tcp server
        ./$SERVER & >$stdout 2>$stderr
        sleep 1
        ./$CLIENT </tmp/EOD_FILE >$stdout 2>$stderr
	RC_IPC="$?"
        kill_pid_fn "$SERVER" >$stdout 2>$stderr
}


#=================================================
# Function to setup tcp client-server connections 
#=================================================
function tcp_server_client_fn()
{
        CLIENT="tcpclient"
        SERVER="tcpserver"
        kill_pid_fn "$SERVER" >$stdout 2>$stderr
        ./$SERVER & >$stdout 2>$stderr
        sleep 2
        ./$CLIENT</tmp/EOD_FILE >$stdout 2>$stderr
	RC_TCP="$?"
        kill_pid_fn "$SERVER" >$stdout 2>$stderr
}

#==================================================================
# Run the test suites which are available on test/t directory
#==================================================================
function run_test()
{
        pushd $TESTS_DIR >$stdout 2>$stderr
	
	# Test IPC server-client 
	tc_register "Test IPC server-client"
	ipc_server_client_fn >$stdout 2>$stderr
	tc_pass_or_fail $RC_IPC "$test failed"

	# Test TCP server-client
	tc_register "Test TCP server-client"
	tcp_server_client_fn >$stdout 2>$stderr
	tc_pass_or_fail $RC_TCP "$test failed"
        popd >$stdout 2>$stderr
	rm -f /tmp/EOD_FILE
}


#===================
# Main script
#===================
TST_TOTAL="2"
tc_setup        #Calling setup function
run_test	# Calling test functions
