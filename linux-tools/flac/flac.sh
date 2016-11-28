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
#LTPBIN=${LTPBIN%/shared}/flac
source $LTPBIN/tc_utils.source

## Author:  Sohny Thomas <sohthoma@in.ibm.com>
###########################################################################################
## source the utility functions

TSTDIR=${LTPBIN%/shared}/flac/

function tc_local_setup()
{
    tc_add_user_or_break || return # sets TC_TEMP_USER
    USER=$TC_TEMP_USER 
    chown -R $USER $TCTMP
    su - $USER -c "cp -rf $TSTDIR $TCTMP/; chmod -R 777 $TCTMP/flac"
}


function run_test()
{
	pushd $TCTMP/flac/Test > /dev/null
	
	#some tests need to be run as a non-root user
	#for the tests to check the lib files have proper permission

	tc_register "tests for FLAC C apis"
	su - $USER -c "cd $TCTMP/flac/Test;./test_libFLAC.sh" 1>$stdout 2>$stderr 
	tc_pass_or_fail $? "testing of flac C APIs"

	tc_register "tests for FLAC C++ apis "
	su - $USER -c "cd $TCTMP/flac/Test;./test_libFLAC++.sh" 1>$stdout 2>$stderr  
	tc_pass_or_fail $? "testing of flac C++ APIs "

	tc_register "tests metadata for  files encoded using metaflac command "
        ./test_metaflac.sh 1>$stdout 2>$stderr
	retval=$?
	grep -c -q "Verify OK" $stderr
	[[ $? -eq 0 ]] && cat /dev/null > $stderr
	tc_pass_or_fail $retval "testing of metaflac command "
	
	tc_register "check grabbag_ APIs for getting and storing cuesheet and picture info"
	su - $USER -c "cd $TCTMP/flac/Test/; ./test_grabbag.sh" 1>$stdout 2>$stderr
	tc_pass_or_fail $? "grabbag API test fails"
 
	tc_register "sanity testing of flac command"
        ./test_flac.sh 1>$stdout 2>$stderr
	retval=$?
        grep -c -q "Verify OK" $stderr
        [[ $? -eq 0 ]] && cat /dev/null > $stderr
	tc_pass_or_fail $retval "sanity testing of flac command"
	popd > /dev/null
}


TST_TOTAL=5

tc_setup
run_test
