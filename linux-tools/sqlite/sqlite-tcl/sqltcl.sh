#!/bin/sh
############################################################################################
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
## File :	sqlite.sh
##
## Description:	Check that sqlite-tcl can run and execute basic operations
##
## Author:	Shruti Bhat , shruti.bhat@in.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/sqlite
source $LTPBIN/tc_utils.source

tc_local_cleanup()
{
rm sample2.db 
}
################################################################################
# the testcase functions
################################################################################


function test01()
 {
           tc_register "Use sqlite-tcl to create sample2 and execute basic commands"
	
	   lib='lib'
	   file /bin/bash  | grep -c 64-bit  >$stdout 2>$stderr
	   [ $? == 1 ] || lib='lib64' 
	   
	   tclsh runsqltcl.tcl $lib >$stdout 2>$stderr
		
           local expected="one 1 two 2 {} 3"	
	   tc_fail_if_bad $? "unexpected response" || return
										     
          cat $stdout | grep -q "$expected" 2>$stderr
          tc_pass_or_fail $? "Did not see expected output \"$expected\" in stdout"

  }
##############################################################################
# main
################################################################################

TST_TOTAL=1
tc_setup			# standard tc_setup

test01 
