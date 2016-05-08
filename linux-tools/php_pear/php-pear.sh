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
## File :       php5-pear.sh
##
## Description: This program tests basic functionality of the PEAR of PHP.
##
## Author:      Yan Li - liyanbj@cn.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

# Test specific variables
PEAR=pear


function tc_local_setup()
{
	cp /etc/php.ini /etc/php.ini$$
        echo "date.timezone = \"US/Central\"" >> /etc/php.ini
}

function tc_local_cleanup()
{
	rm -f /etc/php.ini
        mv /etc/php.ini$$ /etc/php.ini
}


# Function:    Test for installation of commands 
#
# Description: If required commands are not install, terminate test
#                
#
# Return:      0 - on success.
#              non-zero on failure.
test01()
{
	tc_register "Installation check"
	tc_executes $PEAR
	tc_pass_or_fail $? "PEAR not properly installed"
}


#
# Function:    test02
#
# Description: Test that PEAR list command would list all modules
#              installed .
#
# Inputs:      NONE
#
# Exit         0 - on success
#              non-zero on failure.
test02()
{
	tc_register    "Test PEAR list command"

	$PEAR list >$stdout 2>$stderr
	tc_fail_if_bad $? "$PEAR list returned error" || return
	grep -i -q "INSTALLED PACKAGES" $stdout 
	tc_fail_if_bad $? "Bad response from list command" || return
	grep -q "PEAR" $stdout
	tc_pass_or_fail $? "Bad response from list command"
}


#
# Function:    test03
#
# Description: Test that PEAR info command would print out information
#              on designated module
#
# Inputs:      NONE
#
# Exit         0 - on success
#              non-zero on failure.
test03()
{
	tc_register    "Test PEAR info command"
	
#	cp /etc/php.ini /etc/php.ini$$
#	echo "date.timezone = \"US/Central\"" >> /etc/php.ini
	$PEAR info PEAR >$stdout 2>$stderr
	tc_fail_if_bad $? "$PEAR list returned error" || return
	grep -i -q "ABOUT PEAR.PHP.NET/PEAR" $stdout 
#	rm -f /etc/php.ini
#	mv /etc/php.ini$$ /etc/php.ini
	tc_pass_or_fail $? "Bad response from list command"
}


# Function: main
# 
# Description: - call setup function.
#              - execute each test.
#
# Inputs:      NONE
#
# Exit:        0 - success
#              non_zero - failure
#

TST_TOTAL=3
tc_setup
test01  &&
test02  &&
test03  
