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
## File :	openhpi.sh
##
## Description:	Test the openhpi package
##
## Author:	Hong Bo Peng <penghb@cn.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/openhpi
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/openhpi/openhpi2-conformancetest
UNIT_TESTDIR=${LTPBIN%/shared}/openhpi/openhpi2-unittest
EXCLUDE=$TESTDIR/exclude-test
TIMEOUT_EXE=${LTPBIN%/shared}/openhpi/t0
TIMEOUT=120

LOGFILE=openhpi_funtest.log

#
# wait for openhpid to listen on a socket
#
function wait_for_openhpid()
{
        local count=10
        while ! netstat -p | grep -q openhpid ; do
                ((--count)) || break
                sleep 1
        done
}

function tc_local_setup()
{
	tc_root_or_break || return

	# save original openhpi.conf
	[ -e /etc/openhpi/openhpi.conf ] && mv /etc/openhpi/openhpi.conf $TCTMP
}

function tc_local_cleanup()
{
	# restore saved files
	[ -e $TCTMP/openhpi.conf ] && mv $TCTMP/openhpi.conf /etc/openhpi
	[ ! -z $old_conn ] && openhpi-switcher --set=$old_conn &>/dev/null
	tc_service_stop_and_wait openhpid
}

################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"openhpi installation check"
	tc_exists /usr/lib*/libopenhpi*
	tc_pass_or_fail $? "openhpi is not installed properly"
}

function test02()
{
	tc_register  "openhpi-switcher"
	tc_exec_or_break openhpi-switcher || return 1

	local orig_conn
	local new_conn

	orig_conn=`openhpi-switcher --list|grep "*"`
	orig_conn=${orig_conn## * }
	! -z $orig_conn ] && ( [ "$orig_conn" = "standard" ] || [ "$orig_conn" = "client" ] )
	tc_fail_if_bad $? "orig_conn=$orig_conn" || return
	
	# set new connection
	if [ "$orig_conn" = "standard" ]
	then
		new_conn="client"
	else
		new_conn="standard"
	fi

	openhpi-switcher --set=$new_conn &>/dev/null
	tc_fail_if_bad $? "Unexpected response from openhpi-switcher command" || return
	openhpi-switcher --show|grep -q $new_conn
        tc_fail_if_bad $? "new connection \"$new_conn\" failed to be set" || return	

	# restore orig connection
	openhpi-switcher --set=$orig_conn &>/dev/null
	tc_fail_if_bad $? "Unexpected response from openhpi-switcher command" || return
	openhpi-switcher --show|grep -q $orig_conn
        tc_pass_or_fail $? "orig connection \"$orig_conn\" failed to be set" || return	
}

function run_unit_tests()
{
	local unit_path="ohpi ohpic"
	local tests=$(cd $UNIT_TESTDIR; find $unit_path -name "*.test")
	local mode

	[ ! -z $1 ] && mode=$1
	cat > /etc/openhpi/openhpi.conf <<-EOF
	OPENHPI_LOG_ON_SEV = "MAJOR"
	OPENHPI_ON_EP = "{SYSTEM_CHASSIS,1}"
	EOF
	chmod 600 /etc/openhpi/openhpi.conf
	[ "$mode" = client ] && {
		tc_service_restart_and_wait openhpid && wait_for_openhpid
		tc_fail_if_bad $? "could not start openhpid" || return
	}

	[ -n "$tests" ] && set $tests && UNIT_TST_TOTAL=$# && TST_TOTAL=$((UNIT_TST_TOTAL+TST_TOTAL))
	for tst in $tests; 
	do
		tc_register "$mode: $tst"

		$TIMEOUT_EXE $TIMEOUT $UNIT_TESTDIR/$tst >$stdout 2>$stderr
		tc_pass_or_fail $? "$mode: $tst failed"
	done

	unit_path="simulator"
	tests=$(cd $UNIT_TESTDIR; find $unit_path -name "*.test")
	cat > /etc/openhpi/openhpi.conf <<-EOF
		OPENHPI_THREADED = "YES"
		plugin  libsimulator
		handler libsimulator {
			entity_root = "{SYSTEM_CHASSIS,1}"
			name = "test"
		}
	EOF
	[ -n "$tests" ] && set $tests && UNIT_TST_TOTAL=$# && TST_TOTAL=$((TST_TOTAL+UNIT_TST_TOTAL))
	for tst in $tests; 
	do
		tc_register "$mode: $tst"

		$TIMEOUT_EXE $TIMEOUT $UNIT_TESTDIR/$tst >$stdout 2>$stderr
		tc_pass_or_fail $? "$mode: $tst failed"
	done
}

