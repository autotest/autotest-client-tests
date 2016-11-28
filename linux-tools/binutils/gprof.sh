#!/bin/sh
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                         ##
##                                                                                       ##
## Redistribution and use in source and binary forms, with or without modification,      ##
## are permitted provided that the following conditions are met:                         ##
##1.Redistributions of source code must retain the above copyright notice,               ##
##        this list of conditions and the following disclaimer.                          ##
##2.Redistributions in binary form must reproduce the above copyright notice, this       ##
##        list of conditions and the following disclaimer in the documentation and/or    ##
##        other materials provided with the distribution.                                ##
##                                                                                       ##
## THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS    ##
## OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF       ##
## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL##
## THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,   ##
## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF    ##
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)##
## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, ##
## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS ##
## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                          ##
###########################################################################################
#
# File :        gprof.sh
#
# Description:  Test gprof command
#
# Author:      Xu Zheng zhengxu@cn.ibm.com
#
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/binutils
source $LTPBIN/tc_utils.source
gmon_DIR=${LTPBIN%/shared}/binutils/testcases

################################################################################
# testcase functions
################################################################################
function tc_local_setup()
{
	tc_root_or_break || return
	cd $TCTMP
	$gmon_DIR/test 
	[ -f $TCTMP/gmon.out ]
	tc_fail_if_bad $? "Can not generate profile file " || return
}

function tc_output()
{
	local options=" b i J L p P q Q y Z T w60 -function-ordering x"
#	-C 
#	Option -C will cause basic-block execution counts to be tallied and displayed. 
#	Becasue gcc's -a option has removed, the profile data file does not contains 
#	basic-block count records. So jump over this option.
	
	for tst in $options; do
		tc_register "test gprof output options -$tst"
		gprof -$tst $gmon_DIR/test >$TCTMP/output 2>$stderr
		tc_fail_if_bad $? "Option -$tst is bad." || continue
		sleep 1s
		[ -s $TCTMP/output ]
		tc_pass_or_fail $? "The output file from option -$tst is bad."
	done

		tc_register "test gprof output options -I"
		gprof -I $gmon_DIR $gmon_DIR/test >$TCTMP/output 2>$stderr
		tc_fail_if_bad $? "Options -I is bad." || return
		sleep 1s
		[ -s $TCTMP/output ]
		tc_pass_or_fail $? "The output file from option -I is bad."
}

function tc_analysis()
{
	local options=" a c D l z n1 N1 m1"
	tc_get_os_arch
	for tst in $options; do
                # The -c option is not supported on powerpc architectures and s390x.
		[ "$TC_OS_ARCH" = "ppc" ] || \
		[ "$TC_OS_ARCH" = "ppc64" ] || \
                [ "$TC_OS_ARCH" = "ppc64le" ] || \
		[ "$TC_OS_ARCH" = "ppcnf" ] || \
		[ "$TC_OS_ARCH" = "s390x" ]&&  \
		[ "$tst" = "c" ]&&  continue

		tc_register "test gprof analysis options -$tst"
		gprof -$tst $gmon_DIR/test >$TCTMP/output 2>$stderr
		tc_fail_if_bad $? "Option -$tst is bad." || continue 
		sleep 1s
		[ -s $TCTMP/output ]
		tc_pass_or_fail $? "The output file from option -$tst is bad."
	done

		tc_register "test gprof analysis options -k"
		gprof -k $gmon_DIR $gmon_DIR/test >$TCTMP/output 2>$stderr
		tc_fail_if_bad $? "Option -k is bad." || return
		sleep 1s
		[ -s $TCTMP/output ]
		tc_pass_or_fail $? "The output file from option -k is bad."
}

function tc_miscellaneous()
{
	local options=" d Oauto v"
	for tst in $options; do
		tc_register "test gprof miscellaneous options -$tst"
		gprof -$tst $gmon_DIR/test >$TCTMP/output 2>$stderr
		tc_fail_if_bad $? "Option -$tst is bad." || continue 
		sleep 1s
		[ -s $TCTMP/output ]
		tc_pass_or_fail $? "The output file from option -$tst is bad."
	done
		tc_register "test gprof miscellaneous options -s"
		gprof -s $gmon_DIR/test 2>$stderr
		tc_fail_if_bad $? "Option -$tst is bad." || return
		sleep 1s
		[ -s $TCTMP/gmon.sum ]
		tc_pass_or_fail $? "The output file from option -s is bad."
}
####################################################################################
# MAIN
####################################################################################

# Function:     main
#
# Description:  - Execute all tests, report results
#
# Exit:         - zero on success
#               - non-zero on failure
#
tc_setup
tc_output
tc_analysis
tc_miscellaneous

