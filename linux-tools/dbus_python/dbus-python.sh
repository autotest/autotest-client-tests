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
## File :	dbus-python.sh
##
## Description:	Tests the dbus binding for python
##
## Author:	Suzuki K P <suzukikp@in.ibm.com>
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
TESTDIR=${LTPBIN%/shared}/dbus_python/dbus-python-tests

source $LTPBIN/tc_utils.source

function tc_local_cleanup()
{
	[ "$DBUS_SESSION_BUS_PID" != "" ] && {
		kill -TERM $DBUS_SESSION_BUS_PID
		[ $? -ne 0 ] && {
			tc_fail "Dbus daemon exited abnormally"
			return 1
		}
		sleep 2
		tc_info "Stopped dbus-daemon"
		kill -9 $DBUS_SESSION_BUS_PID &>/dev/null
	}


	return 0
}
		
	
function tc_local_setup()
{
	tc_executes "dbus-launch python" || tc_break || return;
	# For dbus-launch copied from the fakeroot !	
	export PATH=$PATH:$TESTDIR/../

	# Create the dbus conf file
	cat > $TCTMP/dbus.conf <<EOF
<busconfig>
  <type>session</type>
  <listen>unix:tmpdir=$TESTDIR</listen>
  <servicedir>$TESTDIR</servicedir>
  
  <policy context="default">
    <!-- Allow everything to be sent -->
    <allow send_destination="*"/>
    <!-- Allow everything to be received -->
    <allow eavesdrop="true"/>
    <!-- Allow anyone to own anything -->
    <allow own="*"/>
  </policy>

</busconfig>
EOF
	unset DBUS_SESSION_BUS_ADDRESS
	unset DBUS_SESSION_BUS_PID

	eval `dbus-launch --sh-syntax --config-file=$TCTMP/dbus.conf`
	if [ "$DBUS_SESSION_BUS_PID" == "" ];then
		tc_break "Could not start dbus daemon"
		exit 0
	fi

	tc_executes "dbus-monitor" &>/devnull && ( dbus-monitor > $TESTDIR/monitor.log & )

	tc_info "Started dbus-daemon($DBUS_SESSION_BUS_PID)"
}

function test_standalone()
{
	tc_register "standalone tests"
	python $TESTDIR/test-standalone.py &>$stdout && grep -q "OK" $stdout
	tc_pass_or_fail $? "Unexpected failure"
}

function test_unusable_main()
{
	tc_register "unusable main test"
	python $TESTDIR/test-unusable-main-loop.py >$stdout 2>$stderr
	tc_pass_or_fail $? "Unexpected failure"
}
TST_TOTAL=2
tc_setup

test_standalone
test_unusable_main
