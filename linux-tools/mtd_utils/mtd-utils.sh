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
## File :   mtd-utils.sh
##
## Description: This program tests basic functionality of mtd-utils command.
##
## Author:   Gong Jie <gongjie@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
DATADIR=${LTPBIN%/shared}/mtd_utils/mtd_files

declare -i MTD_BYTES    # memory size to use, in bytes, max 32MB
declare -i MTD_KBYTES   # memory size to use, in Kbytes
declare -i MTD_ERASE    # erase size to use

#
# local setup
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break rm grep mknod modprobe rmmod || return
	#modprobe mtd

	#
  	# calculate the amount of memory to use.
	# Read the vmalloc free memory from /proc/meminfo
	#
	find_mtd_size
	if [ $MTD_KBYTES -le 8096 ]; then
		tc_info "There is note enough vmalloc memory available on your system to perform the tests"
		exit 1
	fi
	((MTD_BYTES=MTD_KBYTES*1024))
	((MTD_ERASE=MTD_KBYTES/128))    # Smaller amount for erase_size

	tc_info "Using $MTD_KBYTES Kbytes mtdram total_size."
	tc_info "Using $MTD_ERASE Kbytes mtdram erase_size."

	rm -f /dev/mtd0 && mknod -m 644 /dev/mtd0 c 90 0
	rm -f /dev/mtdblock0 && mknod -m 644 /dev/mtdblock0 b 31 0

}

#
# local cleanup
#
function tc_local_cleanup()
{
	rm -rf ${TMPIMG}
	rmmod jffs2 mtdchar mtdblock mtdram >$stdout 2>$stderr
	rmmod mtd_blkdevs  >$stdout 2>$stderr
}
# Find the possible mtd size from the vmalloc chunk available.
function find_mtd_size()
{
	declare -i low mem
	low=16384

	MTD_KBYTES=0

	mem=`cat /proc/meminfo | grep VmallocChunk | awk '{print $2}' 2>/dev/null`
	[ "$mem" == "" ] && return

	((mem-=4096))	#Leave at least 4M apart
	while [ $low -gt  $mem ] ; do
		((low-=1024))
	done
	MTD_KBYTES=$low
}
#
# test1: Installation check
#
function installcheck()
{
	tc_register "mtd-utils installation check"
	tc_executes doc_loadbios \
	            flash_info flash_erase flash_eraseall \
		    flash_lock flash_unlock flash_otp_info flash_otp_dump \
		    flashcp nandwrite  mkfs.jffs2 \
		    mtd_debug nanddump jffs2dump rfddump sumtool
	tc_fail_if_bad $? "mtd-utils is not installed properly." || return

	tc_info "Loading mtdram with total_size=$MTD_KBYTES erase_size=$MTD_ERASE"
	modprobe mtdram total_size=$MTD_KBYTES erase_size=$MTD_ERASE &&
	modprobe jffs2 &&
	modprobe mtdchar &&
	modprobe mtdblock &&
	modprobe mtdram >$stdout 2>$stderr
	
	tc_info "for ppcnf mtd is built into kernel"

	DEVICE=$(find   /dev -maxdepth 1 -name mtd$(grep 'mtdram test device' /proc/mtd  |  cut -d : -f 1 | cut -c 4 ))
	RC=1
	[ -n $DEVICE ] && RC=0
	tc_pass_or_fail $RC "Could not find mtd test device "
}

#
# test2: doc_loadbios test
#
function doc_loadbios_test()
{
	tc_register "doc_loadbios test"
	tc_exist_or_break $DATADIR/foo.img || return
	doc_loadbios $DEVICE $DATADIR/foo.img >$stdout 2>$stderr
	tc_pass_or_fail $? "doc_loadbios failed"
}

#
# test3: flash_info test
#
function flash_info_test()
{
	tc_register "flash_info test"
	flash_info $DEVICE >$stdout 2>$stderr
	tc_pass_or_fail $? "flash_info failed"
}

#
# test4: flash_erase test
#
function flash_erase_test()
{
	tc_register "flash_erase test"
	flash_erase  $DEVICE  >$stdout 2>$stderr
	tc_pass_or_fail $? "flash_erase failed"
}

#
# test5: flash_eraseall test
#
function flash_eraseall_test()
{
	tc_register "flash_eraseall test"
	flash_eraseall -j  $DEVICE  >$stdout 2>$stderr
	tc_pass_or_fail $? "flash_eraseall failed"
}

