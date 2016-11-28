#!/bin/bash
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
#
# File :	e2fsprogs.sh
#
# Description:	Test e2fsprogs package
#
# Author:	Robb Romans <robb@austin.ibm.com>
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/e2fsprogs
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

# variables exported to interface with the various test scripts

export test_dir="${LTPBIN%/shared}/e2fsprogs/tests/"  # set by test_script()
export test_name="" # set by test_script()
export cmd_dir="."  # required by individual tests
export SRCDIR="${LTPBIN%/shared}/e2fsprogs/tests/" # required by e_icount_normal, e_icount_opt

# required executables:
REQUIRED="which dd cat chattr cmp head ls lsattr mke2fs rm sed"

# tests to execute, some are skipped from testsuite, so excluding them
TESTS=`ls -d $test_dir/[a-zA-Z]_*|grep -v -e e_brel_bma -e e_irel_ima \
-e f_h_unsigned -e f_h_reindex -e f_h_normal -e f_h_badroot -e f_h_badnode \
-e i_e2image -e m_quota -e t_quota_1on -e t_quota_2off`

# This test PASS but no "ok" file is created
NO_OK_FILE="f_mmp"


################################################################################
# utility functions
################################################################################

#
# Setup specific to this testcase
#
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return
	sed -i 's:../e2fsck/e2fsck:/sbin/e2fsck:' $test_dir/f_badbblocks/expect.1 \
	$test_dir/f_zero_group/expect.1 $test_dir/f_zero_super/expect.1 \
	$test_dir/f_crashdisk/expect.1  $test_dir/f_illitable/expect.1 \
	$test_dir/f_illitable_flexbg/expect.1 $test_dir/f_misstable/expect.1 \
	$test_dir/f_resize_inode/expect $test_dir/f_zero_inode_size/expect.1 \
	$test_dir/f_desc_size_bad/expect.1 $test_dir/r_1024_small_bg/script \
	$test_dir/r_ext4_small_bg/script
	cp $test_dir/mke2fs.conf.in $test_dir/mke2fs.conf
	cp $test_dir/test_one.in $test_dir/test_one
}

function tc_local_cleanup()
{
	rm -f $test_dir/mke2fs.conf
}

################################################################################
# testcase functions
################################################################################

# Function:		test_script
#
# Description:		- exercise modified e2fsprogs "make check" tests
#
# Parameters:		
#
# Return		- zero on success
#			- return value from commands on failure
#
function test_script() {
	cd $test_dir

	for test_dir in $TESTS ; do

		[ -d $test_dir ]
		tc_break_if_bad "$?" "The test directory $test_dir does not exist." || continue

		test_name=`echo $test_dir | sed -e 's;.*/;;'`
		tc_register "$test_name"

		if [ -f $test_dir/name ]; then
			test_description=`head $test_dir/name`
			tc_info "$test_description"
		fi
		if [ -f $test_dir/script ]; then
			source $test_dir/script 2>$stderr
			if [ -f $test_dir.failed ] ; then 
				cat $test_dir.failed >>$stderr
				[ -f $test_dir.out ] && cat $test_dir.out >$stdout
			fi
			[ $test_name = $NO_OK_FILE ] || [ -f $test_dir.ok ]
			tc_pass_or_fail "$?" "Unexpected results from $test_name."

		else
			test_base=`echo $test_name | sed -e 's/_.*//'`
			default_script=defaults/${test_base}_script
			[ -f $default_script ]
			tc_break_if_bad "$?" "Missing test script." || continue
			source $default_script 2>$stderr
                        if [ -f $test_dir.failed ] ; then
				cat $test_dir.failed >>$stderr
				[ -f $test_dir.out ] && cat $test_dir.out >$stdout
			fi
                        [ -f $test_dir.ok ]
                        tc_pass_or_fail "$?" "unexpected results from $description."
		fi
	done
}

################################################################################
# MAIN
################################################################################

# Function:	main
#
# Description:	- Execute all tests, report results
#
# Exit:		- zero on success
#		- non-zero on failure
#

set $TESTS; TST_TOTAL=$#
tc_setup
source $test_dir/../test_config
test_script

