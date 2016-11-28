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
## File :        m4test.sh
##
## Description:  Test m4 package
##
## Author:      CSDL  hejianj@cn.ibm.com
###########################################################################################

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/m4
cd ${LTPBIN%/shared}/m4

# source the utility functions
source $LTPBIN/tc_utils.source

################################################################################
# environment functions
################################################################################

#
# local setup
#
function tc_local_setup()
{
	tc_exec_or_break cmp test || return
	test -z "$MAKE" && MAKE=make
	test -z "$M4" && M4=/usr/bin/m4
	test -z "$CMP" && CMP=cmp
#	test -z "$VERBOSE" && {exec > /dev/null 2>&1}

# Setting nls related vars. Override them in the test when needed.
	export srcdir=m4test
	export M4
	export CMP
	LANGUAGE=C
	export LANGUAGE
	LC_ALL=C
	export LC_ALL
	LANG=C
	export LANG

}

################################################################################
# testcase functions
################################################################################

# run the m4testcases
function run_m4test() 
{
# run each testcase
for tst in $TESTS ; do
	tst=${tst##*m4test/}
	tc_register "$tst"

	sed -e '/^dnl @result{}/!d' -e 's///' $TESTDIR/$tst >$TCTMP/out
	sed -e '/^dnl @error{}/!d' -e 's///' $TESTDIR/$tst >$TCTMP/err

	m4 -d $TESTDIR/$tst >$TCTMP/xout 2>$TCTMP/temperr
	sed -e "s/$TESTDIR\/$tst/$tst/" $TCTMP/temperr >$TCTMP/xerr

	cmp $TCTMP/out $TCTMP/xout && cmp $TCTMP/err $TCTMP/xerr
	tc_pass_or_fail $? "output unexpected." || {
		[ -s $TCTMP/out ] && tc_info \
			"===================== expected stdout ===================" \
			"$(cat $TCTMP/out)" \
			"====================== actual stdout ====================" \
			"$(cat $TCTMP/xout)" \
			"========================================================="
		[ -s $TCTMP/err ] && tc_info \
			"===================== expected stderr ===================" \
			"$(cat $TCTMP/err)" \
			"====================== actual stderr ====================" \
			"$(cat $TCTMP/xerr)" \
			"========================================================="
	}
done
}

################################################################################
# MAIN
################################################################################

TESTDIR="m4test" # testdir we store individual test files in
TESTS=`find ./$TESTDIR -follow -name "*.*"`

set $TESTS
TST_TOTAL=$#

tc_setup
run_m4test
