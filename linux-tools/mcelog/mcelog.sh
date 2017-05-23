#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
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
## File:         mcelog.sh
##
## Description:  This program tests mcelog package
##
## Author:       Ramya BS
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/mcelog
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/mcelog/tests

################################################################################
# Utility functions
################################################################################

#
# local setup
#
function tc_local_setup()
{

        tc_root_or_break || return

      tc_check_package mcelog
        tc_break_if_bad $? "mcelog not installed"

        lsmod | grep -q mce_inject
        if [ $? -ne 0 ]; then
                modprobe mce_inject >$stdout 2>$stderr
                tc_break_if_bad $? "Failed to load module mce_inject"
        fi


        if [ ! -c /dev/mcelog ]; then
                mknod /dev/mcelog c 10 227 >$stdout 2>$stderr
                if [ $? -ne 0 ]; then
                        tc_break_if_bad $? "Failed to create /dev/mcelog"
                fi
        fi
	# Since the tests  will kill any running mcelog daemon during execution ,we need to stop the  mcelog service before runing tests.
	tc_service_status mcelog
	[ $? -eq 0 ] && stop_mcelog=yes
	
	if [ "$stop_mcelog" = "yes" ]; then 
		tc_service_stop_and_wait mcelog
		start_mcelog=yes
	fi
	tc_get_os_arch
	if [ "$TC_OS_ARCH" = "x86_64" ]; then
		cp $TESTS_DIR/../pagetypes.x86_64/page-types /usr/sbin
	else
		cp $TESTS_DIR/../pagetypes.ia32/page-types /usr/sbin
	fi
}

function tc_local_cleanup()
{

if [ "$start_mcelog" = "yes" ]; then 
	tc_service_start_and_wait mcelog
fi

rm /usr/sbin/page-types -f 

}



function run_test()
{
        pushd $TESTS_DIR &>/dev/null
        TESTS=`ls -d */`
        TST_TOTAL=`echo $TESTS | wc -w`

        for test in $TESTS; do
                tc_register "Test $test"
		chmod +x $test/inject
		#starting mcelog process before running each test ,as this process will be killed during execution of each test .
		tc_service_start_and_wait mcelog		
                ./test $test >$stdout 2>$stderr
		RC=$?
		tc_ignore_warnings "mcelog: no process found"
		tc_pass_or_fail $RC "$test failed"
        done
        popd &>/dev/null
}

# main
#
tc_setup && \
run_test

