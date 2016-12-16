#!/bin/sh
# vi: set ts=8 sw=8 autoindent noexpandtab:
################################################################################
##                                                                            ##
## (C) Copyright IBM Corp. 2012                                               ##
##                                                                            ##
## This program is free software;  you can redistribute it and#or modify      ##
## it under the terms of the GNU General Public License as published by       ##
## the Free Software Foundation; either version 2 of the License, or          ##
## (at your option) any later version.                                        ##
##                                                                            ##
## This program is distributed in the hope that it will be useful, but        ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   ##
## for more details.                                                          ##
##                                                                            ##
## You should have received a copy of the GNU General Public License          ##
## along with this program;  if not, write to the Free Software               ##
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA    ##
##                                                                            ##
################################################################################
#
# File :	udisks.sh
#
# Description:	Tests for udisks package.
#
# Author:	Gowri Shankar <gowrishankar.m@in.ibm.com>
#
# History:	03 Aug 2012 - Initial version - Gowri Shankar
################################################################################
# source the utility functions
################################################################################
#cd $(dirname $0)
#LTPBIN="${LTPBIN%/shared}/udisks2"
RUNTST="${LTPBIN%/shared}/udisks2/tests/integration-test"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
installed="udisks2"
required="blkid dd killall kpartx losetup make mdadm parted python udevadm umount"
test_luks=0
test_smart=0
test_lvm=0


################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return

	# enable applicable tests to run
	tc_exec_or_break cryptsetup && test_luks=1 && ((TST_TOTAL+=1))
	tc_exec_or_break skdump && test_smart=1 && ((TST_TOTAL+=1))
	tc_exec_or_break pvcreate && test_lvm=1 && ((TST_TOTAL+=1))
}

#
# tests A
#  check udisks tool using tests from community
#
function test_functionality
{
	tc_register "check if udisks detects supported file systems"
	$RUNTST FS >$stdout 2>&1
	tc_pass_or_fail $? "some file system tests fail"

	tc_register "run partition tests for udisks"
	$RUNTST Partitions >$stdout 2>&1
	tc_pass_or_fail $? "partition tests fail"

	tc_register "run loop device tests for udisks"
	$RUNTST Loop >$stdout 2>&1
	tc_pass_or_fail $? "loop device tests fail"

	tc_register "check various global options"
	$RUNTST GlobalOps >$stdout 2>&1
	tc_pass_or_fail $? "some global options fail"

	if [ $test_luks ]; then
		tc_register "run luks tests for udisks"
		$RUNTST Luks >$stdout 2>&1
		tc_pass_or_fail $? "luks tests fail"
	else
		tc_warn "skipped LUKS tests.."
	fi

	if [ $test_smart ]; then
		tc_register "run S.M.A.R.T tests for udisks"
		$RUNTST Smart >$stdout 2>&1
		tc_pass_or_fail $? "SMART tests fail"
	else
		tc_warn "skipped S.M.A.R.T status tests"
	fi

	if [ $test_lvm ]; then
		tc_register "run LVM tests for udisks"
		$RUNTST LVM >$stdout 2>&1
		tc_pass_or_fail $? "LVM tests fail"
	else
		tc_warn "skipped LVM tests.."
	fi
}

################################################################################
# main
################################################################################
TST_TOTAL=4 # plus some more tests
tc_setup

test_functionality
