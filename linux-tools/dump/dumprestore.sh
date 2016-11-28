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
## File :	dump-restore.sh
##
## Description:	test dump and restore backup utilities
##
## Author:	Helen Pang, hpang@us.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/dump
source $LTPBIN/tc_utils.source

###############################################################################
# utility functions
###############################################################################

function tc_local_setup()
{
	tc_is_fstype $TCTMP ext2 || tc_is_fstype $TCTMP ext3 || tc_is_fstype $TCTMP ext4
	tc_break_if_bad $? "Only supported for ext2/ext3/ext4 filesystems"
	datadir=$TCTMP/datadir; mkdir -p $TCTMP/datadir
}


function tc_local_cleanup()
{
	if grep -q $TCTMP/tmp_mount /proc/mounts
	then
	umount $TCTMP/tmp_mount
	fi
	[ "$TC_LOOPDEV" != "" ] && ( losetup -d $TC_LOOPDEV || tc_break "Failed to remove $TC_LOOPDEV")
	return
}

################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register "installation check"
	tc_executes dump restore
	tc_pass_or_fail $? "not properly installed"
}

#
# test02	dump to file
#
function test02()
{
	tc_register "dump to file"
	tc_exec_or_break echo grep || return

	echo "Sample file to dump" > $datadir/samplefile
	set `ls -i $datadir/samplefile`; inode=$1
	/bin/sync
	dump -0f $TCTMP/dumpfile $datadir &>$stdout
	tc_fail_if_bad $? "unexpected RC from dump" || return

	grep -q "dump completed" $stdout 
	tc_pass_or_fail $? "expected to see \"dump completed\" in output"
}

#
# test03	restore TOC
#
function test03()
{
	tc_register "restore TOC"
	tc_exec_or_break grep || return
	
	# first look at TOC
	restore tf $TCTMP/dumpfile >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected result from restore tf $TCTMP/dumpfile" || return

	# ensure file name in TOC
	grep -q "$datadir/samplefile" $stdout &>$stderr
	tc_pass_or_fail $? "Expected to see \"samplefile\" file name in stdout"
}

#
# test04	restore filesystem
#
function test04()
{
	tc_register "restore filesystem"
	tc_exec_or_break cat grep || return

	# save copy of and remove original file in preparation for restore
	mv $datadir/samplefile $TCTMP/samplefile
	rm -rf $datadir
	/bin/sync

	# restore the dumped directory
	( cd /; echo y | restore -avf $TCTMP/dumpfile -x $datadir &>$stdout )
	tc_fail_if_bad $? "Unexpected result" || return

	# compare original to restored file
	diff $datadir/samplefile $TCTMP/samplefile >$stdout 2>$stderr
	tc_pass_or_fail $? "restored file did not match original"
}

#
# test05	restore -C
# "restore -C" works only when we backup an entire filesystem and not some 
# specific files. 
# This test requires some commands which may not be a part of many exportroots
# and we do not want the first 4 tests to be broken for these commands, 
# hence the test for those commands will be done and then this test will be 
# executed.
#
function test05()
{
	tc_register "restore -C (compare)"

	dd bs=1024  if=/dev/zero of=$TCTMP/tmp_fs count=2048 &>$stdout # output goes to stderr
	tc_break_if_bad $? "Error while trying to create temp fs" || return

	mkfs.ext2 -F $TCTMP/tmp_fs  &>$stdout 
	tc_break_if_bad $? "mkfs ext2 failed on tmp fs" || return

	tc_get_loopdev
	tc_break_if_bad $? "Error getting a loop device." || return

	losetup $TC_LOOPDEV $TCTMP/tmp_fs 1>$stdout 2>$stderr
	tc_break_if_bad $? "Could not setup a loop device." || return

	mkdir $TCTMP/tmp_mount >$stdout 2>$stderr
	mount $TC_LOOPDEV $TCTMP/tmp_mount >$stdout 2>$stderr
	tc_break_if_bad $? "mounting of tmp fs failed" || return

	mkdir $TCTMP/tmp_mount/datadir >$stdout 2>$stderr
	echo 'Sample file to dump' > $TCTMP/tmp_mount/datadir/samplefile

	/bin/sync >$stdout 2>$stderr
	dump -0f $TCTMP/dumpfile_new $TCTMP/tmp_mount &>$stdout # output goes to stderr
	tc_fail_if_bad $? "unexpected RC from dump" || return

	restore -vCf $TCTMP/dumpfile_new -L 0 >$stdout 2>$stderr
	tc_pass_or_fail $? "Error while restoring the dump." || return
}

################################################################################
# main
################################################################################

TST_TOTAL=4

# standard tc_setup
tc_setup

tc_root_or_break || exit

test01 &&
test02 &&
test03 &&
test04

COMMANDS="dd mkfs.ext2 mount losetup"

if tc_executes $COMMANDS
then
TST_TOTAL+=1
test05
fi
