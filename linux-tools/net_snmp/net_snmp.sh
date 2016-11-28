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
## File :        net_snmp.sh
##
## Description:  Test net-snmp basic functions.
##
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/net_snmp
## source the utility functions
LTPROOT=${PWD%%/testcases/*}/
source $LTPBIN/tc_utils.source

IPV6=""
server_name=""
must_restart_snmpd="tbd"
do_tests=   # set by find_tests()
num_tests=0

#
# tc_local_setup
#
function tc_local_setup()
{
	#
	# Set environment variables for test scripts
	#
	export LTPBIN
	testdir=${LTPBIN%/shared}/net_snmp/snmp_tests
	SNMP_BASEDIR=$testdir
	export SNMP_BASEDIR
	SNMP_VERBOSE=0                  ## 0=silent, 1=warnings, 2=more
        export SNMP_VERBOSE
        SNMP_SLEEP=${SNMP_SLEEP:=3}     ## default seconds to sleep
        export SNMP_SLEEP
        SNMP_UPDIR="/usr"
	export SNMP_UPDIR

	#
	# Check for the configuration script.
	#
	[ -s "$SNMP_BASEDIR/TESTCONF.sh"  ]
	tc_break_if_bad $? "No TESTCONF.sh was found." || exit

	#
	# Setup for the next test run.
	#
	rm -f $testdir/tests/core

	mkdir $TCTMP/snmp		# must make this a subdir or snmp
	SNMP_TMPDIR="$TCTMP/snmp" 	# tests will delete contents of $TCTMP!
	export SNMP_TMPDIR

	if [ "x$SNMP_TEST_HOST" != "x" ] ; then
	    export SNMP_TMPDIR_REMOTE=/tmp/snmptest
	    ssh $SNMP_TEST_HOST mkdir -p $SNMP_TMPDIR_REMOTE
	    
	    # $SNMP_TMPDIR_REMOTE is also needed at local. Configure files
	    # would be generated locally in follow directory then mirrored
	    # to SNMP_TEST_HOST.
	    mkdir -p $SNMP_TMPDIR_REMOTE  
	fi
	mkdir -p $LTPROOT/debug
}


#
# local cleanup
#
function tc_local_cleanup()
{
        # Must run this as its own process because eval_tools.sh works
        # in relation to the sourcing script's directory.
        cd $testdir/tests
        cat <<EOF >stopagent
#!${SHELL}
cd $testdir
source eval_tools.sh # for STOPAGENT
STOPAGENT &>/dev/null
EOF
        chmod +x stopagent
        ./stopagent
	rm stopagent

	killall snmpd &>/dev/null	# just to be sure!

	[ "$must_restart_snmpd" == "yes" ] && tc_service_start_and_wait snmpd 

	if [ "x$SNMP_TMPDIR_REMOTE" != "x" ] ; then
	    ssh $SNMP_TEST_HOST rm -rf $SNMP_TMPDIR_REMOTE
	    rm -rf $SNMP_TMPDIR_REMOTE
	fi
}


function check_install {

	tc_register "net-snmp installation check"
	SBIN_PATH="/usr/sbin"
	PATH="$SBIN_PATH:$PATH"
	tc_executes /usr/sbin/snmpd
	tc_pass_or_fail $? "FATAL: snmpd not installed?" || exit

	PATH=${SNMP_BASEDIR}:$PATH
	export PATH

	tc_service_status snmpd && {
		tc_service_stop_and_wait snmpd  
		must_restart_snmpd="yes"
	}
}


function find_tests {
	num_tests=0
	for testfile in $testdir/tests/T*; do
		case $testfile in
			# Skip backup files, and the like.
			*~)     ;;
			*.bak)  ;;
			*.orig) ;;
			*.rej)  ;;
			
			# Do the rest
			*)
				num_tests=`expr $num_tests + 1`
				do_tests="$do_tests $testfile"
				;;
		esac
	done
	TST_TOTAL="$num_tests"
}


function run_tests {
	cd $testdir/tests
	for testfile in $do_tests; do
		tc_register "${testfile##*/}"
#		if [ "$RUN_IPV6" == "1" ]; then
#			strace -v -o $LTPROOT/debug/snmp-$server_name-${testfile##*/} -tt -f eval_onescript.sh $testfile
#		else
			eval_onescript.sh $testfile
#		fi
		tc_pass_or_fail $? 
	done
}


#################
# Main
#################
RUN_IPV6=0
TST_TOTAL=1 # reset in loop below
tc_setup

tc_exist_or_break /usr/include/net-snmp/net-snmp-config.h || exit
tc_exec_or_break grep || exit

check_install 
find_tests

tc_info "###################################### ipv4"
run_tests

tc_ipv6_info && IPV6=yes
if [ "$IPV6" = "yes" ]; then
	export IPV6
	IPV6_ADDR_LIST=""
	[ "$TC_IPV6_host_ADDRS" ] && IPV6_ADDR_LIST="$IPV6_ADDR_LIST $TC_IPV6_host_ADDRS"
	[ "$TC_IPV6_link_ADDRS" ] && IPV6_ADDR_LIST="$IPV6_ADDR_LIST $TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES"
	[ "$TC_IPV6_global_ADDRS" ] && IPV6_ADDR_LIST="$IPV6_ADDR_LIST $TC_IPV6_global_ADDRS"

	RUN_IPV6=1
	for ADDR in $IPV6_ADDR_LIST ; do
		server_name=$(tc_ipv6_normalize $ADDR)
		export server_name
		tc_info "###################################### ipv6 $server_name"
		TST_TOTAL=`expr $num_tests + $TST_TOTAL`
		run_tests
	done

fi
