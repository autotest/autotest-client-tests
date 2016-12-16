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
# File :	dmsetup.sh
#
# Description:	Test dmsetup.
#
#
# Author:	Suzuki K P <suzukikp@in.ibm.com> 
#

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/device_mapper_multipath
source $LTPBIN/tc_utils.source

disk0_img=""
disk1_img=""
disk0=""
disk1=""
size=""
STATUS=""
TAB_STATUS=""

function create_disks() 
{
	disk0_img="$TCTMP/disk0.img"
	disk1_img="$TCTMP/disk1.img"

	dd if=/dev/zero of=$disk0_img bs=1K count=50K >$stdout 2>$stderr || tc_break "Failed to create disk0 image($disk0_img) file"
	dd if=/dev/zero of=$disk1_img bs=1K count=50K >$stdout 2>$stderr || tc_break "Failed to create disk1 image($disk1_img) file"

	disk0=`losetup --show -f $disk0_img`
	disk1=`losetup --show -f $disk1_img`

	[ "$disk0" != "" ] || tc_break "Failed to create $disk0 on $disk0_img"
	[ "$disk1" != "" ] || tc_break "Failed to create $disk1 on $disk1_img"

	size=`blockdev --getsz $disk0`
	# As on the new kernels cat /proc/partitions shows half #blocks as in blockdev
	size=$((size/2))
}		

destroy_disks()
{
	[ "$disk0" != "" ] && ( losetup -d $disk0 || tc_break "Failed to remove $disk0")
	[ "$disk1" != "" ] && ( losetup -d $disk1 || tc_break "Failed to remove $disk1")
	rm -rf $disk0_img
	rm -rf $disk1_img
}

tc_local_setup()
{
	tc_executes dmsetup || exit
	tc_executes losetup dd mke2fs || {
		tc_info "You require losetup, dd, mke2fs for running device-mapper tests"
		exit
	}
	create_disks
}

function tc_local_cleanup() 
{
	umount $TCTMP/tmp_mount/ &>/dev/null
	dmsetup remove_all &>/dev/null
	destroy_disks &>/dev/null
}

settle()
{
	sleep 1
}
# Gets the device status for $1 into STATUS
get_device_state()
{
	STATE=`dmsetup info $1 2>/dev/null | grep "^State" | awk '{print $2}'`
}
# Similarly for table status for $1
function get_table_state()
{
	TAB_STATE=`dmsetup info $1 2>/dev/null | grep "^Tables" | awk '{print $3}'`
}

# Pass 	$1 = device
#	$2 = Expected State
#	$3 = Expected Table status
function verify_device_state_table()
{

	get_device_state $1
	get_table_state $1

	rc=0
	if [ "$STATE" != "$2" ] || [ "$TAB_STATE" != "$3" ]
	then
		tc_fail "Bad State for device $1. Device State: $STATE Table: $TAB_STATE" \
                         "Expected Device State: $2 Table: $3"
	else
		tc_pass
	fi
}


# Create a linear device with $disk0 $disk1. 
# Dump the table information and the 
function test_create_table()
{
	local DM="$1"

	tc_register "Create device with a table"

	dmsetup create $DM 2>$stderr<<EOF
0 $size linear $disk0 0
$size $size linear $disk1 100
EOF
	tc_fail_if_bad $? "Failed to create $DM from $disk0, $disk1" \
	"$(< $stderr)" || return

	verify_device_state_table $DM "ACTIVE" "LIVE"
	settle # settle the devices
}

function test_remove_dev()
{
	local DM="$1"
	tc_register "Remove a device"

	dmsetup remove $DM 2>$stderr

	tc_pass_or_fail $? "Failed to remove $1" || return
	settle # settle the device
}
# Test creating a device with "no table"
function test_create_notable()
{
	local DM="$1"
	tc_register "Create a device with no table"

	dmsetup create $DM --notable 2>$stderr

	tc_fail_if_bad $? "Failed to create $DM with --notable" || return

	verify_device_state_table $DM "ACTIVE" "None"
	settle
}

