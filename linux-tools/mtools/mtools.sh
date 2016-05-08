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
## File :	mtools.sh
##
## Description:	test mtools support.
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

do_umount="no"	# set to yes after successful mount. checked in tc_local_cleanup
mtools_commands="mattrib mbadblocks mcat mcd mcopy mdel mdeltree mdir
		mdu mformat minfo mlabel mmd mmount mmove mpartition
		mrd mren mshowfat mtoolstest mtype mzip"

################################################################################
# utility functions
################################################################################

#
# tc_local_setup	setup for this testcase
#			Be sure to run test01 first.
#
function tc_local_setup()
{
	image_file=$TCTMP/mtools.img
	mnt=$TCTMP/mnt
	mkdir $mnt
	export MTOOLSRC=$TCTMP/mtools.conf
}

#
# tc_local_cleanup	cleanup specific to this testcase
#
function tc_local_cleanup()
{
	[ "$do_umount" = "yes" ] && umount $mnt
}

################################################################################
# the testcase functions
################################################################################

#
# test01	install check
#
function test01()
{
	tc_register	"install check"
	tc_executes $mtools_commands
	tc_pass_or_fail $? "mtools support not installed properly"
}

#
# test02	mtoolstest
#
function test02()
{
	tc_register	"mtoolstest"
	mtoolstest > $stdout 2>$stderr
	tc_pass_or_fail $? "mtoolstest failed" || return
	cp $stdout $MTOOLSRC
	cat >> $MTOOLSRC <<-EOF
	drive T:
		file="$image_file" fat_bits=16
		tracks=0 heads=0 sectors=0 hidden=0
		offset=0x0
		partition=0
		mformat_only 
	EOF
}

#
# terst03	mformat
#
function test03()
{
	tc_register	"mformat"
	dd if=/dev/zero of=$image_file count=4096 &>/dev/null
	mformat -f 2880 t: >$stdout 2>$stderr
	tc_pass_or_fail $? "mformat failed"
}

#
# terst04	mcopy
#
function test04()
{
	tc_register	"mcopy"
	mcopy $0 t: >$stdout 2>$stderr
	tc_fail_if_bad $? "mcopy failed" || return
	#
	do_umount="yes"
	mount -t msdos $image_file $mnt -o loop >$stdout 2>$stderr
	tc_fail_if_bad $? "msdos filesystem created by mformat failed to mount" || return
	#
	diff $0 $mnt/`basename $0` >$stdout 2>$stderr
	tc_pass_or_fail $? "diff of copied file failed"
}

#
# terst05	mdir
#
function test05()
{
	tc_register	"mdir"
	[ "$do_umount" = "yes" ] && umount $mnt
	do_umount="no"

	mdir t: >/dev/null
	tc_pass_or_fail $? "dir disk failed"
}

#
# terst06	minfo
#
function test06()
{
	tc_register	"minfo"
	minfo t: >$TCTMP/info 2>$stderr
	tc_fail_if_bad $? "print parameter of disk failed" || return

	grep "filename=\"$image_file\"" $TCTMP/info >$stdout 2>$stderr
	tc_pass_or_fail $? "wrong information for disk"
}

#
# terst07	mlabel
#
function test07()
{
	tc_register	"mlabel"
	mlabel -s t: >/dev/null
	tc_pass_or_fail $? "label disk failed"
}

#
# terst08	mmd
#
function test08()
{
	tc_register	"mmd"
	mmd t:test_md >/dev/null
	tc_fail_if_bad $? "make directory failed" || return

	mdir t: >$TCTMP/dirlist
	grep "test_md.*<DIR>" $TCTMP/dirlist >/dev/null
	tc_pass_or_fail $? "directory is not created"
}

#
# terst09	mrd
#
function test09()
{
	tc_register	"mrd"
	mmd t:test_rd >/dev/null
	mrd t:test_rd >/dev/null
	tc_fail_if_bad $? "remove directory failed" || return

	mdir t: >$TCTMP/dirlist
	grep "test_rd.*<DIR>" $TCTMP/dirlist >/dev/null
	[ $? -ne 0 ]
	tc_pass_or_fail $? "directory is not removed"
}

################################################################################
# main
################################################################################

TST_TOTAL=9

tc_setup

tc_root_or_break || exit

test01 &&
test02 &&
test03 &&
test04 &&
test05 &&
test06 &&
test07 &&
test08 &&
test09
