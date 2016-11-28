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
### File : perl-IO-Compress.sh                                                 ##
##
### Description: This testcase tests perl-IO-Compress package                  ##
##
### Author:      Madhuri Appana <maappana@in.ibm.com>                          ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_IO_Compress
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/perl_IO_Compress"
REQUIRED="perl"

function tc_local_setup()
{
    tc_exec_or_break $REQUIRED
    rpm -q perl-IO-Compress >$stdout 2>$stderr
    tc_break_if_bad $? "perl-IO-Compress not installed"
}

function runtests()
{
	pushd $TESTDIR >$stdout 2>$stderr
	TESTS=`ls t/*.t`
	TST_TOTAL=`echo $TESTS | wc -w`
	TST_TOTAL=`expr $TST_TOTAL + 1`
	for test in $TESTS; do
		tc_register "Test $test"
		perl $test &>$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	done
	popd >$stdout 2>$stderr
	tc_register "Test the functionality of zipdetails command"
	#Create a zip file of 1 MB file
	dd if=/dev/zero of=$TCTMP/testfile bs=1024 count=1024 >$stdout 2>$stderr
	zip $TCTMP/testfile.zip $TCTMP/testfile >$stdout 2>$stderr
	zipdetails $TCTMP/testfile.zip >$stdout 2>$stderr
	tc_pass_or_fail $? "Failed to display details of zip file"
	
}

#
#MAIN
#
tc_setup
runtests
