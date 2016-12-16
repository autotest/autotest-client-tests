#!/bin/bash
################################################################################
##                                                                            ##
## (C) Copyright IBM Corp. 2013                                               ##
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
## File :        ibus.sh                                                      ##
##                                                                            ##
## Description: This testcase tests ibus  package                             ##
##                                                                            ##
## Author:      Ramesh YR, rameshyr@linux.vnet.ibm.com                        ##
##                                                                            ##
## History:     15th Feb 2013 - Initial version - Ramesh YR                   ##
################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/ibus
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/ibus/tests"

function tc_local_setup()
{
        rpm -q "ibus" >$stdout 2>$stderr
        tc_break_if_bad $? "ibus package is not installed"

}

function run_test()
{
        /usr/bin/vncserver :123456 -SecurityTypes None >$stdout 2>$stderr;sleep 10
        export DISPLAY=$hostname:123456
        # start the ibus-daemon to run the testcases under tests as pre-condition
        ibus-daemon  --daemonize  --cache=none --panel=disable --config=default >$stdout 2>$stderr;sleep 20
        pushd $TESTS_DIR &>/dev/null
        TESTS=`ls`
        TST_TOTAL=`echo $TESTS | wc -w`
        for test in $TESTS
        do
            tc_register "Test $test"
            # since the ibus-engine test case is calling a  deprecated method and there by ibus-daemon connection is getting closed
              if [[ $test == ibus-inputcontext ]];then
                 pro_id=$(ps -aef | grep -i ibus-daemon | grep -v auto | awk '{print $2}'|head -1)
                 kill -9 $pro_id
                 ibus-daemon  --daemonize  --cache=none --panel=disable --config=default >$stdout 2>$stderr;sleep 20
              fi
            ./$test >$stdout 2>$stderr
            tc_pass_or_fail $? "$test failed"
        done
        popd &>/dev/null
}
#
# main
#
tc_setup && \
run_test 
