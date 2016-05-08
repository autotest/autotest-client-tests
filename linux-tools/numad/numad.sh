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
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

## Author:  Sohny Thomas <sohthoma@in.ibm.com>
###########################################################################################
## source the utility functions


TST_TOTAL=5
REQUIRED="numad numactl memhog"
NODES=""
testPID=""
INTERVAL="5:10"

function tc_local_setup()
{
    tc_root_or_break || return
    tc_exec_or_break  $REQUIRED || exit 
    numactl --show >$stdout 2>$stderr
    cat $stdout | grep -q "No NUMA support"
    if [ $? -eq 0 ]; then
        tc_fail "No NUMA support available on this system" && exit
    fi 
    NODE_CPU1=`numactl --show | grep ^cpubind | cut -d" " -f 2`
    NODE_MEM1=`numactl --show | grep ^membind | cut -d" " -f 2`
    numad -l 6
    #NUMA deamon uses the scan time as defined at 
    #/sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
    #which by default has a high value. This by default causes numad to produce 
    #a warning or error when it starts for first time. So take backup and write a lesser value.
    tc_get_os_arch
    if [ "$TC_OS_ARCH" = "x86_64" ]; then
       TPAGES_SEC=`cat /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs`
       echo 100 > /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
    fi
    NODES=`numactl -H | grep available | cut -d" "  -f2`
    if [ $NODES -gt 1 ]; then
    NODE_CPU2=`numactl --show | grep ^cpubind | cut -d" " -f 3`
    NODE_MEM2=`numactl --show | grep ^membind | cut -d" " -f 3`
    fi
    if [ $NODE_CPU1 ]; then
    NODE0_MEM_SIZE=`numactl -H | grep "node $NODE_CPU1 size" | cut -d" " -f4`
    REQ_MEM_SIZE=`expr $NODE0_MEM_SIZE / 2 - 10`
    bind="--cpunodebind"
    node=$NODE_CPU1
    else
    NODE0_MEM_SIZE=`numactl -H | grep "node $NODE_MEM1 size" | cut -d" " -f4`
    REQ_MEM_SIZE=`expr $NODE0_MEM_SIZE / 2`
    bind="--membind"
    node=$NODE_MEM1
    fi
    TMPDIR=$TCTMP/test_cgroup_dir
    mkdir $TMPDIR
    mount cgroup -t cgroup -o cpuset $TMPDIR
    numad -i 0 2>$stderr
    mv /var/log/numad.log /var/log/numad.log_bkp
}

function tc_local_cleanup()
{	
    umount $TMPDIR
    if [ -f /var/log/numad.log_bkp ] ; then
        numad -i 0:0
        rm -f /var/log/numad.log
        mv /var/log/numad.log_bkp /var/log/numad.log
        if [ "$TC_OS_ARCH" = "x86_64" ]; then
           echo $TPAGES_SEC > /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
        fi
    fi
    pkill yes > /dev/null
}

function tc_run_test()
{
    tc_register "Start Numad deamon"
    numad -d -D $TMPDIR 1>$stdout 2>$stderr
    cat /var/log/numad.log | grep -q "Registering numad version"   
    tc_pass_or_fail $? "Numad deamon not started" || return
	
    tc_register "Change deamon Scan interval"
    numad -i $INTERVAL 
    cat /var/log/numad.log | grep  -q "Changing interval to $INTERVAL"
    tc_pass_or_fail $? "Scan interval could not be changed"

    tc_register "Add a process to scan list"
    yes>/dev/null &
    testPID=$!
    numad -p $testPID
    cat /var/log/numad.log | grep  -q "Adding PID $testPID to inclusion PID list"
    tc_pass_or_fail $? "Process not added to scan list"

    tc_register "Scanning Explicit process list"
    numad -S 0
    tc_fail_if_bad $? "numad -S 0 failed"
    cat /var/log/numad.log | grep  -q "Scanning only explicit PID list processes"
    numactl $bind=$node memhog -r10 $NODE0_MEM_SIZE\m 1>/dev/null &
    tmpPID=$!
    numactl $bind=$node memhog -r10 $REQ_MEM_SIZE\m 1>/dev/null &
    testPID=$! 
    wait $testPID
    ! cat /var/log/numad.log | grep  -q "Advising pid $testPID (memhog) move" 
    tc_pass_or_fail $? "numad still scan all the processes"    
     wait $tmpPID

    tc_register "Removing a process to scan list"
    numad -r $testPID
    tc_fail_if_bad $? "numad -r $testPID failed"
    sleep 5
    cat /var/log/numad.log | grep  -q "Removing PID $testPID from explicit PID list"
    tc_pass_or_fail $? "Process could not be removed from scan list"

    if [ $NODES -gt 1 -a $NODE_MEM2 -a $NODE_MEM1 ]; then	
	TST_TOTAL=$TST_TOTAL+2
	tc_register "Check numad process & resource managing "
	#set to scan all process
	numad -S 1
        tc_fail_if_bad $? "numad -S 1 failed"
	#Changing target utilization 50%
	numad -u 50
        tc_fail_if_bad $? "numad -u 50 failed"
	NODE1_MEM_SIZE=`numactl -H | grep "node $NODE_CPU2 free" | cut -d" " -f4`
	NODE0_HALF_MEM_SIZE=`expr $NODE0_MEM_SIZE / 2`
	if [ $NODE0_HALF_MEM_SIZE -ge $NODE1_MEM_SIZE ]; then
	NODE_DIFF=`expr $NODE0_MEM_SIZE - $NODE1_MEM_SIZE`
	REQ_MEM_SIZE=`expr $NODE0_MEM_SIZE / 2 - $NODE_DIFF`
	fi
	#loading a node with more than 50% of resource utilization
	numactl --cpunodebind=0 memhog -r50 $REQ_MEM_SIZE\m 1>/dev/null &
	testPID=$!
	wait $testPID
	cat /var/log/numad.log | grep  -q "Advising pid $testPID (memhog) move"
	tc_pass_or_fail $? "Process is not moved between nodes"
	
	tc_register "Check numad process node affinty suggestion"
	#loading a node with more than 50% of resource utilization"
	numactl --cpunodebind=0 memhog -r10 $NODE0_MEM_SIZE\m 1>/dev/null &
	numad -w 2:$REQ_MEM_SIZE | grep  -q "[0-9]" 
	tc_pass_or_fail $? "numad did not properly specify the node to run the process"
    fi

}

tc_setup
tc_run_test
