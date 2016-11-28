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
# File :	freetype.sh
#
# Description:	Test the freetype package
#
# Author:	Hong Bo Peng <penghb@cn.ibm.com> 
################################################################################
# source the standard utility functions
################################################################################

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/freetype
source $LTPBIN/tc_utils.source
DATADIR=${LTPBIN%/shared}/freetype/freetype-test
FTDEMOBIN=/usr/bin

################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"is freetype installed"
	libfile=/usr/lib/libfreetype.so.6
	tc_get_os_arch
	[ $TC_OS_ARCH = "x86_64" ] || [ $TC_OS_ARCH = "ppc64" ] || [ $TC_OS_ARCH = "s390x" ] \
	|| [ $TC_OS_ARCH = "ppc64le" ] && libfile=/usr/lib64/libfreetype.so.6
	tc_exist_or_break $libfile 
	tc_pass_or_fail $? "freetype is not installed properly"
	
	tc_exec_or_break diff || return
}

#
# test02	ftview
#
function test02()
{
	tc_register	"ftview"

	$DATADIR/fontview $DATADIR/fonts/c0649bt_.pfb 12 1>$TCTMP/output
	tc_fail_if_bad $? "fontview failed to verify c0649bt_.pfb" || return

	$DATADIR/fontview $DATADIR/fonts/cour.pfa 12 1>>$TCTMP/output
	tc_fail_if_bad $? "fontview failed to verify cour.pfa" || return

	$DATADIR/fontview $DATADIR/fonts/gbsn00lp.ttf 12 1>>$TCTMP/output
	tc_fail_if_bad $? "fontview failed to verify gbsn00lp.ttf" || return

	diff -qiwB $TCTMP/output $DATADIR/fontview.output 2>$stderr 1>$stdout 
	tc_pass_or_fail $? "ftview failed"
}

#
# test03	ftdump
#
function test03()
{
	tc_register	"ftdump"

	$FTDEMOBIN/ftdump -n $DATADIR/fonts/c0649bt_.pfb 1>$TCTMP/output
	tc_fail_if_bad $? "ftdump failed to verify c0649bt_.pfb" || return

	$FTDEMOBIN/ftdump -n $DATADIR/fonts/cour.pfa 1>>$TCTMP/output
	tc_fail_if_bad $? "ftdump failed to verify cour.pfa" || return

	$FTDEMOBIN/ftdump -n $DATADIR/fonts/gbsn00lp.ttf 1>>$TCTMP/output
	tc_fail_if_bad $? "ftdump failed to verify gbsn00lp.ttf" || return

	# diff -qiwB $TCTMP/output $DATADIR/ftdump.output 2>$stderr 1>$stdout 
	diff -qiwB $TCTMP/output $DATADIR/ftdump.output
	tc_pass_or_fail $? "ftview failed"
}

#
# test04	ftlint
#
function test04()
{
	tc_register	"ftlint"

	$FTDEMOBIN/ftlint 12 $DATADIR/fonts/c0649bt_.pfb 2>$stderr 1>$stdout
	tc_fail_if_bad $? "ftlint failed to verify c0649bt_.pfb" || return

	$FTDEMOBIN/ftlint 16 $DATADIR/fonts/cour.pfa 2>$stderr 1>$stdout
	tc_fail_if_bad $? "ftlint failed to verify cour.pfa" || return

	$FTDEMOBIN/ftlint 48 $DATADIR/fonts/gbsn00lp.ttf 2>$stderr 1>$stdout
	tc_pass_or_fail $? "ftlint failed to verify gbsn00lp.ttf" || return
}

################################################################################
# main
################################################################################

TST_TOTAL=4

(
	# standard tc_setup
	tc_setup

	test01  || exit
	test02
	test03
	test04
)

