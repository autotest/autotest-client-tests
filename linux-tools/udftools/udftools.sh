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
## File :           mkudffs_tests.sh
##
## Description: This program tests basic functionality of mkudffs command
##
## Author:          Manoj Iyer  manjo@mail.utexas.edu
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# utility function
################################################################################

function tc_local_setup()
{
	tc_register "setting up environment for testing"    
        tc_root_or_break || return
        tc_exec_or_break diff dd mount mkdir grep || return
        lsmod|grep -q udf 
        if [ ! $? = 0 ]
        then
                modprobe udf 1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
		tc_conf "Failed to load module udf which is required to test, skipping test !"
		exit 0
		fi

                remove_udf=1
       
        fi
        lsmod|grep -q pktcdvd
        if [ ! $? = 0 ]
        then
                modprobe pktcdvd 1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
		tc_conf "Failed to load module pktcdvd which is required to test, skipping test !!"
		else
		remove_pktcdvd=1
		fi
	else
        	remove_pktcdvd=0
        fi
}

tc_local_cleanup()
{
        umount $TCTMP/tst_udf_mnt &>/dev/null
        [ $remove_pktcdvd = 1 ] && modprobe -r pktcdvd
        [ $remove_udf = 1 ] && modprobe -r udf
}

################################################################################
# testcase functions
################################################################################

#
# test01        installation check
#
function test01()
{
        tc_register     "installation check"
        tc_executes mkudffs
        tc_pass_or_fail $? "not properly installed"
}

#
# test02        make a udf filesystem
#
function test02()
{
        tc_register    "mkudffs command"

        # create udf file system on loopback device
        dd if=/dev/zero of=$TCTMP/tst_udf bs=1024k count=8 &>$stdout
        local command="mkudffs --media-type=dvd $TCTMP/tst_udf"
        $command >$TCTMP/tst_mkudffs.out 2>$stderr
        tc_fail_if_bad $? "unexpected response from command" "$command" || return
        
        # create expected output.
cat <<-EOF > $TCTMP/tst_mkudffs.exp
start=0, blocks=16, type=RESERVED
start=16, blocks=3, type=VRS
start=19, blocks=237, type=USPACE
start=256, blocks=1, type=ANCHOR
start=257, blocks=16, type=PVDS
start=273, blocks=1, type=LVID
start=274, blocks=3565, type=PSPACE
start=3839, blocks=1, type=ANCHOR
start=3840, blocks=239, type=USPACE
start=4079, blocks=16, type=RVDS
start=4095, blocks=1, type=ANCHOR
EOF

        # if they are different declare fail, else declare pass.
        diff -wB $TCTMP/tst_mkudffs.out $TCTMP/tst_mkudffs.exp >$stdout 2>$stderr
        tc_pass_or_fail $? "miscompare on output from command" "$command"
}

#
# test03        mount the udf filesystem created above
#
function test03()
{
        tc_register     "mount the udf filesystem"

        # create a temporary mount point.
        mkdir -p $TCTMP/tst_udf_mnt 2>$stderr >$stdout
        tc_fail_if_bad $? "failed creating temporary mount point" || return

        # mount the new device as a udf device, this is the ultimate test
        mount -t udf -o loop $TCTMP/tst_udf $TCTMP/tst_udf_mnt >$stdout 2>$stderr
        RC=$?
        tc_ignore_warnings "mounting read-only"
        tc_fail_if_bad $RC "mount command failed" || return
        mount -t udf -o remount,rw $TCTMP/tst_udf $TCTMP/tst_udf_mnt >$stdout 2>$stderr
        tc_fail_if_bad $? "remount command failed" || return

        mount >$stdout 2>$stderr
        grep -q "$TCTMP/tst_udf_mnt" $stdout 2>>$stderr
        tc_pass_or_fail $? "expected to see" \
                "\"$TCTMP/tst_udf_mnt\" in stdout"
}

#
# test04        read/write mounted filesystem
#
function test04()
{
        tc_register     "read/write mounted filesystem"

        echo "hello sailor" > $TCTMP/tst_udf_mnt/hello.txt
        tc_fail_if_bad $? "couldn't write to udf filesystem" || return

        ls $TCTMP/tst_udf_mnt/ >$stdout 2>$stderr &&
        grep -q "hello.txt" $stdout 2>>$stderr
        tc_fail_if_bad $? "file not created on udf filesystem" || return

        grep -q "hello sailor" $TCTMP/tst_udf_mnt/hello.txt 2>$stderr
        tc_pass_or_fail $? "data mis-compare on udf filesystem"
}

#
# test05        udffsck command
#
function test05()
{
        tc_register     "udffsck"

        tc_executes udffsck 
        tc_fail_if_bad  $? "udffsck not installed" || return

        udffsck $TCTMP/tst_udf >$stdout 2>$stderr 
        tc_pass_or_fail $? "unexpected response"
}

#
# test06        cdrwtool command
#
function test06()
{
        tc_register "cdrwtool"
        tc_executes cdrwtool
        tc_fail_if_bad $? "cdrwtool not installed" || return

        tc_info "must be tested manually: $TCNAME"
}

function pktsetup_test01()
{
    tc_register "pktsetup installation check"
    tc_executes pktsetup
    tc_pass_or_fail $? "not installed properly"
}

function pktsetup_test02()
{
    tc_register    "pktsetup functionality"

    pktsetup pktcdvd0 /dev/null &>$stdout
    tc_fail_if_bad $? "failed writing file to media."

    # check if certain messages appear as a result of this command.
    local exp1="drive not ready"
    local exp2="Inappropriate ioctl for device"
    grep -iq "$exp1" $stdout 2>$stderr || grep -q "$exp2" $stdout 2>>$stderr
    tc_pass_or_fail $? "expected  to see" "$exp1" "$exp2" "in stdout"
}

function cdrwtool_test01()
{
    tc_register "check installation"
    tc_executes cdrwtool
    tc_pass_or_fail $? "cdrwtool not installed properly"
}

function cdrwtool_test02()
{
    tc_exists /dev/cdrom || {
        ((--TST_TOTAL))
        return
    }
    tc_register    "cdrwtool functionality"

    # create a dummy file to write
cat <<-EOF > $TCTMP/tst_cdrwtool.in
This is a dummy file to test cdrwtool
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccccccccccccccc
ddddddddddddddddddddddddddddddddddddd
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
EOF

    # use cdrwtool command to write this file
    cdrwtool -d /dev/cdrom -f $TCTMP/tst_cdrwtool.in >$stdout 2>/dev/null

    # next line to be uncommented for real h/w write test.
    # tc_fail_if_bad $? "failed writing file to media." || return

    # check if certain messages appear as a result of this command.
    local exp1="using device /dev/cdrom"
    local exp2="write file $TCTMP/tst_cdrwtool.in"
    grep -q "$exp1" $stdout && grep -q "$exp2" $stdout 2>$stderr
    tc_pass_or_fail $? "expected to see" "$exp1" "$exp2" "in stdout"
}


# 
# main
#
# pktsetup_test01: To be tested on IDE CDRW, or thinkpad. Should be manual ..

tc_setup
TST_TOTAL=5

test01
test02
test03
test04 
test06
if [ "$remove_pktcdvd" == 1 ]; then
	TST_TOTAL=TST_TOTAL+4
	pktsetup_test01 
	pktsetup_test02 
	cdrwtool_test01
	cdrwtool_test02
fi
