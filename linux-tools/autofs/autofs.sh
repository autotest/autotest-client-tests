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
## File :	autofs.sh
##
## Description:	Test autofs package
##
## Author:	Andrew Pham, apham@austin.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
tc_setup

TST_TOTAL=1
REQUIRED="automount ls sleep"
MOUNTPOINT="$TCTMP/mountpoint"
AUTOFILE="$TCTMP/auto.mfile$$"
MOVED=0
RUNNING=0

function tc_local_cleanup()
{
	[ $MOVED -eq 1 ] && mv /etc/auto.master.save /etc/auto.master
	if [ $RUNNING -eq 1 ]; then
		service autofs reload &> /dev/null
	else
		tc_service_stop_and_wait autofs
	fi
}

################################################################################
# testcase functions
################################################################################


function test01()
{
        tc_register "Installation check"
        tc_executes automount
        tc_pass_or_fail $? "autofs not properly installed"
}

function test02()
{	
	local TEMP

	tc_register "autofs"

	# save the autofs status
	tc_service_status autofs
	if [ $? -eq 0 ]; then
		RUNNING=1
	fi
	
	# save the auto.master
	if [ -e /etc/auto.master ]; then
		cp /etc/auto.master /etc/auto.master.save
		MOVED=1
	fi	
	
	mkdir -p $MOUNTPOINT
	echo "test   -fstype=iso9660,ro,loop :$LTPBIN/image.img" > $AUTOFILE
	echo "$MOUNTPOINT   $AUTOFILE" >> /etc/auto.master
	
	if [ $RUNNING -eq 1 ]; then
		service autofs reload &> /dev/null
	else
		tc_service_start_and_wait autofs
	fi

	tc_info "Sleep 5 seconds to start autofs server "
	sleep 5

	# to get the fs to mount
	ls $MOUNTPOINT/test &> /dev/null

	[ -e $MOUNTPOINT/test/file1.txt -a -e $MOUNTPOINT/test/file2.txt ] &&
        [ -e $MOUNTPOINT/test/file3.txt -a -e $MOUNTPOINT/test/d2/klmnopqr.sys ] &&
        [ -e $MOUNTPOINT/test/d2/12345678  -a -e $MOUNTPOINT/test/d2/abcdefgh ]
	tc_pass_or_fail $? "$MFS/test is not mounted correctly."
	return
}
################################################################################
# main
################################################################################
tc_root_or_break || exit 

# Check if supporting utilities are available
tc_exec_or_break  $REQUIRED || exit

test01 &&
test02
