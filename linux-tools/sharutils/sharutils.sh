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
## File :	sharutils.sh
##
## Description:	Test sharutils package
##
## Author:	Robb Romans <robb@austin.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

REQUIRED="cmp"

################################################################################
# testcase functions
################################################################################

function test01 {
	tc_register "Is sharutils installed?"
	tc_executes uudecode uuencode shar unshar
	tc_pass_or_fail $? "Sharutils is not properly installed"
}


function test02 {
	tc_register "uuencode/uudecode - ascii"
	uuencode -m /etc/passwd $TCTMP/mypass > $TCTMP/foo.uue
	tc_fail_if_bad $? "uuencode failed" || return
	uudecode $TCTMP/foo.uue
	tc_fail_if_bad $? "uudecode failed" || return
	diff -u /etc/passwd $TCTMP/mypass
	tc_pass_or_fail $? "file different after uudecode"
}

function test02_1 {
	tc_register "uuencode/uudecode - binary"
	uuencode -m `which cp` $TCTMP/mycp > $TCTMP/foo.uue
	tc_fail_if_bad $? "uuencode failed" || return
	uudecode $TCTMP/foo.uue
	tc_fail_if_bad $? "uudecode failed" || return
	diff -u `which cp` $TCTMP/mycp
	tc_pass_or_fail $? "file different after uudecode"
}


function test03 {
	tc_register "shar/unshar"
	mkdir $TCTMP/stuff
	cp /etc/passwd `which cp` $TCTMP/stuff  # grab something to archive
	shar $TCTMP/stuff/* > $TCTMP/foo.shar 2>/dev/null
	tc_fail_if_bad $? "shar failed" || return
	mv $TCTMP/stuff $TCTMP/stuffOrig
	unshar $TCTMP/foo.shar &>/dev/null
	diff -u $TCTMP/stuffOrig $TCTMP/stuff >$stdout 2>$stderr
	tc_pass_or_fail $? "unshar failed"
}
	

####################################################################################
# MAIN
####################################################################################

# Function:	main
#

#
# Exit:		- zero on success
#		- non-zero on failure
#
TST_TOTAL=4
tc_setup
tc_exec_or_break $REQUIRED || exit
test01 && \
test02 && test02_1 && \
test03