#
# test6: flashcp test
#
function flashcp_test()
{
	tc_register "flashcp test"
	tc_exist_or_break $DATADIR/foo.img || return
	flashcp -v $DATADIR/foo.img $DEVICE >$stdout 2>$stderr
	tc_pass_or_fail $? "flashcp failed"
}


#
# test10: mkfs.jffs2 test
#
function mkfs_jffs2_test()
{
	tc_register "mkfs.jffs2 test"
	mkfs.jffs2 -d . -o ${TMPIMG} -v >$stdout 2>&1
	tc_pass_or_fail $? "mkfs.jffs2 failed"
}

#
# test11: jffs2dump test
#
function jffs2dump_test()
{
	tc_register "jffs2dump test"
	jffs2dump -cv ${TMPIMG} >$stdout 2>$stderr 
	tc_pass_or_fail $? "jffs2dump failed"
}

#
# test12: sumtool test
#
function sumtool_test()
{
        tc_register "sumtool test"
        sumtool -i ${TMPIMG} -o /dev/null >$stdout 2>$stderr
        tc_pass_or_fail $? "sumtool failed"
}

			
#
# main
#
TST_TOTAL=9
tc_setup

TMPIMG=${TCTMP}/tmpimg

installcheck || exit
doc_loadbios_test
flash_info_test
flash_erase_test
flash_eraseall_test
flashcp_test
mkfs_jffs2_test
jffs2dump_test
sumtool_test


# ftl_format_test
# ftl_check_test
# mkfs_jffs_test
# flash_lock_test
# flash_unlock_test
# mtd_debug_test
# nanddump_test
# nandwrite_test

#
# test14: flash_ulock test
#
function flash_unlock_test()
{
	tc_register "flash_unlock test"
	flash_unlock /dev/mtd0 >$stdout 2>$stderr
	tc_pass_or_fail $? "flash_unlock failed"
}
#
# test7: ftl_format test
#
function ftl_format_test()
{
	tc_register "ftl_format test"
	ftl_format -s 1 -r 5 -b 0 /dev/mtd0 >$stdout 2>$stderr
	tc_pass_or_fail $? "ftl_format failed"
}
#
# test9: mkfs.jffs test
#
function mkfs_jffs_test()
{
	tc_register "mkfs.jffs test"
	mkfs.jffs -d . -o ${TMPIMG} -v9 >$stdout 2>&1
	tc_pass_or_fail $? "mkfs.jffs failed"
}
#
# test17: nandwrite test
#
function nandwrite_test()
{
	tc_register "nandwrite test"
	nanddump /dev/mtd0 $TCTMP/nanddump.out >$stdout 2>$stderr
	tc_pass_or_fail $? "nandwrite failed"
}
#
# test15: mtd_debug test
#
function mtd_debug_test()
{
	tc_register "mtd_debug test"
	mtd_debug info  /dev/mtd0 >$stdout 2>$stderr
	tc_fail_if_bad $? "mtd_debug info failed" || return
	mtd_debug read  /dev/mtd0 0 $MTD_BYTES $TCTMP/mtd_debug.out \
		>$stdout 2>$stderr
	tc_fail_if_bad $? "mtd_debug read failed" || return
	mtd_debug write /dev/mtd0 0 $MTD_BYTES $TCTMP/mtd_debug.out \
		>$stdout 2>$stderr
	tc_fail_if_bad $? "mtd_debug write failed" || return
	mtd_debug erase /dev/mtd0 0 $MTD_BYTES >$stdout 2>&1
	tc_pass_or_fail $? "mtd_debug erase failed"
}

#
# test13: flash_lock test
#
function flash_lock_test()
{
	tc_register "flash_lock test"
	flash_lock /dev/mtd0 0 -1 >$stdout 2>$stderr
	tc_pass_or_fail $? "flash_lock failed"
}
#
# test16: nanddump test
#
function nanddump_test()
{
	tc_register "nanddump test"
	nanddump /dev/mtd0 $TCTMP/nanddump.out 0 $MTD_BYTES >$stdout 2>$stderr
	tc_pass_or_fail $? "nanddump failed"
}
#
# test8: ftl_check test
#
function ftl_check_test()
{
	tc_register "ftl_check test"
	ftl_check -v /dev/mtd0 >$stdout 2>$stderr
	tc_pass_or_fail $? "ftl_check failed"
}
