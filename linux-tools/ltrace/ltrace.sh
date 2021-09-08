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
## File:		ltracetest.sh
##
## Description:	This program tests basic functionality of ltrace program
##
## Author:	CSDL,  James He <hejianj@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/ltrace
source $LTPBIN/tc_utils.source

################################################################################
# Utility functions 
################################################################################

#
# local setup
#	 
function tc_local_setup()
{	
	tc_exec_or_break ltrace touch || return
	
	# run /bin/ngptinit first for initialing the shared memory.
#	tc_exist_or_break /bin/ngptinit || return 
#	/bin/ngptinit 2>/dev/null 
#	tc_break_if_bad $? "can't initialize the shared memory" || return
	
	# create a temporary directory and populate it with empty files.
	mkdir -p $TCTMP/ltrace.d 2>$stderr 1>$stdout
	tc_break_if_bad $? "can't make directory $TCTMP/ltrace.d" || return
	for file in x y z ; do
		touch $TCTMP/ltrace.d/$file 2>$stderr
		tc_break_if_bad $? "can't create file $TCTMP/ltrace.d/$file" \
			|| return
	done
}

################################################################################
# Testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"installation check"
	tc_executes ltrace
	tc_pass_or_fail $? "ltrace not installed properly"

}

#
# test02	ltrace -h
#
function test02()
{
	tc_register	"ltrace -h command"
	ltrace -h >$stdout 2>$stderr
	tc_pass_or_fail $? "ltrace -h command failed"

}

#
# test03	ltrace --help
#
function test03()
{
	tc_register	"ltrace --help command"
	ltrace --help >$stdout 2>$stderr
	tc_pass_or_fail $? "ltrace --help command failed"

}

#
# test04	ltrace -V
#
function test04()
{
	tc_register	"ltrace -V command"
	ltrace -V >$stdout 2>$stderr
	tc_pass_or_fail $? "ltrace -V command failed"

}

#
# test05	ltrace --version
#
function test05()
{
	tc_register	"ltrace --version command"
	ltrace --version >$stdout 2>$stderr
	tc_pass_or_fail $? "ltrace --version command failed"

}

#
# test06	ltrace -o
#
function test06()
{
	tc_register	"ltrace -o command"
	ltrace -o $TCTMP/ltrace.d/ltrace.out ./ltracetest1 >$stdout 2>$stderr
	tc_fail_if_bad $? "ltrace -o command failed" || return
	tc_exist_or_break $TCTMP/ltrace.d/ltrace.out  || return
	tc_pass_or_fail $? "ltrace -o command failed"
}

#
# test07	ltrace -L -S
#
function test07()
{
	tc_register	"ltrace -L -S command"
	ltrace -L -S ./ltracetest1 &>$stdout
	tc_fail_if_bad $? "ltrace -L -S command failed" || return	
	grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
        if [ $? -eq 0 ];then
                grep -q "SYS_open" $stdout
        else
                grep -q "open@SYS" $stdout
        fi
	tc_pass_or_fail $? "ltrace -L -S command failed"
}

#
# test08	ltrace -e
#
function test08()
{
	tc_register	"ltrace -e command"
	ltrace -e toupper ./ltracetest2 &>$stdout
	tc_fail_if_bad $? "ltrace -e command failed" || return	
	grep -q "toupper" $stdout
	tc_pass_or_fail $? "ltrace -e command failed"
}

#
# test09	ltrace -f
#
function test09()
{
	tc_register	"ltrace -f command"
	tc_info "10 second delay allowing forked PID to create so ltrace -f can attach ..."
	ltrace -f ./ltrace_fork &>$stdout & wait
	tc_fail_if_bad $? "unexpeced results"
	# on PPCNF, no PID would appear in output, so we check for SIGCHLD instead
	grep -q ppcnf /proc/distro_id && {
	    grep -q "SIGCHLD" $stdout
	    tc_pass_or_fail $? "expected to see \"SIGCHLD\" in stdout"
	    return
	}
	# this is not PPCNF, do normal check for "[pid xxxxx]"
	grep -q "^\[pid [[:digit:]]\+" $stdout
	tc_pass_or_fail $? "expected to see \"[pid xxxxx]\" in stdout"
}

################################################################################
# main
################################################################################

TST_TOTAL=9

tc_setup

test01 || exit
test02
test03
test04
test05
test06
test07
test08                                  
test09
