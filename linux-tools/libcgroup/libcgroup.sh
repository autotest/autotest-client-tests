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
## File :        libcgroup.sh
##
## Description:  Test the tools of libcgroup package.
##
## Author:       Kumuda G, kumuda@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TESTS_DIR="${LTPBIN%/shared}/libcgroup/tests"

REQUIRED="cgclassify cgcreate cgdelete cgexec cgget cgset cgsnapshot lscgroup lssubsys"
################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    tc_root_or_break
      tc_check_package "libcgroup"
    tc_break_if_bad $? "libcgroup package is not installed" 
    tc_exec_or_break $REQUIRED || return
    tc_add_user_or_break 1>$stdout 2>$stderr
    tc_add_group_or_break 1>$stdout 2>$stderr
    if [ -e /etc/cgconfig.conf ]; then
	mv /etc/cgconfig.conf $TCTMP
	cat  >> /etc/cgconfig.conf << -EOF
	mount {
	cpuset  = /cgroup/cpuset;
	cpu     = /cgroup/cpu;
	cpuacct = /cgroup/cpuacct;
	memory  = /cgroup/memory;
	devices = /cgroup/devices;
	freezer = /cgroup/freezer;
	net_cls = /cgroup/net_cls;
	blkio   = /cgroup/blkio;
	}
-EOF
   fi
}

function tc_local_cleanup()
{
    cgdelete cpu:test
    tc_break_if_bad $? "failed to delete test cgroup"
    if [ -e $TCTMP/cgconfig.conf ]
    then
	mv $TCTMP/cgconfig.conf /etc/
    fi
}
#Bug117707 as per this bug "TEST13:FAIL : cgroup_modify_cgroup() Ret Value = 50016" is expected failure. please ignore this failure.
function run_test()
{
    pushd $TESTS_DIR &> /dev/null
    tc_register "libcgrouptest01"
    ./runlibcgrouptest.sh 1>$stdout 2>$stderr
    RC=$?
    # Exepected kill message in stderr, so excluding it
    grep -v "line 300:" $stderr > $stderr
    tc_pass_or_fail $RC "test failed"
    popd &> /dev/null
    #cleanup by restarting the cgconfig service
    tc_service_restart_and_wait cgconfig
}

function test01()
{
    tc_register "cgcreate"
    cgcreate -g cpu:$TC_TEMP_USER -t $TC_TEMP_USER:$TC_TEMP_GROUP 1>$stdout 2>$stderr
    tc_pass_or_fail $? "failed to create new cgroup"
}

function test02()
{
    tc_register "cgclassify"
    # Adding the running shell to cgroup
    cgclassify -g cpu:$TC_TEMP_USER $PPID 1>$stdout 2>$stderr
    tc_pass_or_fail $? "failed to move the task to cgroup $TC_TEMP_USER"
}
function test03()
{
    tc_register "cgexec"
    cgexec -g cpu:$TC_TEMP_USER ls 1>$stdout 2>$stderr
    tc_pass_or_fail $? "failed to run ls in $TC_TEMP_USER cgroup"
}
function test04()
{
    tc_register "cgget"
    cgget -n -g cpu $TC_TEMP_USER  1>$stdout 2>$stderr &&
    cgget -r cpu.shares $TC_TEMP_USER 1>$stdout 2>$stderr
    tc_pass_or_fail $? "print parameters for $TC_TEMP_USER cgroup failed"
}
function test05()
{
    tc_register "cgset"
    cgset -r cpu.shares=1030 $TC_TEMP_USER  1>$stdout 2>$stderr
    tc_pass_or_fail $? "unable to set cpu.shares for cgroup $TC_TEMP_USER"

    tc_register "cgset --copy-from"
    cgcreate -g cpu:test
    cgset --copy-from test TC_TEMP_USER 1>$stdout 2>$stderr
    tc_pass_or_fail $? "check if its REDHAT bug 828170"
}
function test06()
{
    tc_register "cgsnapshot"
    cgsnapshot -f $TCTMP/cgsnapshot.out 1>$stdout 2>$stderr
    RC=$?
    # Expecting warning messages related to black/white list
    grep -v WARNING $stderr > $stderr
    tc_pass_or_fail $RC "failed to generate configuration file"
}
function test07()
{
    tc_register "lscgroup"
    lscgroup 1>$stdout 2>$stderr
    tc_pass_or_fail $? "failed to list all cgroups"
}
function test08()
{
    tc_register "lssubsys"
    lssubsys -m 1>$stdout 2>$stderr
    tc_pass_or_fail $? "failed"
}
function test09()
{
    tc_register "cgdelete"
    cgdelete cpu:$TC_TEMP_USER 1>$stdout 2>$stderr
    tc_pass_or_fail $? "failed to delete $TC_TEMP_USER cgroup"
}
################################################################################
# MAIN
################################################################################
TST_TOTAL=11
tc_setup
run_test
test01
test02
test03
test04
test05
test06
test07
test08
test09
