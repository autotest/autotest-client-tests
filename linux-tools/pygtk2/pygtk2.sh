#!/bin/bash
################################################################################
##                                                                            ##
##copyright 2003, 2016 IBM Corp                                               ##
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
## You should have received a copy of the GNU General Public Licens           ##
## along with this program;  if not, write to the Free Software               ##
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA    ##
##                                                                            ##
## File :        pygtk2.sh                                                    ##
##                                                                            ##
## Description: This testcase tests pygtk2  package                           ##
##                                                                            ##
## Author:      Anup Kumar, anupkumk@linux.vnet.ibm.com                       ##
################################################################################
# source the utility functions
######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/pygtk2
source $LTPBIN/tc_utils.source
FIVDIR=${LTPBIN%/shared}/pygtk2
REQUIRED="python vncserver"

################################################################################
# Testcase functions
################################################################################

function tc_local_setup()
{
        tc_root_or_break || exit
        tc_exec_or_break $REQUIRED
        
        # search the pygtk2 packages
      tc_check_package "pygtk2"
        tc_break_if_bad $? "pygtk2 package is not installed"

        # test case were failing to set the display
        vncserver :123456 -SecurityTypes None >$stdout 2>$stderr
        export DISPLAY=$hostname:123456

        # create directory to run the test
        if [ ! -d "/root/.local/share/" ]; then
                    mkdir -p /root/.local/share/
        fi

}

function tc_local_cleanup()
{
        # Stop the vncserver running at 123456
         vncserver -kill :123456 > /dev/null
}

function run_test()
{       
        tc_info "calling the test from tests directory through runtest utility "
        # start the test with runtest frame work
        pushd $FIVDIR &>/dev/null
        tc_register "running the test utility"
        python tests/runtests.py 1>$stdout 2>$stderr
	grep OK $stderr
	RC=$?
	grep FAILED $stderr
	if [ $? -ne 0 ]; then
		cat /dev/null > $stderr
	fi
        tc_pass_or_fail $RC "runtest failed to execute" || return
	popd &>/dev/null
}
#
# main
#
tc_setup && \
run_test
