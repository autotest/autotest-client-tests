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
## File :	attr.sh
##
## Description:	Test the functions provided by star.
##
## Author:	Liu Deyan, liudeyan@cn.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

TESTDIR=${LTPBIN%/shared}/attr/attr-tests

TEST1=${LTPBIN%/shared}/attr/attr-tests/attr.test

################################################################################
# the testcase function
################################################################################

TST_TOTAL=1

function tc_local_setup()
{
	tc_exec_or_break grep perl || return
	tc_check_package "perl"
	tc_break_if_bad $? "Need full perl installation, not just perl-base" || return

	local msg1="'/' filesystem support "
	local msg2="remount '/' with 'acl' and 'user_xattr' supported"
	local remountflag=0

        tc_info "Check if '/' filesystem support 'acl' and 'user_xattr'"
        while read dev filesystem systype support
        do
                if [ "$filesystem" == "/" ]
                then
                        if echo "$support" | grep "acl" &&
                        echo "$support" | grep "user_xattr"
                        then
                                tc_info "$msg1 'acl' and 'user_xattr'"
                        else
                                tc_info "$msg2"
                                support="remount,defaults,errors=remount-ro,acl,user_xattr"
                                mount -o $support $dev /
                                tc_break_if_bad $? "remount failed"
                        fi

                fi
        done </etc/fstab
}

function test01()
{
	tc_register "attr test "
	cd $TESTDIR
	./run $TEST1 >$stdout 2>$stderr
	cmd=$1

	set `cat $stdout | grep "passed, 0 failed)" | wc -l`
	[ $1 -eq 1 ]
	tc_pass_or_fail $? "attr test"

}

################################################################################
# main
################################################################################

tc_setup
#tc_run_me_only_once

test01 
