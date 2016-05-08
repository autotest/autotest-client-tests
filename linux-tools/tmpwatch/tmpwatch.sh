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
## File :	tmpwatch.sh
##
## Description:	Tests for tmpwatch package.
##
## Author:	Gowri Shankar <gowrishankar.m@in.ibm.com>
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN="${PWD%%/testcases/*}/testcases/bin"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
installed="tmpwatch"
required="grep"
busypid=""

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return
}

function tc_local_cleanup()
{
	kill -9 $busypid &>/dev/null
}

#
# test A
#  check tmpwatch functionality wrt access time, modification time and change
#  time.
#
function test_tmpwatch()
{
	# create test files for tmpwatch
	mkdir $TCTMP/testdir
	touch $TCTMP/testdir/afile
	touch $TCTMP/testdir/bfile
	touch $TCTMP/testdir/cfile
	touch $TCTMP/testdir/dfile

	# prepare files for an update in modification time
	sleep 1m
	echo 1 > $TCTMP/testdir/bfile

	# prepare files for an update in change time
	sleep 1m
	chmod +x $TCTMP/testdir/cfile

	# prepare files for an update in access time
	touch $TCTMP/testdir/dfile

	# wait for couple of sec to go ahead by 2m in below tests
	tc_info "all test files are created"
	sleep 2s

	tc_register "check tmpwatch by change time"
	tmpwatch --test -c 10m $TCTMP/testdir | grep -q removing
	[ $? -eq 1 ]
	tc_fail_if_bad $? "file should not be removed"
	tmpwatch -c 2m $TCTMP/testdir >$stdout 2>$stderr
	[[ ! -e $TCTMP/testdir/afile && \
	     -e $TCTMP/testdir/bfile && \
	     -e $TCTMP/testdir/cfile ]]
	tc_pass_or_fail $? "change time check failed"

	tc_register "check tmpwatch by modification time"
	tmpwatch --test -m 10m $TCTMP/testdir | grep -q removing
	[ $? -eq 1 ]
	tc_fail_if_bad $? "file should not be removed"
	tmpwatch -m 2m $TCTMP/testdir >$stdout 2>$stderr
	[[ ! -e $TCTMP/testdir/afile && \
	     -e $TCTMP/testdir/bfile && \
	   ! -e $TCTMP/testdir/cfile ]]
	tc_pass_or_fail $? "modification time check failed"

	tc_register "check tmpwatch by access time"
	tmpwatch --test -u 10m $TCTMP/testdir | grep -q removing
	[ $? -eq 1 ]
	tc_fail_if_bad $? "file should not be removed"
	tmpwatch -u 1m $TCTMP/testdir >$stdout 2>$stderr
	[[ ! -e $TCTMP/testdir/afile && \
	   ! -e $TCTMP/testdir/bfile && \
	   ! -e $TCTMP/testdir/cfile && \
	     -e $TCTMP/testdir/dfile ]]
	tc_pass_or_fail $? "access time check failed"

	tc_register "check tmpwatch on a busy file"
	# create a busy file for --fuser check by copying sleep binary
	# and its modification time is also long back for the test to
	# run right away.
	cp -rp `which sleep` $TCTMP/testdir/dfile
	$TCTMP/testdir/dfile 5m &
	busypid=$!
	TC_SLEEPER_PIDS=$busypid
	tmpwatch -m --fuser 1m $TCTMP/testdir >$stdout 2>$stderr
	[[ -e $TCTMP/testdir/dfile ]]
	tc_pass_or_fail $? "busy file is removed"

	tc_register "check tmpwatch to exclude file owner"
	tmpwatch -m -U root 1m $TCTMP/testdir >$stdout 2>$stderr
	[[ -e $TCTMP/testdir/dfile ]]
	tc_pass_or_fail $? "root's test file is removed"
}

################################################################################
# main
################################################################################
TST_TOTAL=5
tc_setup
test_tmpwatch
