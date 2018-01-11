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
## File:		rng-tools.sh
##
## Description:	This program tests basic functionality of rng-tools
##
## Author:	Athira Rajeev<atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
load_rng_mod=0
rng_service=rngd

rngd_cleanup=0

################################################################################
# Utility functions 
################################################################################

#
# local setup
#	 
function tc_local_setup()
{
        tc_register "Setting up machine to run the tests"
	tc_root_or_break || return	
	tc_exec_or_break rngd rngtest || return

	cat >> $TCTMP/entropy.py <<-EOF
	#!/usr/bin/python
	import sys, time
	sys.stdout.write(open('/proc/sys/kernel/random/entropy_avail', 'r').read())
	EOF

	chmod +x $TCTMP/entropy.py
	
}

#
# rngd restore
#
function tc_local_cleanup()
{
	# Restore status of rngd service
	if [ $rngd_cleanup -eq 0 ]; then
		systemctl stop rngd >$stdout 2>$stderr
	        systemctl status rngd >$stdout 2>$stderr
                grep -iqv "Active: active" $stdout
		tc_break_if_bad $? "failed to stop rngd"
	fi
	if [ $load_rng_mod -eq 1 ]; then
		rmmod tpm-rng
		tc_break_if_bad $? "failed to rmmod tpm-rng"
	fi
	
} 

################################################################################
# Testcase functions
################################################################################

function check_rng()
{

        tc_register "checking TPM  device"
        tc_exists /dev/random /dev/urandom /dev/tpm*
        if [ $? -ne 0 ]; then
                tc_conf "TPM devices were not found, Skipping tests"
                exit 0
        else
                lsmod |grep -qw tpm-rng
                if [ $? -ne 0 ]; then
                        modprobe tpm-rng >/dev/null
                        if [ $? -eq 0 ]; then
                                load_rng_mod=1
                        else
                                tc_conf "Failed to load tpm-rng module"
                                exit 0
                        fi
                fi
        fi
        systemctl is-active rngd 2>&1 >/dev/null
        [ $? -eq 0 ] && \
                rngd_cleanup=1


        tc_service_restart_and_wait $rng_service
}
#
# test01	rngd test
#
function test01()
{
	tc_register	"rngd test"

	# Invoke rngd with random number input device ( -r )
	# and output device ( -o )
	rngd -r /dev/urandom -o /dev/random --fill-watermark=3000 >$stdout 2>$stderr
	tc_fail_if_bad $? "rngd failed to execute" || return

	entropy_available=`python $TCTMP/entropy.py`
	[ $entropy_available -ge 3000 ]
	tc_pass_or_fail $? "rngd failed to fill the entropy pool with specified level"
}

#
# test02	rngtest
#
function test02()
{
	tc_register	"rngtest command"
	
	# invoke rngtest taking random number
	# input from /dev/random filled by rngd
	cat /dev/random | rngtest -c 1000 &> $TMP/result

	grep -wq "rngtest: FIPS 140-2 successes" $TMP/result && grep -wq "rngtest: FIPS 140-2 failures" $TMP/result
	tc_pass_or_fail $? "rngtest failed to statistics"

	tc_register	"rngtest -b option"
	# Dump statistics every 250 blocks
	cat /dev/random | rngtest -c 1000 -b 250 &> $TMP/result2
	
	# Check if rngtest dumped statistics 4 times for 1000 blocks
	count=`grep -wc "rngtest: FIPS 140-2 successes" $TMP/result2 `
	[ $count -eq 4 ]
	tc_pass_or_fail $? "rngtest -b failed" 
}

#
# test03	TPM source
#
function test03()
{
	tc_register	"rngd with tpm-rng as source"

	ls /dev/ | grep -q tpm
	[ $? -ne 0 ] && tc_conf "TPM device not present, Test cannot be run" && return 1

	tc_check_kconfig "CONFIG_HW_RANDOM_TPM"; RC=$?
	[ $RC -eq 2 ] && tc_conf "module for hardware RNG source missing" && return 1

	tc_check_kconfig "CONFIG_TCG_TPM" || return

	# Stop already running rngd to test entropy 
	# filled by starting rngd with hwrng as source
        systemctl stop rngd >$stdout 2>$stderr

	if [ $RC -eq 1 ]; then
		# Load module for tpm RNG
		modprobe tpm-rng
		tc_fail_if_bad $? "Failed to insert module tpm-rng" || return
		load_rng_mod=1
	fi

	# invoke rngd with random number input device as hwrng
	rngd -r /dev/hwrng -o /dev/random --fill-watermark=3000 >$stdout 2>$stderr
	tc_pass_or_fail $? "rngd failed to execute" || return

	tc_register "Running rngtest with entropy filled from hwrng"
	cat /dev/random | rngtest -c 1 &> $TMP/result3

	grep -wq "rngtest: FIPS 140-2 successes" $TMP/result3 && grep -wq "rngtest: FIPS 140-2 failures" $TMP/result3
	tc_pass_or_fail $? "rngd failed with /dev/hwrng"
}
	 
################################################################################
# main
################################################################################

tc_setup
check_rng
TST_TOTAL=4
test01
test02
test03