# Tests load table operation.
# Loads table with "striped" target type.
function test_load_table()
{
	local DM="$1"
	
	sz=$((size+size))
	tc_register "Load table"
	dmsetup load $DM <<EOF
0 $sz striped 2 256  $disk0 0 $disk1 0
EOF
	tc_fail_if_bad $? "Load table command failed" || return
	
	#Now the state of the device should ACTIVE and Table : INACTIVE"
	verify_device_state_table $DM "ACTIVE" "INACTIVE"
	settle
}
#
# Test the suspend/resume operation on the device
# After suspend, the status of the device should show "SUSPENDED"
# A resume operation changes the state of the device back to "ACTIVE"
# Also, it makes the necessary changes in the table which were committed earlier.
# In our case, we loaded a table using "load" in test_load_table. After the resume,
# we should see the new table in action, and the state should be "LIVE"
function test_suspend_resume ()
{
	local DM="$1"
	tc_register "Suspend device"
	
	dmsetup suspend $DM 2>$stderr

	tc_fail_if_bad $? "Failed to suspend $DM" || return

	get_device_state $DM

	if [ "$STATE" != "SUSPENDED" ]
	then
		tc_fail "Device is not suspended. Current Statuse : $STATUS"
		return
	fi

	tc_pass

	tc_register "Resume device"
	
	dmsetup resume $DM 2>$stderr

	tc_fail_if_bad $? "Failed to resume $DM"  || return

	get_device_state $DM
	get_table_state $DM
	
	if [ "$STATE" != "ACTIVE" ]
	then
		tc_fail "Device state is not active. State: $STATUS" 
		return
	fi

	if [ "$TAB_STATE" != "LIVE" ]
	then 
		tc_fail "Device table is not LIVE. State: $TAB_STATUS"
		return
	fi
	
	dmsetup table $DM 2>$stderr | awk '{print $1 " " $2 " " $3 " " $4 " " $5 " " $7 " " $9 }' > $TCTMP/table.out
	echo "0 $((size+size)) striped 2 256 0 0" >$TCTMP/table.exp
	
	diff -qb $TCTMP/table.out $TCTMP/table.exp 2>>$stderr
	
	tc_fail_if_bad $? "Unexpected table for $DM" \
	"========= table expected ============" \
	"$(< $TCTMP/table.exp)" \
	"========= table actual ============"\
	"$(< $TCTMP/table.out)"\
	"========= End of log ========" || return

	tc_pass
	rm -f $TCTMP/table.* &>/dev/null
	settle
}
	
function test_remove_all()
{
	tc_register "Remove all"

	dmsetup remove_all 2>$stderr
	tc_fail_if_bad $? "Failed to remove_all"

	rc=`dmsetup info 2>/dev/null`

	if [ "$rc" != "No devices found" ]
	then
		tc_fail "Remove all : got unexpected o/p" \
		"Expected : No devices found"\
		"Result : $rc" || return
	fi
	tc_pass
	settle
}

# This is a tricky test. Testing the snapshot functionality
# We use two disks disk0 and disk1.
#
# 1.	Create a filesystem on disk0 and create a test file.
# 2.	Now create a snapshot for disk0 with disk1 as a COW device
# 3.	Mount the new dm device and Update the above test file
# 4.	Unmount the filesystem and verify that the test file is unchanged on the disk0
#
function test_snapshot()
{
	tmp_dir=$TCTMP/tmp_mount
	DM="test_dm-snap"
	
	tc_register "Snapshot"
	mkdir -p $tmp_dir

	tc_info "Create a filesystem on disk0 and create a test file."
	mke2fs -F $disk0 &>$stdout
	tc_fail_if_bad $? "Failed to format $disk0 as ext2" || return
	mount $disk0 $tmp_dir
	echo "Hello World" > $tmp_dir/test.txt
	umount $tmp_dir
	
	tc_info "create a snapshot for disk0 with disk1 as a COW device"
	echo "losetup:" >$stdout	
	losetup -a >>$stdout
	local args="0 `blockdev --getsz $disk0` snapshot $disk0 $disk1 P 32"
	echo $args | dmsetup create $DM >>$stdout 2>$stderr 
	tc_fail_if_bad $? "Failed to create snapshot with args \"$args\"" || return

	tc_info "Mount the new dm device and Update the above test file"
	mount /dev/mapper/$DM $tmp_dir
	echo "Good Bye" > $tmp_dir/test.txt
	umount $tmp_dir

	dmsetup remove_all 2>$stderr
	
	tc_info "Unmount the filesystem and verify that the test file is unchanged on the disk0"
	mount $disk0 $tmp_dir
	echo "Hello World" > $tmp_dir/test.exp
	diff -b $tmp_dir/test.exp $tmp_dir/test.txt
	tc_fail_if_bad $? "Snapshot fails. DM allows writes to original device" || (umount $tmp_dir && return)

	umount $tmp_dir

	tc_pass
}
	
	
	

tc_setup

dm="test_dm-0"

test_create_table $dm &&
test_remove_dev  $dm &&
test_create_notable $dm && 
test_load_table $dm &&
test_suspend_resume $dm

## Remove all the devices.
test_remove_all &&
test_snapshot
