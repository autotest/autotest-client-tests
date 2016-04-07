#!/bin/bash
###########################################################################################
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
# File :        dirsplit.sh
#
# Description:  Check that dirsplit works.
#
# Author:	Athira Rajeev
#
##################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/dirsplit/TEST
REQUIRED="dirsplit mkisofs"
                                                                                                                                                              
################################################################################
# the testcase functions
################################################################################

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_executes $REQUIRED || break
	
	# Create directory structure, directories
	# and files to test dirsplit
	mkdir -p $TESTDIR/DIR

	pushd $TESTDIR >/dev/null
	dd if=/dev/zero of=test1.dat bs=256 count=10240 >$stdout 2>$stderr
	tc_break_if_bad_rc $? "Failed to create File test1.dat of size 2.5M"

	dd if=/dev/zero of=test2.dat bs=256 count=10240 >$stdout 2>$stderr
	tc_break_if_bad_rc $? "Failed to create File test2.dat of size 2.5M"

	dd if=/dev/zero of=DIR/test3.dat bs=256 count=10240 >$stdout 2>$stderr
	tc_break_if_bad_rc $? "Failed to create File test3.dat of size 2.5M"
	
	dd if=/dev/zero of=test4.dat bs=512 count=10240 >$stdout 2>$stderr
	tc_break_if_bad_rc $? "Failed to create File test4.dat of size 5M"

	popd >/dev/null
}

