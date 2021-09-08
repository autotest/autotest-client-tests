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
### File :       oddjob.sh                                                     ##
##
### Description: This testcase tests oddjob package                            ##
##
### Author:      Sheetal Kamatar <sheetal.kamatar@in.ibm.com>                  ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/oddjob
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/oddjob"
ODDJOB_TESTDIR="${LTPBIN%/shared}/oddjob/tests/"
ODDJOB_CMDDIR="${LTPBIN%/shared}/oddjob/tests/cmdparse"

function tc_local_setup() 
{
	# Check Installation
	tc_check_package oddjob
	tc_break_if_bad $? "oddjob required, but not installed" || return

	cp $TESTDIR/tests/test-oddjobd.sh $TESTDIR/tests/test-oddjobd.sh.bkp
	sed -e 's/break/exit 1/g' -e '/exit 0/d' -i $TESTDIR/tests/test-oddjobd.sh
	pkgname=$(tc_print_package_version oddjob)
	cp $TESTDIR/tests/test-oddjobd.conf $TESTDIR/tests/test-oddjobd.conf.bkp
	sed -e 's|/builddir/build/BUILD/'$pkgname'/tests/|'$ODDJOB_TESTDIR'|g' -e 's/"mockbuild"/"root"/' -i $TESTDIR/tests/test-oddjobd.conf
	sed -e 's|\(^[0-9].*\)|0|g' -e 's|mockbuild|root|g' -i $TESTDIR/tests/006/expected_stdout
	sed -e 's|\(^[0-9].*\)|0|g' -e 's|mockbuild|root|g' -i $TESTDIR/tests/007/expected_stdout
	sed -e 's|mockbuild|root|g' -i $TESTDIR/tests/008/expected_stdout
}

function test01()
{
	tc_register "Testing cmdparse"	
	pushd $ODDJOB_CMDDIR &> $stdout 2>$stderr
	./test-cmdparse.sh >$stdout 2>$stderr
	tc_pass_or_fail $? "cmdparse failed"
	popd &> $stdout 2> $stderr
}

function test02()
{
	pushd $ODDJOB_TESTDIR &> $stdout 2>$stderr
	tc_register "Testing methods"
	./test-oddjobd.sh >$stdout 2>$stderr
	RC=$?
	tc_ignore_warnings "Error org.freedesktop.DBus.Error.SELinuxSecurityContextUnknown: Could not determine security context for ':"
	tc_pass_or_fail $RC "Test Failed"
	popd &> $stdout 2>$stderr
}

#
# main
#
tc_setup
TST_TOTAL=2
test01
test02
