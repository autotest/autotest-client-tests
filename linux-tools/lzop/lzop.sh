#!/bin/sh
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
### File :        lzop.sh                                                      ##
##
### Description: This testcase tests lzop utility                              ##
##
### Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
### Description: This testcase tests lzop utility                              ##
source $LTPBIN/tc_utils.source
LZOP_TESTS_DIR="${LTPBIN%/shared}/lzop"

required="lzop"

function tc_local_setup()
{
    tc_exec_or_break $required
}

function creat_del_tst_files()
{
    [[ -f $TCTMP/*.c || -f $TCTMP/*.lzo ]] && rm -rf $TCTMP/*
    touch $TCTMP/a.c $TCTMP/b.c
    [[ -f $TCTMP/*.h ]] || touch $TCTMP/a.h $TCTMP/b.h
}

function test_single_file_mode()
{
    tc_register "test single_file_mode_create"
    creat_del_tst_files
    lzop $TCTMP/a.c $TCTMP/b.c >$stdout 2>$stderr
    tc_fail_if_bad $? "test single_file_mode_create fail" || return
    rm -rf $TCTMP/*.lzo
    lzop $TCTMP/*.c >$stdout 2>$stderr
    tc_fail_if_bad $? "test single_file_mode_create fail" || return
    rm -rf $TCTMP/*.lzo
    lzop -U $TCTMP/a.c $TCTMP/b.c >$stdout 2>$stderr
    tc_pass_or_fail $? "test single_file_mode_create fail"

    tc_register "test single_file_mode_extract"
    lzop -d $TCTMP/a.c.lzo >$stdout 2>$stderr
    tc_fail_if_bad $? "test single_file_mode_extract fail" || return
    lzop -df $TCTMP/a.c.lzo >$stdout 2>$stderr
    tc_fail_if_bad $? "test single_file_mode_extract fail" || return
    rm -rf $TCTMP/*.c
    lzop -d $TCTMP/*.lzo >$stdout 2>$stderr
    tc_pass_or_fail $? "test single_file_mode_extract fail"

    tc_register "test single_file_mode_list"
    lzop -l $TCTMP/a.c.lzo >$stdout 2>$stderr
    tc_fail_if_bad $? "test single_file_mode_list fail" || return
    lzop -l $TCTMP/*.lzo >$stdout 2>$stderr
    tc_fail_if_bad $? "test single_file_mode_list fail" || return
    lzop -lv $TCTMP/*.lzo >$stdout 2>$stderr
    tc_pass_or_fail $? "test single_file_mode_list fail" || return

    tc_register "test single_file_mode_test"
    lzop -t $TCTMP/a.c.lzo &>$stdout
    tc_fail_if_bad $? "test single_file_mode_test fail" || return
    lzop -tq $TCTMP/*.lzo &>$stdout
    tc_pass_or_fail $? "test single_file_mode_test fail"
}

function test_pipe_mode()
{
    tc_register "test pipe_mode_create"
    creat_del_tst_files
    ( lzop < $TCTMP/a.c > $TCTMP/y.lzo ) >$stdout 2>$stderr
    tc_fail_if_bad $? "test pipe_mode_create fail" || return
    ( cat $TCTMP/a.c | lzop > $TCTMP/y.lzo ) >$stdout 2>$stderr
    tc_fail_if_bad $? "test pipe_mode_create fail" || return
    pushd $TCTMP &>/dev/null
    ( tar -cf - *.c | lzop > y.tar.lzo ) >$stdout 2>$stderr
    tc_pass_or_fail $? "test pipe_mode_create fail"
    popd &>/dev/null

    tc_register "test pipe_mode_extract"
    ( lzop -d < $TCTMP/y.lzo > $TCTMP/a.c ) >$stdout 2>$stderr
    tc_fail_if_bad $? "test pipe_mode_extract fail" || return
    pushd $TCTMP &>/dev/null
    ( lzop -d < y.tar.lzo | tar -xvf - ) >$stdout 2>$stderr
    test -f a.c && test -f b.c
    tc_pass_or_fail $? "test pipe_mode_extract fail"
    popd &>/dev/null

    tc_register "test pipe_mode_list"
    ( lzop -l < $TCTMP/y.lzo ) >$stdout 2>$stderr
    tc_fail_if_bad $? "test pipe_mode_list fail" || return
    cat $TCTMP/y.lzo | lzop -l >$stdout 2>$stderr
    tc_fail_if_bad $? "test pipe_mode_list fail" || return
    ( lzop -d < $TCTMP/y.tar.lzo | tar -tvf - ) >$stdout 2>$stderr
    tc_pass_or_fail $? "test pipe_mode_list fail"

    tc_register "test pipe_mode_test"
    lzop -t < $TCTMP/y.lzo &>$stdout
    tc_fail_if_bad $? "test pipe_mode_test fail" || return
    cat $TCTMP/y.lzo | lzop -t &>$stdout
    tc_pass_or_fail $? "test pipe_mode_test fail"
}

function test_stdout_mode()
{
    tc_register "test stdout_mode_create"
    ( lzop -c $TCTMP/a.c > $TCTMP/y.lzo ) >$stdout 2>$stderr
    tc_pass_or_fail $? "test stdout_mode_create fail"

    tc_register "test stdout_mode_extract"
    ( lzop -dc $TCTMP/y.lzo > $TCTMP/a.c ) >$stdout 2>$stderr
    tc_fail_if_bad $? "test stdout_mode_extract fail" || return
    pushd $TCTMP &>/dev/null
    ( lzop -dc $TCTMP/y.tar.lzo | tar -xvf - ) >$stdout 2>$stderr
    grep -q a.c $stdout && grep -q b.c $stdout
    tc_pass_or_fail $? "test stdout_mode_extract fail"

    tc_register "test stdout_mode_list"
    ( lzop -dc $TCTMP/y.tar.lzo | tar -tvf - ) >$stdout 2>$stderr
    grep -q a.c $stdout && grep -q b.c $stdout
    tc_pass_or_fail $? "test stdout_mode_list fail"
    popd &> /dev/null
}

function test_archive_mode()
{
    tc_register "test archive_mode_create"
    creat_del_tst_files
    lzop $TCTMP/a.c $TCTMP/b.c -o $TCTMP/sources.lzo >$stdout 2>$stderr
    tc_fail_if_bad $? "test archive_mode_create fail" || return
    rm -rf $TCTMP/*.lzo
    lzop -P $TCTMP/*.c -o $TCTMP/sources.lzo
    tc_fail_if_bad $? "test archive_mode_create fail" || return
    ( lzop -c $TCTMP/*.c > $TCTMP/sources.lzo ) >$stdout 2>$stderr
    tc_fail_if_bad $? "test archive_mode_create fail" || return
    ( lzop -c $TCTMP/*.h >> $TCTMP/sources.lzo ) >$stdout 2>$stderr
    tc_pass_or_fail $? "test archive_mode_create fail"

    tc_register "test archive_mode_extract"
    rm -rf $TCTMP/*.c $TCTMP/*.h
    lzop -dN $TCTMP/sources.lzo >$stdout 2>$stderr
    tc_pass_or_fail $? "test archive_mode_extract fail"

    tc_register "test archive_mode_list"
    lzop -lNv $TCTMP/sources.lzo >$stdout 2>$stderr
    tc_pass_or_fail $? "test archive_mode_list  fail"

    tc_register "test archive_mode_test"
    lzop -tN $TCTMP/sources.lzo &>$stdout
    tc_fail_if_bad $? "test archive_mode_test fail" || return
    lzop -tNvv $TCTMP/sources.lzo &>$stdout
    tc_pass_or_fail $? "test archive_mode_test fail"
}

function test_backup_mode()
{
    tc_register "test backup_mode"
    creat_del_tst_files
    pushd $TCTMP &>/dev/null
    tar --use-compress-program=lzop -cf testdir.tar.lzo *.c *.h
    tc_pass_or_fail $? "test backup_mode fail"
    popd &>/dev/null
}


#
# main
#
tc_setup
TST_TOTAL=16
test_single_file_mode
test_pipe_mode
test_stdout_mode
test_archive_mode
test_backup_mode 
