#!/bin/bash
# vi: set ts=4 sw=4 expandtab :
################################################################################
##                                                                            ##
## (C) Copyright IBM Corp. 2009                                               ##
##                                                                            ##
## This program is free software;  you can redistribute it and#or modify      ##
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
# File :        fiv_verify.sh
#
# Description:  Run some overall system verification checks.
#
# Author:       Robert Paulsen, rpaulsen@us.ibm.com
#
# History:      May 29 2009 - Created. Robert Paulsen. rpaulsen@us.ibm.com
#                   At this time the only test is rpm verify for dependencies.
#               Aug 12 2009 (rcp) This will not be considered a PASS/FAIL test
#                           at this time. We will just collect the info for
#                           later comparison to customer builds.
#
#               Oct 07 2010 (kings). Change of manifest file name from jlbd.manifest to
#                           mcp.manifest        
#
# source the utility functions
ME=$(readlink -f $0)
#LTPBIN=${ME%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source          # sets LTPROOT

tc_local_setup()
{
    return      # nothing to do at this time.
}

tc_local_cleanup()
{
    return      # nothing to do at this time.
}

################################################################################
# the testcase functions
################################################################################

#
#   rpm verify
#
function test01()
{
    tc_register "rpm verify dependencies"
    tc_info "This testcase will not fail. It simply gathers rpm dependency data and places it in $LTPROOT/results/rpm_verify.txt"
    tc_executes rpm || {
        tc_info "Cannot collect any data without the rpm command. Giving up."
        tc_pass_or_fail 0
        return
    }
    local FILTER='|grep "Unsatisfied"'
    tc_executes grep &>/dev/null || FILTER=""

    tc_info "getting package list from manifest file"
    source /etc/mcp.manifest
    local RPM_LIST_variable_name=_MANIFEST_${_MANIFEST_PROJECT}_EXPORTROOT_RPMS
    local RPM_LIST=${!RPM_LIST_variable_name}
    local PKG_LIST=${RPM_LIST//.rpm/}

    tc_info "verifying rpms with filter $FILTER"
    2>/dev/null eval rpm --verify --nofiles $PKG_LIST $FILTER > $LTPROOT/results/rpm_verify.txt
    tc_pass_or_fail 0           # No failure. Just collecting info.
}

################################################################################
# main
################################################################################

TST_TOTAL=1
tc_setup                        # standard tc_setup

test01