# cases in this list write info to stderr, which do not indicate it failed;
# so its stderr is directed to stdout for easy judgement
cases_independent_from_stderr=(./src/sensor/saHpiSensorEventMasksGet/4.test ./src/sensor/saHpiSensorTypeGet/3.test \
			       ./src/events/saHpiEventGet/6.test ./src/events/saHpiEventGet/19.test \ 
			       ./src/events/saHpiEventGet/18.test ./src/sensor/saHpiSensorThresholdsSet/15.test \
			       ./src/inventory/saHpiIdrFieldGet/10-1.test ./src/inventory/saHpiIdrFieldGet/10-2.test \
			       ./src/inventory/saHpiIdrFieldGet/11.test ./src/inventory/saHpiIdrFieldGet/12.test \
			       ./src/inventory/saHpiIdrFieldGet/9.test
)

function runtests()
{
	local Num_PASS=0
	local Num_FAIL=0
	local Num_NA=0
	local Num_MISC=0
	local Num_SKIP=0
	local tst_FAIL
	local mode

	[ ! -z $1 ] && mode=$1
	cat > /etc/openhpi/openhpi.conf <<-EOF
		OPENHPI_THREADED = "YES"
		plugin  libsimulator
		handler libsimulator {
			entity_root = "{SYSTEM_CHASSIS,1}"
			name = "test"
		}
	EOF
	chmod 600 /etc/openhpi/openhpi.conf
	[ "$mode" = client ] && {
		tc_service_restart_and_wait openhpid  && wait_for_openhpid
		tc_fail_if_bad $? "could not start openhpid" || return
	}

	tc_info "Please set the openhpi.conf according to your hardware and then run manual test again for specifial plugins."

	local tests=$(cd $TESTDIR; find . -name "*.test")

	[ -n "$tests" ] && set $tests && CONF_TST_TOTAL=$# && TST_TOTAL=$((CONF_TST_TOTAL+TST_TOTAL))

	for tst in $tests ; do

		cat $EXCLUDE | grep -v "^#" | grep $tst > /dev/null
		if [ $? -gt 0 ]; then
			tc_register	"$mode: $tst"

			echo ${cases_independent_from_stderr[@]}|grep -q $tst
			if [ $? = 0 ]
			then
				$TIMEOUT_EXE $TIMEOUT $TESTDIR/$tst &>$stdout
			else
				$TIMEOUT_EXE $TIMEOUT $TESTDIR/$tst >$stdout 2>$stderr
			fi
			rc=$?

			if [ $rc -eq 1 ]; then
				let Num_FAIL+=1
				tst_FAIL="${tst_FAIL} $tst"
				tc_pass_or_fail $rc "$mode: $tst failed"
			elif [ $rc -eq 3 ]; then
				let Num_NA+=1
				tc_info	"$mode: $tst: Not Supported."
			elif [ $rc -ne 0 ]; then
				let Num_MISC+=1
				tc_info "$mode: $tst: return $rc"
			else 
				let Num_PASS+=1
				tc_pass_or_fail $rc "$mode: Execution $tst failed"
			fi
		else
			let TST_TOTAL=TST_TOTAL-1
			let Num_SKIP+=1
			echo "$tst : SKIPED for simulator plugin."
		fi
	done
	tc_info "******************"
        tc_info "Execution Summary:"
	tc_info "    PASS: ${Num_PASS}, NA: ${Num_NA}, FAIL: ${Num_FAIL}, SKIP: ${Num_SKIP}, OTHER: ${Num_MISC}"
	[ ${Num_FAIL} -gt 0 ] && {
		local t
		tc_info "Failed Tests(${Num_FAIL}):"
		for t in ${tst_FAIL}
       		do
			tc_info "    $t"
		done
	}
	tc_info "******************"
}

################################################################################
# main
################################################################################

tc_setup

TST_TOTAL=1
test01 || exit
supported_mode=(client)
for i in ${supported_mode[@]}
do
	runtests $i
done
