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
## File :	squashfs-tools.sh
##
## Description:	test squashfs-tools  utilities
##
## Author:	Sandesh Chopdekar, sandesh_vc@in.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source


################################################################################
# global variables
################################################################################

DATADIR=""
SQUASHDIR=""
UNSQUASHDIR="" 
MOUNTDIR=""


###############################################################################
# utility functions
###############################################################################

function tc_local_setup()
{
	# Create files/directories for testing.  
	DATADIR="$TCTMP/data"
	SQUASHDIR="$TCTMP/data/squash"
	UNSQUASHDIR="$TCTMP/unsquash" 
	MOUNTDIR="$TCTMP/sqmnt"

	# Create Dir 
	mkdir  $DATADIR 
	mkdir  $SQUASHDIR 
	mkdir  $SQUASHDIR/sq0 
	mkdir  $SQUASHDIR/sq1 
	mkdir  $SQUASHDIR/sq2
	mkdir  $MOUNTDIR 
	tc_break_if_bad $? "Directory Creation Error " || exit 

	# Create files, under dir.  
	echo "file0 Sample squashfs file" > $SQUASHDIR/sq0/file0
	echo "file1 Sample squashfs file" > $SQUASHDIR/sq0/file1
	echo "file0 Sample squashfs file" > $SQUASHDIR/sq1/file0
	echo "file1 Sample squashfs file" > $SQUASHDIR/sq1/file1
	echo "file1 Sample squashfs file" > $SQUASHDIR/sq2/file1
	echo "file0 Sample squashfs file" > $SQUASHDIR/sq2/file0
	tc_break_if_bad  $? "File Creation Error" || exit
}

#
# Clean-up the data dirs created
function tc_local_cleanup()
{ 
	umount $MOUNTDIR 
}

################################################################################
# the testcase functions
################################################################################

#
# Compare the directories
#
function comp_dir
{
	local iCount=0 

	while [ "$iCount" -lt 3 ] 
	do 
		[ -e $1/sq$iCount ]
		tc_fail_if_bad $? " Dir sq$iCount does not exists " || return

		# If the dir exists, check for the files.
		[ -e $1/sq$iCount/file0 ]
		tc_fail_if_bad $? " File sq$iCount/file0 does not exists " || return 

		# Verify the contents
		#grep -w "$(cat $1/sq$iCount/file0)" $2/sq$iCount/file0 >$stdout 2>$stderr

		###### Bug 64261 fix #######
                m="$(cat $1/sq$iCount/file0)"
                grep "\([^a-zA-Z_0-9]\+$m[^a-zA-Z_0-9]*\$\)\|\(^[^a-zA-Z_0-9]*$m[^a-zA-Z_0-9]\+\)\|\(^$m$\)" $2/sq$iCount/file0 >$stdout 2>$stderr 
		###### Fix End ############

		tc_fail_if_bad $? " Contents of file $1/sq$iCount/file0  bad" || return

		# If the dir exists, check for the files.
		[ -e $1/sq$iCount/file1 ]
		tc_fail_if_bad $? " File sq$iCount/file1 does not exists " || return

		# Verify the contents
		#grep -w "$(cat $1/sq$iCount/file1)" $2/sq$iCount/file1 >$stdout 2>$stderr

		###### Bug 64261 fix #######
                m="$(cat $1/sq$iCount/file1)"
                grep "\([^a-zA-Z_0-9]\+$m[^a-zA-Z_0-9]*\$\)\|\(^[^a-zA-Z_0-9]*$m[^a-zA-Z_0-9]\+\)\|\(^$m$\)" $2/sq$iCount/file1 >$stdout 2>$stderr
                ###### Fix End ############

		tc_fail_if_bad $? " Contents of file $1/sq$iCount/file1  bad" || return 
			
		((++iCount))
	done

	return 0

}

#
# test01	installation check
# Checking if the commands exist. 
#
function test01()
{
	tc_register "installation check"
	tc_executes mksquashfs  unsquashfs
	tc_pass_or_fail $? "mksquashfs-tools not properly installed" 
}


