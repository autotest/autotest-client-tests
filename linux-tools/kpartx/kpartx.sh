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
##                                                                            ##
## File :       kpartx.sh                                                     ##
##                                                                            ##
## Description: Test kpartx.                                                  ##
##                                                                            ##
## Author:      Kingsuk Deb <kingsdeb@linux.vnet.ibm.com>                     ##
##                                                                            ##                 
################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
kpartx_img=$TCTMP/kpartx_test.img
partition_table_types="msdos gpt"

tc_local_setup()
{
    tc_exec_or_break kpartx || return
    tc_executes losetup dd parted || {
        tc_info "You require losetup, dd, parted for running kpartx tests"
        return
    }
    dd if=/dev/zero of=$kpartx_img bs=1K count=10K >$stdout 2>$stderr || return
    loopdev=`losetup -f | cut -d '/' -f3`
    loopdev_no=${loopdev: -1}
}

function tc_local_cleanup()
{
    rm -f $kpartx_img
}

function create_partition()
{
    parted -s $kpartx_img mklabel $1 || return
    parted -s $kpartx_img mkpart p ext3 20kB 10MB &>$stdout || return
}

function run_kpartx_tests()
{
    tc_register "Test kpartx"
    kpartx $kpartx_img >$stdout 2>$stderr
    grep -q ${loopdev}p1 $stdout && \
    grep "loop deleted" $stdout | grep -q /dev/$loopdev
    tc_pass_or_fail $? "kpartx fail" || return

    tc_register "Test kpartx -p"
    kpartx -p -dummy $kpartx_img >$stdout 2>$stderr
    grep -q ${loopdev}-dummy1 $stdout && \
    grep "loop deleted" $stdout | grep -q /dev/$loopdev
    tc_pass_or_fail $? "kpartx -p fail"

    tc_register "Test kpartx -a"
    test -z "`dmsetup ls | grep "loop$loopdev_no"`"
    kpartx -a $kpartx_img >$stdout 2>$stderr
    tc_fail_if_bad $? "kpartx -a fail"
    test -n "`dmsetup ls | grep "loop$loopdev_no"`"
    tc_pass_or_fail $? "kpartx -a failed to create dev mappings"

    tc_register "Test kpartx -l"
    kpartx -l $kpartx_img >$stdout 2>$stderr
    grep ${loopdev}p1 $stdout | grep -q /dev/$loopdev
    tc_pass_or_fail $? "kpartx -l fail"

    tc_register "Test kpartx -d"
    kpartx -d $kpartx_img >$stdout 2>$stderr
    grep "loop deleted" $stdout | grep -q  /dev/$loopdev
    tc_fail_if_bad $? "kpartx -d fail1" || return
    loopdev_free=`losetup -f | cut -d '/' -f3`
    test $loopdev == $loopdev_free
    tc_pass_or_fail $? "kpartx -d fail"
}


tc_setup
TST_TOTAL=5
i=1

for type in $partition_table_types 
do
    TST_TOTAL=$((TST_TOTAL * i))
    echo "Creating $type partition and run tests..."
    create_partition $type
    run_kpartx_tests 
    (( ++i ))
done
