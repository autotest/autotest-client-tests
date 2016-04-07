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
## File :	lvm.sh
##
## Description:	Test lvm
##
## Author:	Xu Zheng, zhengxu@cn.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
part1=""
part2=""
vgname1="test_vg1_$$"
vgname2="test_vg2_$$"
lvname="test_vol_$$"
#lvchange lvcreate lvdisplay lvextend lvm lvmchange lvmdiskscan lvmsadc lvmsar lvreduce lvremove lvrename lvresize lvs lvscan pvchange pvcreate pvdisplay pvmove pvremove pvresize pvs pvscan vgcfgbackup vgcfgrestore vgchange vgck vgconvert vgcreate vgdisplay vgexport vgextend vgimport vgmerge vgmknodes vgreduce vgremove vgrename vgs vgscan vgsplit

function tc_local_setup()
{

	for i in 0 1 2 3 4 5 6 7 ;do
		part1="/dev/loop$i"
		losetup -a | grep -i "/dev/loop$i" >$stdout 2>$stderr  || break
	done

	for i in 7 6 5 4 3 2 1 ;do
		part2="/dev/loop$i"
		losetup -a | grep -i "/dev/loop$i" >$stdout 2>$stderr  || break
	done
	dd if=/dev/zero of=$TCTMP/lvm1 bs=1024 count=20480 &>/dev/null
	tc_break_if_bad $? "dd lvm1 error "
	sleep 1
	dd if=/dev/zero of=$TCTMP/lvm2 bs=1024 count=30720 &>/dev/null
	tc_break_if_bad $? "dd lvm2 error "
	sleep 1
	mke2fs -F $TCTMP/lvm1 &>/dev/null
	tc_break_if_bad $? "mke2fs lvm1 error "
	sleep 1
	mke2fs -F $TCTMP/lvm2 &>/dev/null
	tc_break_if_bad $? "mke2fs lvm2 error "
	sleep 1
	losetup $part1 $TCTMP/lvm1 >$stdout 2>$stderr
	tc_break_if_bad $? "losetup $part1 $TCTMP/lvm1  error "
	sleep 1
	losetup $part2 $TCTMP/lvm2 >$stdout 2>$stderr
	tc_break_if_bad $? "losetup $part2 $TCTMP/lvm2  error "
	rm -rf /dev/$vgname1/ /dev/$vgname2/
}

function tc_local_cleanup()
{
	lvremove $lvname &>/dev/null
	lvremove ${lvname}0 &>/dev/null
	vgremove $vgname1 &>/dev/null
	vgremove $vgname2 &>/dev/null
	pvremove $part1 &>/dev/null
	pvremove $part2 &>/dev/null
	losetup -d $part1 
	losetup -d $part2
}
################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"installation check"
	tc_executes lvm
	tc_pass_or_fail $? "lvm not properly installed"
}

#
# test02	dumpconfig formats help
#
function test02()
{
	tc_register "lvm dumpconfig"
	lvm dumpconfig &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "lvm formats"
	lvm formats &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "lvm help"
	lvm help &>$stdout
	tc_pass_or_fail $? "unexpected response" || return
}

