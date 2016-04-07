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
## File :       dosfstools.sh
##
## Description: This testcase tests the functionalitis of the dosfstools package
##
## Author:       Andrew Pham, apham@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TST_TOTAL=1
REQUIRED="modprobe mount umount touch grep ls"

function have_vfat_support()
{
	tc_executes modprobe && modprobe vfat &>/dev/null
}

################################################################################
# the testcase functions
################################################################################

function install_check()
{
	tc_register "installation check"

	tc_executes dosfsck mkdosfs 
	tc_fail_if_bad $? "dosfstools not properly installed"
}

function TC_mkdosfs()
{
	tc_register "mkdosfs and dosfsck" 
	
	mkdosfs -C -F 32 $TCTMP/mm_mount.img 1024 >/dev/null #2>$stderr
	tc_fail_if_bad $?  "$summary2" || return 1
	
	if have_vfat_support ; then
		tc_info "mounting vfat"
		mkdir $TCTMP/mnt >&/dev/null
		if tc_is_busybox mount ; then
			mount $TCTMP/mm_mount.img $TCTMP/mnt -t vfat -o loop >$stdout 2>/$stderr
		else		
			mount $TCTMP/mm_mount.img $TCTMP/mnt -o loop >$stdout 2>$stderr
		fi
		tc_fail_if_bad $? "could not mount VFAT filesystem" || return
		
		touch $TCTMP/mnt/f1 $TCTMP/mnt/f2 $TCTMP/mnt/f3 >&/dev/null
		umount $TCTMP/mnt
	else
		tc_info "no vfat support so can't mount the filesystem"
	fi
	
	dosfsck $TCTMP/mm_mount.img >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected response from dosfsck" || return

	grep mm_mount.img $stdout | grep files | grep -q clusters
	tc_pass_or_fail $?  "Unable to use the newly created FAT32 filesystem"

}
################################################################################
# main
################################################################################

TST_TOTAL=2
tc_setup

[ "$TCTMP" ] && rm -rf $TCTMP/*

# Check if supporting utilities are available
tc_exec_or_break  $REQUIRED || exit 1

install_check  &&
TC_mkdosfs
