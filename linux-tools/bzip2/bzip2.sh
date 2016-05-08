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
## File :	bzip2.sh						      ##
##
## Description:	Test basic functionality of bzip2/bunzip2 commands	      ##
##
## Author:	Yu-Pao Lee						      ##
###########################################################################################
## source the utility functions

ME=$(readlink -f $0)
#LTPBIN=${ME%%/testcases/*}/testcases/bin
TSTCSDIR=${LTPBIN%/shared}/bzip2		# Bug 64116
source $LTPBIN/tc_utils.source

################################################################################
# the testcase functions
################################################################################

function test01()
{
	tc_register "installation check"
	tc_executes bzip2 bunzip2
	tc_pass_or_fail $? "bzip2 not installed properly"
}

function test02()		# test bzip2 and bunzip2
{
	local infile
	local outfile

	tc_register "test bzip2 -1 and bunzip2"

	# check that required commands are present
	tc_exec_or_break cp cmp || return

	# Bug 64116 Fix Start
	#cp -p $LTPBIN/sample* $TCTMP 
	cp -p $TSTCSDIR/sample* $TCTMP 
	# Fix End

	# ensure required files exist before testing
	tc_exist_or_break $TCTMP/sample1.ref $TCTMP/sample1.bz2 \
		$TCTMP/sample2.ref $TCTMP/sample2.bz2 \
		$TCTMP/sample3.ref $TCTMP/sample3.bz2  || return

	tc_info "Using bzip2 -1 to compress file..."
	infile=$TCTMP/sample1.ref
	outfile=$TCTMP/sample1.rb2
	bzip2 -1 < $infile > $outfile 2>$stderr
	tc_fail_if_bad $? "bzip2 -1 failed" || return
	
	tc_info "Using bunzip2 to decompress files..."
	infile=$TCTMP/sample1.bz2
	outfile=$TCTMP/sample1.tst
	bunzip2 < $infile > $outfile 2>$stderr
	tc_fail_if_bad $? "bunzip2 failed" || return

	tc_info "1st compare..."
	infile=$TCTMP/sample1.ref
	outfile=$TCTMP/sample1.tst
	cmp $infile $outfile 2>$stderr
	tc_fail_if_bad $? "cmp sample1.ref sample1.tst failed" || return

	tc_info "2nd compare..."
	infile=$TCTMP/sample1.bz2
	outfile=$TCTMP/sample1.rb2
	cmp $infile $outfile 2>$stderr
	tc_pass_or_fail $? "cmp sample1.bz2 sample1.rb2 failed"
}


function test03()
{
	local infile
	local outfile

	tc_register "test bzip2 -2 and bunzip2"

	tc_info "Using bzip2 -2 to compress file...."
	infile=$TCTMP/sample2.ref
	outfile=$TCTMP/sample2.rb2
	bzip2 -2 < $infile > $outfile 2>$stderr
	tc_fail_if_bad $? "bzip2 -2 failed" || return

	tc_info "Using bunzip2 to decompress file...."
	infile=$TCTMP/sample2.bz2
	outfile=$TCTMP/sample2.tst
	bunzip2 < $infile > $outfile 2>$stderr
	tc_fail_if_bad $? "bunzip2 command failed" || return

	tc_info "1st compare..."
	infile=$TCTMP/sample2.ref
	outfile=$TCTMP/sample2.tst
	cmp $infile $outfile 2>$stderr
	tc_fail_if_bad $? "cmp sample2.ref sample2.tst failed" || return

	tc_info "2nd compare..."
	infile=$TCTMP/sample2.bz2
	outfile=$TCTMP/sample2.rb2
	cmp $infile $outfile 2>$stderr
	tc_pass_or_fail $? "cmp sample2.bz2 sample1.rb2 failed"
}


function test04()
{
	local infile
	local outfile

	tc_register "test bzip2 -3 and bunzip2 -s"

	tc_info "Using bzip2 -3 to compress file...."
	infile=$TCTMP/sample3.ref
	outfile=$TCTMP/sample3.rb2
	bzip2 -3 < $infile > $outfile 2>$stderr
	tc_fail_if_bad $? "bzip2 -3 failed" || return

	tc_info "Using bunzip2 -s to decompress file...."
	infile=$TCTMP/sample3.bz2
	outfile=$TCTMP/sample3.tst
	bunzip2 -s < $infile > $outfile 2>$stderr
	tc_fail_if_bad $? "$TCTMP/bzip.err" "bunzip2 command failed" || return

	tc_info "1st compare..."
	infile=$TCTMP/sample3.ref
	outfile=$TCTMP/sample3.tst
	cmp $infile $outfile 2>$stderr
	tc_fail_if_bad $? "cmp sample3.ref sample3.tst failed" || return

	tc_info "2nd compare..."
	infile=$TCTMP/sample3.bz2
	outfile=$TCTMP/sample3.rb2
	cmp $infile $outfile 2>$stderr
	tc_pass_or_fail $? "cmp samp1e3.bz2 sample3.rb2 failed"
}

################################################################################
# Function    :  main
################################################################################

TST_TOTAL=4

# standard tc_setup
tc_setup
tc_run_me_only_once

test01 &&
test02 &&
test03 &&
test04