#
# test03	pvchange pvcreate pvdisplay pvmove pvremove pvs pvscan 
#			vgcfgbackup vgcfgrestore vgchange vgck vgconve vgcreate vgdisplay vgexport vgextend vgimport vgmerge 
#			vgmknodes vgreduce vgremove vgrename vgs vgscan vgsplit
#			lvchange lvcreate lvdisplay lvextend lvm lvmdiskscan lvreduce lvremove 
#			lvrename lvresize lvs lvscan
#			pvresize lvmsadc lvmsar lvmchange //Command not implemented yet.
function test03()
{
	local size="16M"

	tc_register "modprobe dm_mod"
	modprobe dm_mod &>$stdout
	tc_pass_or_fail $? "unexpected response" || return 

	tc_register "pvcreate $part1 $part2"
	yes | pvcreate $part1 $part2 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "pvremove $part2"
	pvremove $part2 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return 

	tc_register "pvdisplay $part1"
	pvdisplay $part1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test pvs"
	pvs &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test pvscan"
	pvscan &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgcreate $vgname1 $part1"
	vgcreate $vgname1 $part1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgchange -a n"
	vgchange -a n $vgname1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgexport $vgname1"
	vgexport $vgname1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgimport $vgname1"
	vgimport $vgname1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test vgdisplay"
	vgdisplay $vgname1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test vgrename"
	vgrename $vgname1 $vgname2 &>$stdout
	tc_fail_if_bad $? "vgrename $vgname1 $vgname2 error!" || return
	vgrename $vgname2 $vgname1 &>$stdout
	tc_pass_or_fail $? "vgrename $vgname2 $vgname1 error!" || return

	tc_register "test vgs"
	vgs &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test vgscan"
	vgscan &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test vgck"
	vgck &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgcfgbackup $vgname1"
	vgcfgbackup $vgname1 &>$stdout
	tc_pass_or_fail  $? "unexpected response" || return

	tc_register "vgcfgrestore $vgname1"
	vgcfgrestore $vgname1 &>$stdout
	tc_pass_or_fail  $? "unexpected response" || return

	tc_register "vgconvert -M1 $vgname1"
	vgconvert -M1 $vgname1 &>$stdout
	tc_pass_or_fail  $? "unexpected response" || return

	tc_register "vgconvert -M2 $vgname1"
	vgconvert -M2 $vgname1 &>$stdout
	tc_pass_or_fail  $? "unexpected response" || return
	
	tc_register "pvcreate $part2"
	pvcreate $part2 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgcreate $vgname2 $part2"
	vgcreate $vgname2 $part2 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgmerge $vgname1 $vgname2"
	# mark $vgname2 inactive before merge (bug 71973)
	vgchange -a n $vgname2 &>$stdout
	vgmerge $vgname1 $vgname2 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgsplit $vgname1 $vgname2 $part2"
	vgsplit $vgname1 $vgname2 $part2 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgmknodes $vgname1 $vgname2"
	vgmknodes $vgname1 $vgname2 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "lvcreate -n $lvname -L $size $vgname1"
	lvcreate -n $lvname -L $size $vgname1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test lvrename"
	lvrename $vgname1 $lvname ${lvname}0 &>$stdout
	tc_fail_if_bad_rc $? "test lvrename error!" || return
	lvrename $vgname1 ${lvname}0 $lvname &>$stdout
	tc_pass_or_fail $? "test lvrename error!" || return

	tc_register "test lvmdiskscan"
	lvmdiskscan &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test lvscan"
	lvscan &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "test lvdisplay"
	lvdisplay &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgremove $vgname2"
	vgremove $vgname2 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return 

	tc_register "vgextend $vgname1 $part2"
	vgextend $vgname1 $part2 &>$stdout
	tc_pass_or_fail  $? "unexpected response" || return

	tc_register "lvextend -L +4 $vgname1/$lvname $part2"
	lvextend -L +4 $vgname1/$lvname $part2 &>$stdout
	tc_pass_or_fail  $? "unexpected response" || return

	tc_register "lvreduce -f -L -4 $vgname1/$lvname $part2"
	lvreduce -f -L -4 $vgname1/$lvname &>$stdout
	tc_pass_or_fail  $? "unexpected response" || return

	tc_register "lvresize -L +12 $vgname1/$lvname $part2"
	lvresize -L +20 $vgname1/$lvname &>$stdout
	tc_pass_or_fail  $? "unexpected response" || return

	tc_register "modprobe dm_mirror"
	modprobe dm_mirror &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "lvchange -pr $vgname1/$lvname"
	lvchange -pr $vgname1/$lvname &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "lvremove -f $vgname1/$lvname"
	sleep 2
	lvremove -f $vgname1/$lvname &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "lvcreate -n $lvname -L 8 $vgname1"
	lvcreate -n $lvname -L 8 $vgname1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "pvchange -x y $part1"
	pvchange -x y $part1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "pvmove -v -n $part1"
	pvmove -v -n $part1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return
	
	tc_register "lvremove -f $vgname1/$lvname"
	sleep 2
	lvremove -f $vgname1/$lvname &>$stdout
	tc_pass_or_fail $? "unexpected response" || return

	tc_register "vgremove $vgname1"
	vgremove $vgname1 &>$stdout
	tc_pass_or_fail $? "unexpected response" || return
}

################################################################################
# main
################################################################################

TST_TOTAL=46

# standard tc_setup
tc_setup

tc_root_or_break || exit

test01 &&
test02 &&
test03
