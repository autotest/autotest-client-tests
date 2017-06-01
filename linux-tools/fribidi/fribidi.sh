#!/bin/bash 
############################################################################################
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
## File :       fribidi.sh                                              		  ##
##									      		  ##
## Description: Test for fribidi package                                             ##                                                             
## Author:      Charishma M <charism2@in.ibm.com>                             		  ##
##                                                                                 	  ##
############################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/fribidi
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/fribidi"

################################################################################
# Utility functions                                                            
################################################################################
#                                                                              
# LOCAL SETUP                                                              
################################################################################


function tc_local_setup()
{	
      tc_check_package fribidi
        tc_break_if_bad $? "fribidi is not installed properly"

	# creating bin directory and linking fribidi binary for test purpose	
	if [ ! -d $TESTS_DIR/bin ]; then
	mkdir $TESTS_DIR/bin
	ln -s /usr/bin/fribidi $TESTS_DIR/bin/fribidi
	fi
}

function tc_local_cleanup() 
{
        if [ -d $TESTS_DIR/bin ]; then
                rm -rf $TESTS_DIR/bin
        fi
}

function runtests()
{
       pushd $TESTS_DIR/test >$stdout 2>$stderr
       test="run.tests"
		tc_register "Test $test"
                ./$test >$stdout 2>$stderr
                tc_pass_or_fail $? "$test failed"
    	popd >$stdout 2>$stderr

}

################################################################################
#  MAIN                                                           
################################################################################

tc_setup
TST_TOTAL=1
runtests

