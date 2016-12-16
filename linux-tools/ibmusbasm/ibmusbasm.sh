#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
################################################################################
##                                                                            ##
## (C) Copyright IBM Corp. 2007                                               ##
##                                                                            ##
## This program is free software;  you can redistribute it and or modify      ##
## it under the terms of the GNU General Public License as published by       ##
## the Free Software Foundation; either version 2 of the License, or          ##
## (at your option) any later version.                                        ##
##                                                                            ##
## This program is distributed in the hope that it will be useful, but        ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   ##
## for more details.                                                          ##
##                                                                            ##
## You should have received a copy of the GNU General Public License          ##
## along with this program;  if not, write to the Free Software               ##
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA    ##
##                                                                            ##
################################################################################
#
# File:         ibmusbasm.sh
#
# Description:  Test the USB interface to RSAII.
#
# Author:       Robert Paulsen, rpaulsen@us.ibm.com
#
# History:      01 Dec 2007 (rcp) created.
#
##################################################################################

# source the utility functions
#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/ibmusbasm
source $LTPBIN/tc_utils.source

###############################################################################
# globals
###############################################################################
RSAII_ID="vendor=04b3.*prodid=4001"     # regexpr for USB product ID in USB_DEVICES
USB_DEVICES=/proc/bus/usb/devices       # where to look for RSAII_ID
MOUNT_CMD="mount -t usbfs usbfs /proc/bus/usb" # mount command for usb
INIT_CMD="/etc/init.d/ibmasm"           # command to start daemon
MY_DIR=${LTPBIN%/shared}/ibmusbasm
UTILITY=$MY_DIR/mpcli.sh
INSTALL_SCRIPT=$MY_DIR/asmcli_install.sh
INSTALL_TARBALL=$MY_DIR/asmcli.tgz

REQUIRED="grep mount tar $UTILITY"

################################################################################
# utility function(s)
################################################################################

#
# local setup
#   Primarily, skip test if RSAII not available.
#
function tc_local_setup()
{

    tc_exec_or_break $REQUIRED || return

    # activate usb subsystem
    mount | grep -q usbfs || {
        $MOUNT_CMD >$stdout 2>$stderr
        tc_break_if_bad $? "Cannot mount usb filesystem" || exit
    }
    tc_exist_or_break $USB_DEVICES || exit

    # be sure RSAII hardware is available
    grep -qi "$RSAII_ID" $USB_DEVICES >$stdout 2>$stderr
    tc_break_if_bad $? "Does not appear that RSAII hardware is available" || exit

    # install asmcli.tgz if not already installed
    tc_executes /opt/IBMmpcli/bin/MPCLI.sh &>/dev/null || {
    	cp $INSTALL_TARBALL /tmp
	$INSTALL_SCRIPT >$stdout 2>$stderr
	tc_break_if_bad $? "Could not install $INSTALL_TARBALL" || exit
    }
    return 0
}

#
# cleanup
#
function tc_local_cleanup()
{
    tc_executes $INIT_CMD &>/dev/null && $INIT_CMD stop &>/dev/null
}

################################################################################
# test function(s)
################################################################################

#
# installation check
#
function test01()
{
    tc_register "installation check and start daemon"
    tc_exec_or_fail $INIT_CMD || return
    $INIT_CMD stop >$stdout 2>$stderr
    sleep 1
    $INIT_CMD start >$stdout 2>$stderr && sleep 1
    tc_pass_or_fail $? "could not start ibmusbasm daemon"
}

#
# vpd check
#
function test02()
{
    tc_register "vpd check"
    $UTILITY < $MY_DIR/vpd.script >$stdout 2>$stderr
    tc_fail_if_bad $? "Unexpected results from vpd.script" || return

    # A few things that seem safe to check for in the output
    local e expected=(
	    "build ID"
	    "Firmware VPD"
	    "Device Driver"
	    "file name"
	    "SUCCESS: getmpid"
	    "Date and Time:"
	    )
    for e in "${expected[@]}" ; do
        grep -qi "$e" $stdout 
        tc_fail_if_bad $? "Did not see expected \"$e\" in stdout" || return
    done
    tc_pass_or_fail 0 # PASS if we get this far
}

################################################################################
# main
################################################################################

tc_setup || exit

TST_TOTAL=2
test01 &&
test02
