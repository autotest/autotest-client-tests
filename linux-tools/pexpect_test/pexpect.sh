#!/bin/sh
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
## File:		pexpect.sh
##
## Description:	Test pexpect package
##
## Author:	Athira Rajeev<atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

export TSTDIR=${LTPBIN%/shared}/pexpect_test
REQUIRED="python"
TST_TOTAL=5

################################################################################
# testcase functions
################################################################################

# Function:		runtest
#
function runtest()
{
	# Create one file $USER directory
	touch /home/$USER/testfile

	tc_register "ssh using pexpect"

	# login to another host using pexpect 
	# and execute ls , verify it lists the "testfile"
	python $TSTDIR/sshls.py -s localhost -u $USER -p $PASSWORD &>$stdout 2>$stderr
	tc_fail_if_bad $? "ssh using pexpect failed" || return

	grep -q testfile $stdout 2>$stderr 
	tc_pass_or_fail $? "ls in localhost failed to list testfile using pxpect"

	tc_register "ssh using pxssh"

	# login to another host using pxssh
	# and execute ls , verify it lists the "testfile"
	python $TSTDIR/astat.py -s localhost -u $USER -p $PASSWORD &>$stdout 2>$stderr
	tc_fail_if_bad $? "ssh using pxssh failed" || return

	grep -q testfile $stdout 2>$stderr
	tc_pass_or_fail $? "ls in localhost failed to list testfile using pxssh"	

	tc_register "Test for ANSI, screen and FSM modules"

	# bd_serv.py exposes an shell terminal on a socket
	# bd_serv.py starts the server as a daemon process ( using -d )
	# and opens an ssh connection for the client to connect to.
	python $TSTDIR/bd_serv.py -d --hostname localhost --username $USER --password $PASSWORD &>$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to start server in daemon mode" || return

	sleep 5
	# Connect to the shell terminal created by bd_serv 
	# and execute command "ls" 
	# verify it lists the "testfile"
	python $TSTDIR/bd_client.py "/tmp/mysock" ls &>$stdout 2>$stderr
	tc_fail_if_bad $? "client failed to connect to the virtual terminal"

	grep -q testfile $stdout 2>$stderr
	tc_pass_or_fail $? "ls failed to list file in virtual terminal"

	# Stop the server started using bd_serv.py
	# And the ssh session for client
	pid=`ps ax|grep "bd_serv.py" | grep -v grep | awk '{ print $1}'`
	kill $pid

	pid=`ps ax|grep $USER | grep -v grep | awk '{ print $1}'`
	kill $pid

	tc_register "Test for fdpexpect"

	python $TSTDIR/test_filedescriptor.py &>$stdout 2>$stderr
	tc_pass_or_fail $? "fdexpect failed"

	tc_register "Test for pexpect.run, and other pexpect tests"
	
	python $TSTDIR/test_pexpect.py &>$stdout 2>$stderr
	tc_pass_or_fail $? "pexpect tests failed"
}

function tc_local_setup()
{
	rpm -q pexpect >$stdout 2>$stderr 
	tc_break_if_bad $? "pexpect required, but not installed" || return 

	tc_exec_or_break $REQUIRED || return

	tc_add_user_or_break || return # sets TC_TEMP_USER 
	USER=$TC_TEMP_USER 
	PASSWORD=$TC_TEMP_PASSWD
}

####################################################################################
# MAIN
####################################################################################

# Function:	main
#
tc_setup
runtest
