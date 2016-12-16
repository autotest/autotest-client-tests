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
## File :	patch.sh
##
## Description:	Test the patch package
##
## Author:	Hong Bo Peng <penghb@cn.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/patch
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/patch

################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"is patch installed"
	tc_executes patch
	tc_pass_or_fail $? "patch is not installed properly"
}

#
# test02	"patch
#
function test02()
{
	tc_register	"patch"
	tc_exec_or_break cmp diff || return

	# create some files and diff file
	mkdir dir02 dir02.new
	echo -e "a\nb\nc" > dir02/a
	echo -e "b\nc\nd" > dir02/b
	echo -e "a\nB\nc" > dir02.new/a
	echo -e "b\nC\nd" > dir02.new/b
	diff -rc dir02 dir02.new > cdiff

	#patch files and check result
	patch -p0 < cdiff 2>$stderr 1>$stdout
	tc_fail_if_bad $? "patch failed"

	cmp dir02/a dir02.new/a >$stdout 2>$stderr
	tc_fail_if_bad $? "patch didn't create correct result"

	cmp dir02/b dir02.new/b >$stdout 2>$stderr
	tc_pass_or_fail $? "patch didn't create correct result"
}

#
# test03	"patch -p1 -i
#
function test03()
{
	tc_register	"patch -p1 -i"
	tc_exec_or_break cmp diff || return

	mkdir dir03 dir03.new
	echo -e "a\nb\nc" > dir03/a
	echo -e "b\nc\nd" > dir03/b
	echo -e "a\nB\nc" > dir03.new/a
	echo -e "b\nC\nd" > dir03.new/b
	diff -rc dir03 dir03.new > cdiff

	cd dir03
	patch -p1 -i ../cdiff 2>$stderr 1>$stdout
	tc_fail_if_bad $? "patch -p1 -i failed"

	cd ..
	cmp dir03/a dir03.new/a >$stdout 2>$stderr
	tc_fail_if_bad $? "patch didn't create correct result"

	cmp dir03/b dir03.new/b >$stdout 2>$stderr
	tc_pass_or_fail $? "patch -p1 -i didn't create correct result"
}

#
# test04	"patch -R
#
function test04()
{
	tc_register	"patch -R"
	tc_exec_or_break cmp diff || return

	mkdir dir04 dir04.new
	echo -e "a\nb\nc" > dir04/a
	echo -e "b\nc\nd" > dir04/b
	echo -e "a\nB\nc" > dir04.new/a
	echo -e "b\nC\nd" > dir04.new/b
	diff -rc dir04 dir04.new > cdiff

	cd dir04.new
	patch -R -p1 -i ../cdiff  2>$stderr 1>$stdout
	tc_fail_if_bad $? "patch -R failed"

	cd ..
	cmp dir04/a dir04.new/a >$stdout 2>$stderr
	tc_fail_if_bad $? "patch didn't create correct result"

	cmp dir04/b dir04.new/b >$stdout 2>$stderr
	tc_pass_or_fail $? "patch -R didn't create correct result"
}

#
# test05	"patch -l
#
function test05()
{
	tc_register	"patch -l"
	tc_exec_or_break cmp diff || return

	mkdir dir05
	echo -e "a\nb\nc" > dir05/a
	echo -e "a\nB\nc" > dir05/a.new
	diff -rc dir05/a dir05/a.new > cdiff

	#now add a space to the original file
	echo -e "a\nb\nc " > dir05/a

	patch -l -p0 < cdiff 2>$stderr 1>$stdout
	tc_fail_if_bad $? "patch -l failed"

	diff -b dir05/a dir05/a.new >$stdout 2>$stderr
	tc_pass_or_fail $? "patch -l didn't create correct result"
}

################################################################################
# main
################################################################################

TST_TOTAL=5

(
	# standard tc_setup
	tc_setup
	cd $TCTMP

	test01 || exit
	test02
	test03
	test04
	test05
)
