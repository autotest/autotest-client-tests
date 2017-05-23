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
### File : libcanberra.sh                                                      ##
##
### Description: This testcase tests the libcanberra package                   ##
##
### Author: Snehal Phule <snehal.phule@in.ibm.com>                             ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libcanberra
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libcanberra/tests"
function tc_local_setup()
{
        # check installation and environment 
      tc_check_package libcanberra
        tc_break_if_bad $? "libcanberra is not properly installed"
}

function check_soundcard()
{
        tc_register "checking sound card"
        aplay -l 1>$stdout 2>$stderr
        grep -q "no soundcards found" $stderr
        if [ $? -eq 0 ]; then
                tc_conf "Sound card not present"
                return 1
        fi
        tc_pass_or_fail 0
}


function run_test()
{
	pushd $TESTS_DIR &>/dev/null
	TESTS=`ls`
        
	#Check if canberra services are present
	tc_register "Test canberra-system-bootup service"
      tc_check_package libcanberra
	tc_pass_or_fail $? "Test canberra-system-bootup service failed"
	
	tc_register "Test canberra-system-shutdown-reboot service"
      tc_check_package libcanberra
	tc_pass_or_fail $? "Test canberra-system-shutdown-reboot service failed"

	tc_register "Test canberra-system-shutdown service"
      tc_check_package libcanberra
	tc_pass_or_fail $? "Test canberra-system-shutdown service failed"

	for test in $TESTS
	do
		tc_register "Test $test"
		./$test 
		tc_pass_or_fail $? "Test $test failed"
	done
	popd &>/dev/null
}

 
#
# main
#
tc_setup
check_soundcard || exit
TST_TOTAL=4
run_test
