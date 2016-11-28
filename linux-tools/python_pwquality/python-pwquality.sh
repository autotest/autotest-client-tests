#!/bin/sh
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
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
## File :        python-pwquality.sh
##
## Description:  Test the APIs of python-pwquality package.
##
## Author:      Tejaswini Sambamurthy <tejaswin.linux.vnet.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/python_pwquality
source $LTPBIN/tc_utils.source

TESTS_DIR="${LTPBIN%/shared}/python_pwquality"

REQUIRED="python"


################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED

	set `find /usr/lib* -name libcrack\*`
	[ -f $1 ] &&  tc_break_if_bad $? "cracklib not installed properly"
	
	set `find /usr/lib* -name pwquality\*`
        [ -f $1 ] &&  tc_break_if_bad $? "python-pwquality not installed properly"
	
	# Take a back up of pwquality.conf
	if [ -f /etc/security/pwquality.conf ];then
		mv /etc/security/pwquality.conf /etc/security/pwquality.conf.bak 
	else
		tc_info "/etc/security/pwquality.conf not found" && return
	fi
}

function tc_local_cleanup()
{
	mv /etc/security/pwquality.conf.bak /etc/security/pwquality.conf
}

function run_test()
{
	pushd $TESTS_DIR &> /dev/null

	# Testing the python wrapper
	tc_register "Python-wrapper"
	# Setting the limits in pwquality.conf, refer to pwquality.conf for details
	cat > /etc/security/pwquality.conf <<- EOF
	minlen = 11
	maxrepeat = 1
	EOF

	# Run the python application that uses the wrapper
	python pypwquality.py >$stdout 2>$stderr
	tc_pass_or_fail $? "Python wrapper failed"

	popd &> /dev/null
}

################################################################################
# MAIN
################################################################################
TST_TOTAL=1
tc_setup
run_test
