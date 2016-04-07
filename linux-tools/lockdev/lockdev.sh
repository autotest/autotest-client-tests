#!/bin/bash
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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
## File :        lockdev.sh                                                   ##
##                                                                            ##
## Description: This testcase tests lockdev package                           ##
##                                                                            ##
## Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
##                                                                            ##
################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
lock_path=/var/lock/lockdev

function tc_local_setup()
{
	tc_root_or_break
	tc_exec_or_break lockdev 

	## Find terminal devices for testing ##
	DEVICES=`ls /dev/tty[0-9]* /dev/hvc[0-9]*`
	check_dev_if_locked
    	[ "$DEV" ] || tc_conf_if_bad $? "No Device to test" || return

	## Find device major/minor no
	maj=`ls -l /dev/$DEV | awk -F " " '{print $5}' | cut -d',' -f1`
	min=`ls -l /dev/$DEV | awk -F " " '{print $6}' | cut -d',' -f1`
	
	## Check expected lck file format
	expect_lck_filename_frmt $maj $min
}

function check_dev_if_locked()
{
	for dev  in $DEVICES
	do
		DEV=`echo $dev | cut -d'/' -f3`
		if [ -e $lock_path/LCK..$DEV ]; then
			continue
		else
			break
		fi
	done
}

#
#It doesnt create any file. Its a function to
#get expected lck files format.
# e.g : LCK.004.001  LCK...16616  LCK..tty1

function expect_lck_filename_frmt()
{
	if (($1 >= 100)); then
		MAJ=$maj
	elif (($1 >= 10)); then  
		MAJ="0$maj"
	else  
		MAJ="00$maj"
	fi

	if (($2 >= 100)); then
		MIN=$min
	elif (($2 >= 10)); then
		MIN="0$min"
	else
		MIN="00$min"
	fi

	lck_file1="$lock_path/LK.000.$MAJ.$MIN"
	lck_file2="$lock_path/LCK..$DEV"
	lck_file3="$lock_path/LCK...$$"
}

function test_lockdev()
{
	tc_register "test lock with lockdev"
	lockdev -l $DEV >$stdout 2>$stderr
	[[ -e $lck_file1 && -e $lck_file2 && -e $lck_file3 ]]
	tc_fail_if_bad $? "Could not find LCK file" || return
	grep -q $$ $lck_file1 && \
	grep -q $$ $lck_file2 && \
	grep -q $$ $lck_file3
	tc_pass_or_fail $? "Could not find pid in LCK file"
	
	tc_register "Check lock with lockdev"
	lockdev -d $DEV >$stdout 2>$stderr
	[ "$?" = 1 ]
	tc_pass_or_fail $? "check lock with -d fail"

	tc_register "test unlock with lockdev"
	lockdev -u $DEV >$stdout 2>$stderr
	[[ ! -e $lck_file1 && ! -e $lck_file2 ]] 
	tc_pass_or_fail $? "release lock with -u fail"	
}

#
# main
#
TST_TOTAL=3
tc_setup && \
test_lockdev
