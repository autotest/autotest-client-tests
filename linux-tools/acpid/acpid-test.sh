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

# File :	acpid-test.sh
#
# Description:	Test acpid server functionality.
#
#		Contains the actual testcases for the acpid.
#		We use a FIFO file to simulate the acpi_event file from the kernel.
#		This gives the flexibility of generating predictable events just by
#		writing to the FIFO from the testcase.
#
# Author:	Suzuki K P <suzukikp@in.ibm.com> 
#
#
################################################################################
#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/acpid
LOGDIR=$TESTDIR/log
BACKUPDIR=$TESTDIR/data
EVENT_FILE=$TESTDIR/acpi_event
ACPI_CLIENT_PID=""
SOCK_OPT=""
CONF_DIR=$TESTDIR/conf
EVENTS=$BACKUPDIR/events

INTERVAL=1 # Interval to wait for the acpid server to settle down.


stop_acpid()
{
	killall -TERM acpid >/dev/null 2>&1
	sleep 1
	killall -9 acpid >/dev/null 2>&1
	# Always return success 
	return 0
}


# called with eventfile, confdir 
start_acpid()
{
# Events are read from $EVENT_FILE, with rules loaded from $CONF_DIR
	acpid -e $EVENT_FILE -c $CONF_DIR $SOCK_OPT 
}

# Reload the acpid rules.

reload_acpid()
{
# SIGHUP causes the acpid to reload the rules from the conf dir
	killall -HUP acpid >/dev/null 2>&1
}

# Open an fd for writing. Used for writing to the event fifo
open_fd()
{
	exec 36<>$EVENT_FILE
}

# Close the fd(fifo). This will stop the acpid
close_fd()
{
	exec 36>&-
}

# Start the acpi_listen in background.
# Usage: run_acpi_client_bg stdout stderr
#
run_acpi_client_bg()
{
	ACPI_CLIENT_PID=-1
	acpi_listen >$1 2>$2 &
	ACPI_CLIENT_PID=$!
	#For debugging : echo "acpi client pid is $ACPI_CLIENT_PID"
}

acpi_client_status()
{
	wait $ACPI_CLIENT_PID
	ACPI_CLIENT_STATUS=$?
	#For debugging: echo "acpi client status is $ACPI_CLIENT_STATUS"
}

create_event_file()
{
	unlink  $EVENT_FILE >/dev/null 2>&1
	mkfifo $EVENT_FILE
}

tc_local_setup()
{
	stop_acpid
	create_event_file
	DIFF=diff
	tc_executes diff || {
		DIFF="true"
		tc_info "Without diff we will depend only on commands' return codes"
        }
	# Open the pipe
	open_fd
	rm -rf $LOGDIR # Cleanup the logs
	mkdir -p $LOGDIR
}

tc_local_cleanup()
{
	tc_service_restart_and_wait acpid
}

test_status()
{
	tc_fail_if_bad $ACPI_CLIENT_STATUS "acpi_client failed"\
	"========== client stdout      =========="\
	"$(< $CLIENT_STDOUT)" \
	"========== client stderr      ==========" \
	"$(< $CLIENT_STDERR)" \
	"========== end of client logs =========="
	
	$DIFF -bE $CLIENT_EXP $CLIENT_STDOUT
	tc_fail_if_bad $? "failed" \
		"=============== client.log : Expected to see ================" \
		"$(< $CLIENT_EXP)" \
	"================================================"
	
	if [ $? -ne "0" ]; then
		tc_fail
		return
	fi

	$DIFF -bE $TEST_EXPECT $ACTION_LOG
	tc_pass_or_fail $? "failed" \
		"=============== actions.log : Expected to see  ================" \
		"$(< $TEST_EXPECT)" \
	"================================================"
	
}
	
# Basic test for acpid & acpi_listen
# 	1.	Start the acpid
# 	2.	Open the fd to make acpid accept connections
# 	3.	Start the acpi_listen(aka, client) in background.
#	4.	Close the fd, this should make acpid exit and hence the client
#	5.	The exit status of the client should be "0"

