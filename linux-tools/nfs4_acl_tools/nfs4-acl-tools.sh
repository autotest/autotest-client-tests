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
## File:         nfs4-acl-tools.sh
##
## Description:  This program tests basic functionality of nfs4-acl-tools
##
## Author:       Athira Rajeev <atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/nfs4_acl_tools"

REQUIRED="nfs4_editfacl nfs4_getfacl nfs4_setfacl dd losetup hostname"

TESTDIR=${LTPBIN%/shared}/nfs4_acl_tools/test

TESTS=(
apply-mask.test
basic.test
inheritance_test
chmod.test
chown.test
create.test
delete.test
)

################################################################################
# Utility functions
################################################################################

#
# local setup
#        
function tc_local_setup()
{       
	tc_root_or_break || return
	tc_exec_or_break $REQUIRED || return

	nfs_cleanup=0
    # To get the domain name
	domain_name=`hostname -f`
    domain_name=`echo $domain_name |awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//' ` 

	cp -rp /etc/exports $TCTMP/

    /etc/init.d/nfs status &> /dev/null
    [ $? -eq 0 ] && \
        nfs_cleanup=1

    tc_register "Prepare and export the nfs partition"
    # Create regular file ext3.img
    dd if=/dev/zero of=ext3.img bs=1 count=10MB 1>$stdout 2>$stderr
    tc_break_if_bad_rc $? "dd command failed" || return

    img=`losetup -sf ext3.img` 1>$stdout 2>$stderr
    tc_break_if_bad_rc $? "losetup failed" || return

    # Put ext3 filesystem 
    mkfs -t ext3 $img 1>$stdout 2>$stderr
    tc_break_if_bad_rc $? "mkfs.ext3 failed" || return

    ip=`hostname -i`
    set $ip
    ip=$1
    # Update /etc/exports with nfs directory
    echo "/mnt/NFS_PARTITION $ip(rw,async,acl,no_root_squash)" >> /etc/exports
    
    mkdir -p /mnt/NFS_PARTITION
    # mount the partition to be exported with acl
    mount -o loop -o acl $img /mnt/NFS_PARTITION/ 1>$stdout 2>$stderr
    tc_break_if_bad_rc $? "Failed to mount nfs directory" || return

    # Restart the nfs server
    /etc/init.d/nfs restart
    tc_fail_if_bad $? "failed to restart the nfs server" || return

    mkdir -p /NFS_PARTITION/
    # mount the exported NFS directory
    mount -t nfs4 -o acl $ip:/mnt/NFS_PARTITION /NFS_PARTITION/
    tc_pass_or_fail $? "Failed to mount the exported NFS directory" || return
}

#
# local cleanup
#
function tc_local_cleanup()
{
	# unmount the NFS directory
	# Restore the etc/exports
	mv $TCTMP/exports /etc/exports
	umount /NFS_PARTITION
	/etc/init.d/nfs restart
	umount /mnt/NFS_PARTITION
	rm -rf /NFS_PARTITION
	rm -rf $TEST_DIR/ext3.img

    losetup -d $img 1>$stdout 2>$stderr
    tc_break_if_bad $? "Failed to delete $img"

	if [ $nfs_cleanup -eq 0 ]; then
	/etc/init.d/nfs stop >$stdout 2>$stderr
	tc_break_if_bad $? "failed to stop nfs"
	fi
}

################################################################################
# Testcase functions
################################################################################

function runtest()
{
    pushd $TESTDIR/ &>/dev/null
    TST_TOTAL=${#TESTS[*]}
    local t
    for t in ${TESTS[@]} ; do
        echo $t

        local test_name=$t
   
        sed -i "s:domain:$domain_name:g" $test_name
        tc_register $test_name
        ./run $test_name >$stdout 2>$stderr
        tc_pass_or_fail $? "$test_name failed"
    done
    popd &>/dev/null
}

################################################################################
# main
################################################################################

tc_setup
runtest
