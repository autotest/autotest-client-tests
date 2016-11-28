#!/bin/bash
###########################################################################################
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

## File : parted.sh                                                    ##
## ##
## Description: This testcase tests parted package                            ##
## ##
## Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/parted
source $LTPBIN/tc_utils.source
PARTED_DIR="${LTPBIN%/shared}/parted"
TESTS_DIR="$PARTED_DIR/tests"
parted_bin_dir="${TESTS_DIR%tests}/parted"
required_cmd="parted partprobe"

tc_get_os_arch || return

function tc_local_setup()
{
    tc_root_or_break || return

    # check installation and environment
    tc_exec_or_break $required_cmd || return

    mkdir $parted_bin_dir
    ln -s `which parted` $parted_bin_dir/
    ln -s `which partprobe` $parted_bin_dir/


    ### Below Substitutions are required to run the test in our env as it is taken from sources ###
    sed -i "/^abs_top_srcdir/ s|/builddir/build/BUILD/parted-2.1|$PARTED_DIR|" $TESTS_DIR/init.sh
    sed -i '/^abs_top_srcdir/ a abs_srcdir="$abs_top_srcdir/tests"' $TESTS_DIR/init.sh

    sed -i "/^# along with this program/ a ENABLE_DEVICE_MAPPER=yes" $TESTS_DIR/t6000-dm.sh

    sed -i '/^skip_test_ "Test.*/ s//#&/' $TESTS_DIR/t9020-alignment.sh

    sed -i '/^: ${srcdir=.}/ a . $srcdir/init.sh' $TESTS_DIR/t9020-alignment.sh

    sed -i "/^skip_test_ 'test disabled'/ s//#&/" $TESTS_DIR/t3000-resize-fs.sh

    sed -i "/^scsi_debug_setup_ dev_size_mb=550/ s//& delay=0/" $TESTS_DIR/t3000-resize-fs.sh

    sed -i 's|$abs_top_srcdir|'$PARTED_DIR'|' $TESTS_DIR/init.cfg
    sed -i 's|$abs_top_srcdir|'$PARTED_DIR'|' $TESTS_DIR/t-lib-helpers.sh
    sed -i 's|$abs_top_srcdir|'$PARTED_DIR'|' $TESTS_DIR/t-local.sh
    sed -i 's|dup-clobber \|\| fail=1|'$PARTED_DIR'/tests/.libs/dup-clobber \|\| fail=1|' $TESTS_DIR/t0500-dup-clobber.sh

    ### mkfs.hfs test will only run if the command found in system ###
    file_mkfs_hfs=`which mkfs.hfs`
    if [ -z $file_mkfs_hfs ]; then
        sed -i '/^for fs_type/ s/hfs+//' $TESTS_DIR/t3000-resize-fs.sh
    fi

}

function tc_local_cleanup()
{

    ### Revert back the substitions done in setup. ###
    sed -i "/^scsi_debug_setup_ dev_size_mb=550 delay=0/ s/delay=0//" $TESTS_DIR/t3000-resize-fs.sh

    sed -i 's/for fs_type in  fat32;/for fs_type in hfs+ fat32;/' $TESTS_DIR/t3000-resize-fs.sh

    sed -i "/^#skip_test_ 'test disabled'/ s/^#//" $TESTS_DIR/t3000-resize-fs.sh

    sed -i '/^\. $srcdir\/init.sh/d' $TESTS_DIR/t9020-alignment.sh

    sed -i '/^#skip_test_ "Test.*/ s/^#//' $TESTS_DIR/t9020-alignment.sh

    sed -i '/^ENABLE_DEVICE_MAPPER=yes/d' $TESTS_DIR/t6000-dm.sh

    sed -i '/^abs_srcdir/d' $TESTS_DIR/init.sh
    sed -i "/^abs_top_srcdir/ s|$PARTED_DIR|/builddir/build/BUILD/parted-2.1|" $TESTS_DIR/init.sh

    rm -rf $parted_bin_dir

    sed -i 's|'$PARTED_DIR'/tests/.libs/dup-clobber \|\| fail=1|dup-clobber \|\| fail=1|' $TESTS_DIR/t0500-dup-clobber.sh
    ### Preventing two testcases from running archs other than x86_64
    [ $TC_OS_ARCH != "x86_64" ] && {
        mv $TESTS_DIR/t0211-gpt-rewrite-header.sh.org $TESTS_DIR/t0211-gpt-rewrite-header.sh
        mv $TESTS_DIR/t0210-gpt-resized-partition-entry-array.sh.org $TESTS_DIR/t0210-gpt-resized-partition-entry-array.sh
        }
}


function run_test()
{
    pushd $TESTS_DIR &>/dev/null
    TESTS=`ls t[0-9]*.sh`
    TST_TOTAL=`echo $TESTS | wc -w`

    for test in $TESTS; do
        tc_register "Test $test"
        ./$test &>$stdout
        rc=$?
        if [ "$rc" -eq 77 ]; then
                cat /dev/null > $stdout
                tc_conf "test skipped"
        else
                tc_pass_or_fail $rc "Test $test failed"
        fi
    done
    popd &>/dev/null
}

#
# main
#
tc_setup
run_test 