test1()
{
	tc_register "Basic test for acpid and acpi_listen"
	# open_fd 
	start_acpid
	sleep $INTERVAL # Let the server settle down.
	run_acpi_client_bg $LOGDIR/client-1.out $LOGDIR/client-1.err
	sleep $INTERVAL # Let the client connect to the server.
	stop_acpid # Sanity step to make sure acpid is down
	acpi_client_status
	tc_pass_or_fail $ACPI_CLIENT_STATUS "failed\n" "acpi_listen: failed with exit status $ACPI_CLIENT_STATUS"\
	"====== acpi_listen : stdout  ======\n"\
	"$(< $LOGDIR/client-1.out)"\
	"====== acpi_listen : stderr  ======\n"\
	"$(< $LOGDIR/client-1.err)"
}

# Check for -S option
# If -S option is specified, the client should get a "Connection refused error"
#

test2()
{
	SOCK_OPT="-S"
	tc_register "Test for acpid -S socket option"
	
	CLIENT_STDOUT=$LOGDIR/client-3.out
	CLIENT_STDERR=$LOGDIR/client-3.err

	start_acpid
	sleep $INTERVAL # Let the server settle down.
	run_acpi_client_bg $CLIENT_STDOUT $CLIENT_STDERR
	sleep $INTERVAL # Let the client try to connet to the server.
	stop_acpid
	acpi_client_status
	
	if [ $ACPI_CLIENT_STATUS == 0 ]
	then
		tc_fail "failed\n"" acpi_listen: Succeeded unexpectedly\n"
	else	
		tc_pass
	fi
	# reset the SOCK_OPT
	SOCK_OPT=""
}

# Real testing starts here
# Run acpid with some rules and check out the results. Both for client outputs and the action logs.
#
test3()
{
	tc_register "Test the action on events"
	
	SOCK_OPT=""

	# Setup env variables for conf dir, Log file for action scripts.

	TEST_EXPECT=$BACKUPDIR/action-log-3.exp
	CLIENT_EXP=$EVENTS
	
	# Action log for test 3
	export ACTION_LOG=$LOGDIR/action-log-3.out

	# echo "Log file is : $ACTION_LOG"

	CLIENT_STDOUT=$LOGDIR/client-log-3.out
	CLIENT_STDERR=$LOGDIR/client-log-3.err
	
	rm -rf $ACTION_LOG >/dev/null 2>&1 

	# Touch the ACTOIN log. Sanity !
	touch $ACTION_LOG

	start_acpid
	sleep $INTERVAL # Let the server settle down.
	
	run_acpi_client_bg $CLIENT_STDOUT $CLIENT_STDERR
	
	# give enough time for the client to connect before the server starts processing events
	sleep $INTERVAL
	# Generate the events !
	cat $EVENTS >&36

	# Sleep to let acpid process all the events
	sleep $INTERVAL
	
	# Now stop the acpid
	stop_acpid

	acpi_client_status
	test_status

}

# Same as Test3. Just that we reload the rules using SIGHUP and check if the 
# new rules were loaded.

test4()
{
	rm -rf $NEW_RULE
	tc_register "Test ACPID SIGHUP behaviour"
	export ACTION_LOG="$LOGDIR/action-log-4.out"
	
	TEST_EXPECT=$BACKUPDIR/action-log-4.exp
	CLIENT_EXP=$LOGDIR/client-4.exp

	NEW_RULE=$CONF_DIR/tmprule
	
	CLIENT_STDOUT=$LOGDIR/client-4.out
	CLIENT_STDERR=$LOGDIR/client-4.err
	

	rm -rf $ACTION_LOG
	touch $ACTION_LOG

	start_acpid
	# open_fd

	run_acpi_client_bg  $CLIENT_STDOUT $CLIENT_STDERR

	# let the client connect to the server
	sleep $INTERVAL

	cat $EVENTS >&36
	
	# Add the new temporary rule
	cp $BACKUPDIR/tmprule $NEW_RULE

	# Let the server finish processing of the events
	sleep $INTERVAL	
	
	# Reload the config files
	reload_acpid
	cat $EVENTS >&36
	
	sleep $INTERVAL
	stop_acpid

# Hence we see the events twice
	cat $EVENTS $EVENTS > $CLIENT_EXP
	acpi_client_status
	test_status

	rm -rf $NEW_RULE
}

tc_setup
test1
test2
test3
test4
