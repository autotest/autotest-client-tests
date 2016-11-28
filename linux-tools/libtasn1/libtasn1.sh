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
### File :        libtasn1.sh                                                  ##
##
### Description:  This testcase tests libtasn1 package                         ##
##
### Author:       Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                     ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libtasn1
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/libtasn1/tests"

function tc_local_setup()
{
	set `find /usr/lib* -name libtasn1\*`
	[ -f $1 ] &&  tc_break_if_bad $? "libtasn1 not properly installed"

}

function run_test()
{
	pushd $TESTDIR &>/dev/null
	tests="`find  Test_* -not -name '*.*'` crlf"	
	TST_TOTAL=`echo $tests | wc -w`
	for test in $tests
	do
	    tc_register $test
	    ./$test >$stdout 2>$stderr
	    RC=$?
	    error_message=`grep -vc "Warning:" $stdout`
	    if [ $error_message -eq 0 ]
	    then
		cat /dev/null > $stderr
	    fi
	    tc_pass_or_fail $RC "$test failed"
	done
	popd &>/dev/null
}

#
# main
#
tc_setup && run_test
