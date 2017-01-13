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
## File :	unzip.sh
##
## Description:	Test unzip
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/unzip
source $LTPBIN/tc_utils.source

################################################################################
# the testcase functions
################################################################################

#
# test01	Test that unzip can uncompress .zip file.
#
function test01()
{
	tc_register "unzip"
	tc_exec_or_break diff || return

	unzip -d $TCTMP tst_unzip_file.zip >$stdout 2>$stderr
	tc_fail_if_bad $? "unzip failed" || return

	while read line ; do
		ls $TCTMP/$line >$stdout 2>$stderr
		tc_fail_if_bad $? "$line not extracted from zip file" || return
		grep -q "file" $TCTMP/$line || continue
		grep -q "$line-data" $TCTMP/$line
		tc_fail_if_bad $? "$line extracted from zip file but with bad data" || return
	done < expected_unzip
	tc_pass_or_fail 0 # pass if we get this far
}

################################################################################
# main
################################################################################

tc_setup	# standard tc_setup

TST_TOTAL=1
test01