#
# test02	basic  mksquashfs
#
function test02()
{
	tc_register "mksquashfs basic "

	# basic mksquashfs
	mksquashfs $SQUASHDIR $DATADIR/fs_image02 >$stdout 2>$stderr 
	tc_fail_if_bad $? "mksquashfs failed " || return

	# Simple unsquashfs, except the -dest
	unsquashfs  -dest  $UNSQUASHDIR $DATADIR/fs_image02  >$stdout 2>$stderr
	tc_fail_if_bad $? "unsquashfs failed " || return 

	# Check the directory trees
	comp_dir $UNSQUASHDIR $SQUASHDIR || return
	tc_pass
}


#
# test03	Test option block size
#
function test03()
{
	tc_register "mksquashfs block size"

	mksquashfs $SQUASHDIR  $DATADIR/fs_image03 -b 8192 >$stdout 2>$stderr 
	tc_fail_if_bad $? "Unexpected result from mksquashfs " || return

	unsquashfs  -force -dest  $UNSQUASHDIR $DATADIR/fs_image03 >$stdout 2>$stderr
	tc_fail_if_bad $? " unsquashfs failed " || return 

	comp_dir $UNSQUASHDIR $SQUASHDIR || return 

	#file $DATADIR/fs_image03 | grep -w "blocksize\:\ 8192 bytes" >$stdout 2>$stderr

	####### Bug 64261 Fix #######
        file $DATADIR/fs_image03 | grep "blocksize\:\ 8192 bytes" >$stdout 2>$stderr
        ###### Fix End ##############

	tc_pass_or_fail $? "Block Check failed  "
}


#
# test04	Test mounting of squashfs image.
#
function test04()
{
	tc_register "mksquashfs mount"

	# basic mksquashfs
	mksquashfs $SQUASHDIR  $DATADIR/fs_image04 >$stdout 2>$stderr
	tc_fail_if_bad $? "mksquashfs for mount failed " || return

	# Mount SquashFS image
	mount -t squashfs -o loop $DATADIR/fs_image04 $MOUNTDIR  >$stdout 2>$stderr
	tc_fail_if_bad $? "mount failed " || return

	comp_dir $MOUNTDIR $SQUASHDIR || return

	cat $MOUNTDIR/sq1/file0 >$stdout 2>$stderr
	tc_fail_if_bad $? "Reading from file failed " || return

	! echo "Sample squashfs file" > $MOUNTDIR/sq1/file0 >$stdout 2>$stderr
	tc_pass_or_fail $? "Write did not failed as expected"
}


#
# test05	Test no compress options
#
function test05()
{
	tc_register "mksquashfs no compress"

	mksquashfs $SQUASHDIR  $DATADIR/fs_image05 -noI -noD -noF >$stdout 2>$stderr
	tc_fail_if_bad $? "mksquashfs (no-compress) failed " || return

	# Simple unsquashfs, except the -dest
	unsquashfs  -force -dest  $UNSQUASHDIR $DATADIR/fs_image05  >$stdout 2>$stderr
	tc_fail_if_bad $? "unsquashfs failed " || return 

	# Check the directory trees
	comp_dir $UNSQUASHDIR $SQUASHDIR || return
	tc_pass
}


#
# test06	Test -no-append option
#
function test06()
{
	tc_register "mksquashfs -no-append "

	mksquashfs $SQUASHDIR  $DATADIR/fs_image06 >$stdout 2>$stderr
	tc_fail_if_bad $? "first mksquashfs failed " || return

	mksquashfs $SQUASHDIR  $DATADIR/fs_image06 -noappend >$stdout 2>$stderr
	tc_fail_if_bad $? "second mksquashfs (-noappend) failed " || return

	# unsquashfs
	unsquashfs  -force -dest  $UNSQUASHDIR $DATADIR/fs_image06  >$stdout 2>$stderr
	tc_fail_if_bad $? "unsquashfs failed " || return 

	# Check the directory trees
	comp_dir $UNSQUASHDIR $SQUASHDIR || return
	tc_pass
}

################################################################################
# main
################################################################################

TST_TOTAL=6

tc_setup 
tc_root_or_break || exit

test01 &&
test02 &&
test03 &&
test04 &&
test05 &&
test06 