#
# tc_local_cleanup              cleanup unique to this testcase
#
function tc_local_cleanup()
{
	# Remove the test directory 
	# created to test dirsplit
	rm -rf $TESTDIR
}
#
# test_dirsplit        Test for dirsplit
#
function test_dirsplit()
{
	pushd $TESTDIR >/dev/null
	tc_register "Test dirsplit with -s ( to specify size of medium where files will be copied to )"

	# split the contents of TEST
	# directory into target mediums of size 6M	
	dirsplit -s 6M $TESTDIR >$stdout 2>$stderr
	tc_fail_if_bad $? "dirsplit -s failed" || return

	# Check if this has created three vol_*.list ( default catalog ) files
	# and this has the files test1.dat, test2.dat and DIR directory
	[ -e vol_1.list ] && [ -e vol_2.list ] && [ -e vol_3.list ] && \
	[ `grep -E 'DIR/test3.dat|test2.dat|test1.dat|test4.dat' vol*.list | wc -l` -eq 4 ]
	tc_pass_or_fail $? "dirsplit -s failed to create 3 volumes"

	# Removing the created vol_*.list files
	rm -r vol*.list

	# Using -p option will add prefix to target directories
	# Example -p result implies creating result1, result2 etc
	tc_register "Test dirsplit with -p option ( first part of catalog name )"

	dirsplit -s 6M $TESTDIR -p $TCTMP/result >$stdout 2>$stderr
	tc_fail_if_bad $? "dirsplit -p failed" || return

	# check if the vol_*.list ( default catalog ) files
	# are created under prefix - result
	[ -e $TCTMP/result1.list ] && [ -e $TCTMP/result2.list ] && [ -e $TCTMP/result3.list ] && \
	[ `grep -E 'test4.dat|DIR/test3.dat|test2.dat|test1.dat' $TCTMP/result*.list | wc -l` -eq 4 ]
	tc_pass_or_fail $? "dirsplit -p failed to create 3 volumes"

	# This test -e2 will fail as -e2 will
	# try to put all files in single directory
	# and target medium size is 6M here.
	tc_register "Test dirsplit with -e option"
	
	dirsplit -s 6M -e2 $TESTDIR >$stdout 2>$stderr
	rc=$?
	if [ `grep -vc "Too large object" $stderr` -eq 0 ];then cat /dev/null > $stderr; fi
	[ $rc -ne 0 ]
	tc_pass_or_fail $? "dirsplit with -e2 failed"
	
	tc_register "dirsplit with -e4 option"

	# e4 where rest files will be stored in another medium
	dirsplit -s 6M -e4 $TESTDIR >$stdout 2>$stderr
	tc_fail_if_bad $? "dirsplit with -e4 failed" || return

	# Verify this creates 2 vol_*.list ( default catalog ) files
	[ -e vol_1.list ] && [ -e vol_2.list ]
	tc_pass_or_fail $? "dirsplit with -e4 failed to create catalog files"

	# Removing the created vol_*.list files
	rm -r vol*.list

	tc_register "Test dirsplit with -f option ( to filter only some files/directories)"

	dirsplit -s 6M -f '/DIR/' $TESTDIR >$stdout 2>$stderr
	tc_pass_or_fail $? "dirsplit -f failed"

	tc_register "dirsplit with -l option"
	# Using -l will create directories having symbolic link
	# files in source directory
	dirsplit -s 6M -l $TESTDIR -p $TCTMP/symlink_dir >$stdout 2>$stderr
	tc_fail_if_bad $? "dirsplit with -l failed" || return
	
	# verify if default ( vol_* directories ) are
	# created and has symlinks to source directories.
	[ -d "$TCTMP/symlink_dir1" ] && [ -d "$TCTMP/symlink_dir2" ] && [ -d "$TCTMP/symlink_dir3" ]
	tc_fail_if_bad $? "Failed to created directories with -l" || return

	test=$(find $TCTMP -type l | xargs ls -l | grep -E "\\$TESTDIR/test1.dat|\\$TESTDIR/test2.dat|\\$TESTDIR/test4.dat|\\$TESTDIR/DIR/test3.dat" | wc -l)
	[ $test -eq 4 ]
	tc_pass_or_fail $? "dirsplit with -l failed to create symlink"

	tc_register "dirsplit with -L option"
	# Using -L will create directories with hard links
	dirsplit -s 6M -L $TESTDIR -p $TCTMP/hardlink_dir >$stdout 2>$stderr
	tc_fail_if_bad $? "dirsplit with -L failed" || return

	# verify if this has created three directories
	# and hardlink with files in TEST dir
	[ -d "$TCTMP/hardlink_dir1" ] && [ -d "$TCTMP/hardlink_dir2" ] && [ -d "$TCTMP/hardlink_dir3" ]
	tc_fail_if_bad $? "Failed to create directories with -L" || return

	[ `ls $TCTMP/hardlink_dir*/* | grep -E 'test4.dat|test3.dat|test2.dat|test1.dat' | wc -l` -eq 4 ]
	tc_pass_or_fail $? "dirsplit with -L failed to create files in target directory"

	# The use of dirsplit is that the .list files 
	# can be utilized by mkisofs to generate .iso files
	# path-list option is used to pass list file.
	tc_register "Verify catalog file is usable with mkisofs"

	mkisofs -D -r --joliet-long -graft-points -input-charset iso-8859-1 -path-list $TCTMP/result1.list -o test.iso &>$stdout
	tc_fail_if_bad $? "mkisofs failed to create iso with catalog file" || return

	# Test if iso file is created
	[ -e test.iso ]
	tc_pass_or_fail $? "Failed to create iso file with dirsplit catalog file"
	
	# Option -m will move files to target medium.
	tc_register "Test dirsplit -m ( move files to target directories )"

	dirsplit -m -s 6M $TESTDIR -p $TCTMP/backup >$stdout 2>$stderr
	tc_fail_if_bad $? "dirsplit -m failed" || return

	# verify this has created three backup directories
	[ -d "$TCTMP/backup1" ] && [ -d "$TCTMP/backup2" ] && [ -d "$TCTMP/backup3" ]
	tc_fail_if_bad $? "dirsplit with -m failed to created backup directories" || return

	# verify the files are present in backup directories
	[ `ls $TCTMP/backup*/* | grep -E 'test4.dat|test3.dat|test2.dat|test1.dat' | wc -l` -eq 4 ]
	tc_fail_if_bad $? "dirsplit with -m failed to move files to target medium"

	#Verify the files are moved from TEST
	[ `find $TESTDIR -type f | wc -l` = "0" ]
	tc_pass_or_fail $? "dirsplit with -m failed to move files from TEST"

	popd > /dev/null
}

################################################################################
# Main
################################################################################

TST_TOTAL=9

tc_setup
test_dirsplit


################################################################################
# End Of Main
################################################################################
