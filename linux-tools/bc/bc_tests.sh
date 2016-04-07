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
## File :       bc_tests.sh
##
## Description: This program tests basic functionality of the bc program
##
## Author:      Paul Washington - wshp@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source


# Function:     Test for installation of commands 
#
# Description:  - If required commands are not install, terminate test
#                
#
# Return:       - zero on success.
#               - non-zero on failure.
test01()
{
	tc_register "Installation check"
	tc_executes bc
	tc_pass_or_fail $? "bc not properly installed"
}


#
# Function:    test02
#
# Description: - Test that bc will successfuly ADD two values 
#                the local system for a number of common system faults
#
#
# Inputs:      NONE
#
# Exit         0 - on success
#              non-zero on failure.
test02()
{
	tc_register    "Adding 8 + 8 expect 16"

	local OUTPUT=0
	OUTPUT=$(echo "8+8" | bc) 2>$stderr
	tc_fail_if_bad $? "Bad response from bc" || return
	[ "$OUTPUT" -eq "16" ]
	tc_pass_or_fail $? "Bad argument from bc 8 + 8"
}


#
# Function:    test03
#
# Description: - Test that bc will successfully SUBTRACT two values
#
#
# Inputs:      NONE
#
# Exit         0 - on success
#              non-zero on failure.
test03()
{
	tc_register    "Subtract 60 - 12 expect 48"
	local OUTPUT=0
	OUTPUT=$(echo "60-12" | bc) 2>$stderr
	[ "$OUTPUT" -eq "48" ]

	tc_pass_or_fail $? "Bad argument from bc 60 - 12"
}

#
# Function   test 04
#
# Description: - Test that bc will successfully MULTIPLY three numbers
#
#
# Inputs:	NONE
#
# Exit 		0 - on success
#		non-zero on failure
test04()
{
	tc_register	    "Multiply 60*12*50 expect 36000"
	local OUTPUT=0
	OUTPUT=$(echo "60*12*50" | bc) 2>$stderr
	[ "$OUTPUT" -eq "36000" ]
	tc_pass_or_fail $? "Bad argument from 60*12*50"
}

#
# Function	test 05
#
# Description: - Test that bc will successfully DIVIDE two numbers
#
#
# Inputs:	NONE
#
# Exit		0 - on success
#		non-zero on failure
test05()
{
	tc_register	  "Divide 300/2 expect 150"
	local OUTPUT=0
	OUTPUT=$(echo "300/2" | bc) 2>$stderr 
	[ "$OUTPUT" -eq "150" ]
	tc_pass_or_fail $? "Bad argument from 300/2"
}	

# Function: main
# 
# Description: - call setup function.
#              - execute each test.
#
# Inputs:      NONE
#
# Exit:        zero - success
#              non_zero - failure
#

TST_TOTAL=5
tc_setup
test01  &&
test02  && 
test03  &&
test04  &&
test05
