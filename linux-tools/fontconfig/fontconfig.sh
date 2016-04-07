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
#
# File :	fontconfig.sh
#
# Description:	Test the fontconfig package
#
# Author:	Hong Bo Peng <penghb@cn.ibm.com>
################################################################################
# source the standard utility functions
################################################################################

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TESTDIR=${LTPBIN%/shared}/fontconfig/fontconfig-test

FONT1=$TESTDIR/4x6.pcf
FONT2=$TESTDIR/8x16.pcf

#
# tc_local_setup
#
function tc_local_setup()
{
	FONTDIR=$TCTMP/fonts
	CACHEDIR=$TCTMP/cache.dir

	sed 	"s!@FONTDIR@!$FONTDIR!
		s!@CACHEDIR@!$CACHEDIR!" < $TESTDIR/fonts.conf.in > $TCTMP/fonts.conf
	FONTCONFIG_FILE=$TCTMP/fonts.conf

	export FONTCONFIG_FILE 
}


################################################################################
# the testcase functions
################################################################################

#
# check()	common functions to check output
#
function check()
{
	fc-list - family pixelsize | sort > $TCTMP/out 
	echo "=" >> $TCTMP/out
	fc-list - family pixelsize | sort >> $TCTMP/out
	echo "=" >> $TCTMP/out
	fc-list - family pixelsize | sort >> $TCTMP/out
	tr -d '\015' <$TCTMP/out >$TCTMP/out.tmp; mv $TCTMP/out.tmp $TCTMP/out
	if diff $TCTMP/out $TESTDIR/out.expected 2>$stderr 1>$stdout ; then : ; else
		tc_info "*** Test failed: $TEST"
		tc_info "*** output is in 'out', expected output in 'out.expected'"
		return 1
	fi
	rm $TCTMP/out
	return 0
}

#
# prep()	common functions to prepare for testing
#
function prep()
{
	rm -rf $CACHEFILE
	rm -rf $FONTDIR
	mkdir $FONTDIR
}

#
# test01	installation check
#
function test01()
{
	tc_register	"is fontconfig installed"
	tc_executes fc-list fc-cache fc-match
	tc_pass_or_fail $? "fontconfig is not installed properly"

	tc_exec_or_break diff || return
}

#
# test02	"Basic check
#
function test02()
{
	tc_register	"Basic check"

	prep
	cp $FONT1 $FONT2 $FONTDIR
	check
	tc_pass_or_fail $? "unexpected output from Basic check"
}

#
# test03	"With a cache file
#
function test03()
{
	tc_register	"With a cache file"

	prep
	cp $FONT1 $FONT2 $FONTDIR
	fc-cache $FONTDIR
	check
	tc_pass_or_fail $? "unexpected output"
}

#
# test04	"Subdir with a cache file
#
function test04()
{
	tc_register	"Subdir with a cache file"

	prep
	mkdir $FONTDIR/a
	cp $FONT1 $FONT2 $FONTDIR/a
	fc-cache $FONTDIR/a
	check
	tc_pass_or_fail $? "unexpected output"
}

#
# test05	"Complicated directory structure
#
function test05()
{
	tc_register	"Complicated directory structure"

	prep
	mkdir $FONTDIR/a
	mkdir $FONTDIR/a/a
	mkdir $FONTDIR/b
	mkdir $FONTDIR/b/a
	cp $FONT1 $FONTDIR/a
	cp $FONT2 $FONTDIR/b/a
	check

	tc_pass_or_fail $? "unexpected output"
}

#
# test06	"Subdir with an out-of-date cache file
#
function test06()
{
	tc_register	"Subdir with an out-of-date cache file"

	prep
	mkdir $FONTDIR/a
	fc-cache $FONTDIR/a
	sleep 1
	cp $FONT1 $FONT2 $FONTDIR/a
	check

	tc_pass_or_fail $? "unexpected output"
}

#
# test07	"Dir with an out-of-date cache file
#
function test07()
{
	tc_register	"Dir with an out-of-date cache file"

	prep
	cp $FONT1 $FONTDIR
	fc-cache $FONTDIR
	sleep 1
	mkdir $FONTDIR/a
	cp $FONT2 $FONTDIR/a
	check

	tc_pass_or_fail $? "unexpected output"
}

#
# test08	"fc-match check
#
function test08()
{
	tc_register	"fc-match check"

	prep
	cp $FONT1 $FONT2 $FONTDIR
	fc-match "Fixed:pixelsize=6" 2> /dev/null 1>$TCTMP/match.out
	tc_fail_if_bad $? "unexpected output from Basic check"

	diff -qiwB $TCTMP/match.out $TESTDIR/match.expected 2>$stderr 1>$stdout
	tc_pass_or_fail $? "unexpected output from fc-match"
}

################################################################################
# main
################################################################################

TST_TOTAL=8

(
	# standard tc_setup
	tc_setup
	cp $TESTDIR/* $TCTMP
	cd $TCTMP

	test01 || exit
	test02
	test03
	test04
	test05
	test06
	test07
	test08
)
