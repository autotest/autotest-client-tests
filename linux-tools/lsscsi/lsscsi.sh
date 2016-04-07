#!/bin/sh
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
## File :	lsscsi.sh
##
## Description:	lsscsi utility for listing the scsi devices on the machine
##
## Authors:	Suzuki K P <suzukikp@in.ibm.com>
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
## Description:	lsscsi utility for listing the scsi devices on the machine
source $LTPBIN/tc_utils.source
num_devices=0

test_lsscsi()
{
	local vendor rev model rc=0 device

	tc_register "lsscsi"

	lsscsi >$stdout 2>$stderr

	for addr in `ls /sys/bus/scsi/devices | grep "^[0-9a-f]"`
	do
		vendor=`cat /sys/bus/scsi/devices/$addr/vendor`
		vendor=${vendor/%\ *} 
		rev=`cat /sys/bus/scsi/devices/$addr/rev`
		rev=${rev/%\ *}
		model=`cat /sys/bus/scsi/devices/$addr/model`
		dev=`ls /sys/bus/scsi/devices/$addr/block 2>/dev/null`
		if [ "$dev" != "" ];
		then
			device="/dev/$dev"
		else
			device="-"
		fi
		grep -q "[$addr].*$vendor.*$model.*$rev.*$device" $stdout 2>>$stderr
		if [ $? -ne 0 ]; then
			tc_info "Unable to find the device entry in lsscsi: ($addr | $vendor | $model | $rev)" 
			(rc++)
		fi
		((num_devices++))
	done
	tc_pass_or_fail $rc "Failed to find device info in lsscsi"
}

test_lsscsi_classic()
{
        tc_register "lsscsi -c"

        if [ $num_devices -eq 0 ]; then
                echo "Attached devices: none" > $TCTMP/scsi.out
        else
                sort /proc/scsi/scsi > $TCTMP/scsi.out
        fi
                lsscsi -c 2>$stderr | sed "s/Target:/Id:/" 2>>$stderr | sort >$stdout
                diff -ibup --ignore-all-space $stdout  $TCTMP/scsi.out >>$stderr 2>&1
        tc_pass_or_fail $? "Unexpected output from lsscsi -c"
}

tc_setup
test_lsscsi && test_lsscsi_classic
