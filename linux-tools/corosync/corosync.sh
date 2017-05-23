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
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TSTDIR=${LTPBIN%/shared}/corosync/Test
## Author:  Sohny Thomas <sohthoma@in.ibm.com>
###########################################################################################
## source the utility functions

DEAMONSTATUS=""

function tc_local_setup()
{
    tc_root_or_break || return
      tc_check_package corosync
    tc_break_if_bad $? "corosync package not installed" 

    # For the corosync daemon to work, requires /etc/corosync/corosync.conf
    if [ ! -f /etc/corosync/corosync.conf ]; then
	cp /etc/corosync/corosync.conf.example /etc/corosync/corosync.conf
	corosync_conf_yes=1
    fi

    systemctl status corosync >$stdout 2>$stderr
    DEAMONSTATUS=$?
    if [ $DEAMONSTATUS -eq 3 ]; then
	tc_service_start_and_wait corosync
	tc_fail_if_bad $? "Could not start corosync deamon"
    fi
}

function tc_local_cleanup()
{  
    if [ $DEAMONSTATUS -eq 3 ]; then
        systemctl stop corosync >$stdout 2>$stderr
    fi
    if [ $corosync_conf_yes -eq 1 ]; then
    	rm -rf /etc/corosync/corosync.conf
    fi
}

function run_test() 
{
	pushd $TSTDIR &>/dev/null
    	# Excluding quorum related tests as they are applicable for cluster
	TESTS=`ls | egrep -v '(*quorum*)'`
	TST_TOTAL=`echo $TESTS | wc -w`
	for test in $TESTS; do
		tc_register "Test $test"
		if [ "$test" == "cpgverify" ]; then
			./$test -i 100 >$stdout 2>$stderr
		elif [ "$test" == "testcpg" ] || [ "$test" == "testcpgzc" ]; then
			./$test << END >$stdout 2>$stderr
		        EXIT
END
		else
			./$test >$stdout 2>$stderr
		fi
		RC=$?
		if [ ! `egrep -v "debug|passed|skipped" $stderr` ]; then
			cat /dev/null > $stderr
		fi
		tc_pass_or_fail $RC "$test failed"
	done
	popd &>/dev/null
}


tc_setup
run_test
