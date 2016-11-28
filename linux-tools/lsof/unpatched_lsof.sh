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
## File :	lsof.sh
##
## Description:	Test the lsof program
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/lsof
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/lsof
cd $TESTDIR
TESTCASEDIR=${LTPBIN%/shared}/lsof/lsof-tests

################################################################################
# global variables
################################################################################

looper=""
myfile=""
TESTLIST="@TESTLIST@"
PS_ARGS="-ef"

################################################################################
# the utility functions
################################################################################

#
#	tc_local_setup
#
function tc_local_setup()
{
	if tc_is_busybox ps ; then
		PS_ARGS=""
	fi

	cp /etc/hosts /etc/hosts.bck
	grep -m 1 $(hostname) /etc/hosts.bck > /etc/hosts
}

#
#	tc_local_cleanup
#
function tc_local_cleanup()
{
	mv /etc/hosts.bck /etc/hosts
	[ "$looper" ] && killall $looper &>/dev/null
}

################################################################################
# the testcase functions
################################################################################

#
#	test01	Check to see that lsof is installed.
#
function test01()
{
	tc_register "is lsof installed?"

	tc_executes lsof
	tc_pass_or_fail $? "lsof not installed"
}

#
#	test02	Open a file and see that lsof lists it.
#
function test02()
{
	tc_register	"lsof should list an open file"

	# create script that will loop forever
	# then redirect its output (of which there is none) to a file
	cat > $looper <<-EOF
		#!$SHELL
		while : ; do
			sleep 1
		done
	EOF
	chmod +x $looper
	eval ./$looper > $myfile &

	# wait for process to start
	counter=10
	while ! ps ${PS_ARGS} | grep -q "[l]ooper$$.sh" ; do
		tc_info "waiting for $looper to start"
		sleep 1
		((--counter))
		[ $counter != 0 ] || {
			tc_break_if_bad 1 "$looper did not start in 10 seconds"
			return
		}
	done

	# see that lsof lists the file
	lsof >$stdout 2>$stderr
	grep -q "$myfile" $stdout
	tc_pass_or_fail $? "expected to see file $myfile listed in output"
}

#
#	test03	As test02, but restrict output of lsof with -c.
#		-c compares command names.
#		If the expression matches the file should be listed. 
#
function test03()
{
	tc_register	"lsof -c $looper finds match"

	lsof -c $looper >$stdout 2>$stderr
	grep -q "$myfile" $stdout
	tc_pass_or_fail $? "expected to see file $myfile listed in output"
}

#
#	test04	As test02, but restrict output of lsof with -c.
#		-c compares command names.
#		If the expression does NOT match the file should
#		NOT be listed. 
#
function test04()
{
	tc_register	"lsof -c x$looper does NOT find match"

	lsof -c x$looper >$stdout 2>$stderr
	grep -q "$myfile" $stdout
	[ $? -ne 0 ]
	tc_pass_or_fail $? "expected to NOT see file $myfile listed in output"
}

#
#	test0n	Close the previously opened file and see that lsof no longer
#		lists it. (Depends on file opened by test02.)
function test0n()
{
	tc_register	"lsof should NOT list closed file"

	# kill the process
	tc_info "Terminated message is expected..."
	killall $looper

	# wait for the process to die
	while ps ${PS_ARGS} | grep "[l]oop$$.sh" ; do	# wait for the process to die
		tc_info "waiting for $looper to die"
		sleep 5
	done
	sleep 5

	# see that lsof no longer lists the file
	lsof >$stdout 2>$stderr
	grep -q "$myfile" $stdout
	[ $? -ne 0 ]
	tc_pass_or_fail $? "expected to NOT see file $myfile listed in output"
}

#
#	testxx		Run all tests ported from the source tree
#
function testxx()
{
              tc_is_fstype $TCTMP nfs 
              result=$?
	      for t in $TESTLIST ; do
                if [ $result -eq 0 ] && [ "$t" == "LTlock" ];
                then
			((--TST_TOTAL))
			tc_info "Skipped $t"
                    continue;
                fi
		tc_register "$t"
		$TESTCASEDIR/$t >$stdout 2>$stderr
		tc_pass_or_fail $? "bad response from test" \
		"Note that LTsock can fail if /etc/hosts has two entries for $(hostname)"
	done;
}

################################################################################
# main
################################################################################

set $TESTLIST
let TST_TOTAL=5+$#

tc_setup			# standard setup

tc_exec_or_break grep killall sleep chmod || exit

set the global variables
looper=looper$$.sh
myfile=$TCTMP/myfile

pwd=$PWD
cd $TCTMP
test01 && \
test02 && \
test03 && \
test04 && \
test0n 
cd $pwd
testxx
