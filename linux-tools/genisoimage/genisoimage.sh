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
# File :	genisoimage.sh
#
# Description:	Test genisoimage and related tools.
#
#
# Author:	Suzuki K P <suzukikp@in.ibm.com> 
#
################################################################################
#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

function tc_local_cleanup()
{
	umount $TCTMP/tmp_mount &>/dev/null
}

function test_installation()
{
	tc_register "installation"
	tc_executes "genisoimage isoinfo isovfy isodump" || {
		tc_break "Missing commands" && exit
	}
	tc_pass
}

function test_genisoimage()
{
	tc_register "genisoimage"

	mkdir -p $TCTMP/iso/ $TCTMP/tmp_mount

# Populate the directory to create ISO image from
	cp  $LTPBIN/tc_utils.source $TCTMP/iso/
	dd if=/dev/zero of=$TCTMP/iso/dummy.file bs=1024 count=1024 &>$stdout
	[ $? -ne 0 ] && tc_info "WARN: dd command failed"
# Create the iso image.
	genisoimage -R -p test -o $TCTMP/image.iso $TCTMP/iso/ &>$stdout 
	tc_fail_if_bad $? "genisoimage command failed" || return

	`file $TCTMP/image.iso | grep -q "ISO 9660"`
	tc_fail_if_bad $? "Created iso file is not an ISO 9660 format." || return
# Mount the image to compare the iso image and the source files.
	mount -o loop $TCTMP/image.iso $TCTMP/tmp_mount 2>$stderr
	status=$?
	#Flushing off  mounting readonly warning
	tc_ignore_warnings "mounting read-only"
	tc_fail_if_bad $status "Unable to mount generated iso image." || return
	`touch $TCTMP/tmp_mount/read_only.txt 2>/dev/null`
	if [ $? -eq 0 ];then
		tc_fail " ISO is not Read Only"
	fi

	diff -ar $TCTMP/tmp_mount $TCTMP/iso/ >$stderr
	tc_fail_if_bad $? "The files in the iso image differs from the actual" || return
	tc_pass
}

function test_isovfy()
{
	tc_register "isovfy"
	isovfy $TCTMP/image.iso >$stdout 2>$stderr
	tc_pass_or_fail $? "isovfy detected problems with iso image"
}

function test_isoinfo()
{
	tc_register "isoinfo"
	isoinfo -R -f -i $TCTMP/image.iso >$stdout 2>$stderr
	tc_fail_if_bad $? "isoinfo failed" || return
	grep -q tc_utils.source $stdout && grep -q dummy.file $stdout;
	tc_pass_or_fail $? "Expected tc_utils.source and dummy.file" 
}

tc_setup
TST_TOTAL=4
test_installation &&  
test_genisoimage && 
test_isoinfo &&
test_isovfy

