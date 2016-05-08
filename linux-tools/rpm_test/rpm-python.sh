#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
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
#
# File :	rpm-python.sh
#
# Description:	Test rpm-python subpackage
#
# Author:	rende
#
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

#testdir=${LTPBIN%/shared}/rpm_test-python
testdir=${LTPBIN%/shared}/rpm_test

fullpkgname=""

################################################################################
# testcase functions
################################################################################

function tc_local_setup()
{
	#fullpkgname=$(find /usr/src/packages/RPMS -name "tst_rpm*.rpm")
	fullpkgname=$(find /root/rpmbuild/RPMS -name "tst_rpm*.rpm"| grep -v debug | grep -v source)
	[ -n "$fullpkgname" -a  -e "$fullpkgname" ]
	tc_break_if_bad $? "sample rpm not found, make sure you've run rpm.sh before this test." || return

	#if rpm -qa|grep -q tst_rpm ; then
	#	tc_info "uninstall tst_rpm in local_setup"
	#	rpm -e tst_rpm &>/dev/null
	#fi
}

function rpmupgrade()
{
	tc_register "rpmupgrade.py"

	$testdir/rpmupgrade.py $fullpkgname >$stdout 2>$stderr
	tc_fail_if_bad $? "rpmupgrade.py failed" || return

	rpm -qa|grep -q tst_rpm
	tc_pass_or_fail $? "tst_rpm doesn't get installed"

}

function rpmvercomp()
{
	tc_register "rpmvercomp.py"

	$testdir/rpmvercomp.py $fullpkgname >$stdout 2>$stderr
	tc_fail_if_bad $? "rpmvercomp.py failed" || return

	grep -q "OK to upgrade" $stdout
	tc_pass_or_fail $? "Version compare failed"

}

function rpmqa()
{
	tc_register "rpmqa.py"

	$testdir/rpmqa.py >$stdout 2>$stderr
	tc_fail_if_bad $? "rpmqa.py failed" || return

	grep -q "tst_rpm" $stdout #&& grep -q "P tst_rpm" $stdout
	tc_pass_or_fail $? "rpmqa.py failed to find the pkj \"tst_rpm\" "

}

function rpmglob()
{
	tc_register "rpmglob.py"

	$testdir/rpmglob.py "tst_rpm*" >$stdout 2>$stderr
	tc_fail_if_bad $? "rpmglob.py failed" || return

	grep -q "tst_rpm" $stdout 
	tc_pass_or_fail $? "rpmglob.py failed"

}

function rpminfo()
{
	tc_register "rpminfo.py"

	$testdir/rpminfo.py tst_rpm >$stdout 2>$stderr
	tc_fail_if_bad $? "rpminfo.py failed" || return

	grep -q "Package *: tst_rpm" $stdout 
	tc_pass_or_fail $? "rpminfo.py failed"

}

function rpmreadheader()
{
	tc_register "rpmreadheader.py"

	$testdir/rpmreadheader.py $fullpkgname >$stdout 2>$stderr
	tc_pass_or_fail $? "rpmreadheader.py failed"

}

function rpmremove()
{
	tc_register "rpmremove.py"

	$testdir/rpmremove.py tst_rpm >$stdout 2>$stderr
	tc_fail_if_bad $? "rpmremove.py failed" || return

	rpm -qa|grep -q tst_rpm
	tc_pass_or_fail !$? "tst_rpm doesn't get uninstalled"

}

####################################################################################
# MAIN
####################################################################################

# Function:	main
#

#
# Exit:		- zero on success
#		- non-zero on failure
#

TST_TOTAL=7

tc_setup
rpmupgrade
rpmvercomp
rpmqa
rpmglob
rpminfo
rpmreadheader
rpmremove

