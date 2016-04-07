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
### File :       pkgconfig.sh                                                  ##
##
### Description: This testcase tests pkgconfig package                         ##
##
### Author:      Kingsuk Deb <kingsdeb@linux.vnet.ibm.com>                     ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/pkgconfig/tests"
required="pkg-config"
BIN_DIR="${TESTS_DIR%tests}"

function tc_local_setup()
{
    # check installation and environment
    tc_exec_or_break $required || return

    export PKG_CONFIG_PATH=$TESTS_DIR

    ln -s `which pkg-config` $BIN_DIR

    # set -x is set in one test which is not required. 
    # So commenting it out below. 
    sed -i '/^set -x/ s/^/#/' $TESTS_DIR/check-requires-private
}

function tc_local_cleanup()
{
    rm -f $BIN_DIR/pkg-config
}

function test01()
{
    tc_register "check-exists"
    pkg-config --exists simple = 1.0.0 >$stdout 2>$stderr
    tc_pass_or_fail $? "pkg-config --exists fail"
}

function test02()
{
    tc_register "check-modversion"
    pkg-config --modversion simple >$stdout 2>$stderr
    grep -q "1.0.0" $stdout
    tc_pass_or_fail $? "pkg-config --modversion failed"

    tc_register "check-atleast-version"
    pkg-config --atleast-version=0.99 simple >$stdout 2>$stderr
    tc_pass_or_fail $? "pkg-config --atleast-version failed"

    tc_register "check-exact-version"
    pkg-config --exact-version=1.0 simple >$stdout 2>$stderr
    [ $? -ne 0 ]
    tc_pass_or_fail $? "pkg-config --exact-version fail"

    tc_register "check-max-version"
    pkg-config --max-version=1.0.1 simple >$stdout 2>$stderr
    tc_pass_or_fail $? "pkg-config --max-version fail"
}

function test03()
{
    tc_register "check-errors"
    pkg-config --short-errors --errors-to-stdout --modversion \
        simple1 >$stdout 2>$stderr
    [ $? -ne 0 ]
    tc_fail_if_bad $? "pkg-config --short-errors passed .. should fail" || return
    [[ `cat $stdout` = "No package 'simple1' found" ]]
    tc_pass_or_fail $? "pkg-config --short-errors/--errors-to-stdout fail"
}

function test04()
{
    tc_register "check-print-provides"
    pkg-config --print-provides simple >$stdout 2>$stderr
    grep -q "simple" $stdout
    tc_pass_or_fail $? "pkg-config --print-provides fail"

    tc_register "check-print-requires"
    pkg-config --print-requires requires-test >$stdout 2>$stderr
    [[ `grep  public.dep $stdout` ]]
    tc_pass_or_fail $? "pkg-config --print-requires fail"

    tc_register "check-print-requires-private"
    pkg-config --print-requires-private requires-test >$stdout 2>$stderr
    [[ `grep  private.dep $stdout` ]]
    tc_pass_or_fail $? "pkg-config --print-requires-private fail"

    unset PKG_CONFIG_PATH
}

function test05()
{
    tc_register "check-list-all"
    def_pc_files=`find /usr/lib*/pkgconfig /usr/share/pkgconfig -name *.pc | wc -l`
    pkg-config --list-all | wc -l >$stdout 2>$stderr
    [[ `cat $stdout` -eq $def_pc_files ]]
    tc_pass_or_fail $? "pkg-config --list-all fail"
}

function test06()
{
    pushd $TESTS_DIR &>/dev/null
    TESTS=`ls check-*`
    TST_TOTAL=`expr $TST_TOTAL + $(echo $TESTS | wc -w)`
    for test in $TESTS; do
        tc_register "$test"
        srcdir=. ./$test >$stdout 2>$stderr
        tc_pass_or_fail $? "$test fail"
    done
    popd &>/dev/null
}


#
# main
#
TST_TOTAL=9
tc_setup && \
test01
test02
test03
test04
test05
test06 
