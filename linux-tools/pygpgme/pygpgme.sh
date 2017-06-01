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
### File :       pygpgme.sh                	                              ##
##
### Description: Test for pygpgme  package                                     ##
##
### Author:      Athira Rajeev <atrajeev@in.ibm.com>                           ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/pygpgme
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/pygpgme"
REQUIRED="python"

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return 
}

function tc_local_cleanup()
{
	# Unlink the files which
	# were created in the setup
	unlink $TESTS_DIR/gpgme/_gpgme.so
	unlink $TESTS_DIR/gpgme/editutil.py
	unlink $TESTS_DIR/gpgme/__init__.py
}

function install_check()
{
      tc_check_package pygpgme
	tc_break_if_bad $? "pygpgme not installed"
}

function run_test()
{
	pushd $TESTS_DIR >$stdout 2>$stderr
	
	# The tests refer to gpgme modules in
	# path where the test modules are present
	# Example import gpgme.tests and import gpgme.__gpgme
	# link the system installed modules to test path and unlink in cleanup
	gpgme_path=`find /usr/lib* -name gpgme`
	ln -s $gpgme_path/_gpgme.so $TESTS_DIR/gpgme/_gpgme.so
	ln -s $gpgme_path/editutil.py $TESTS_DIR/gpgme/editutil.py
	ln -s $gpgme_path/__init__.py $TESTS_DIR/gpgme/__init__.py

	# The tests are in unittestr framework
	# triggered by test_all.py
	tc_register "Tests for pygpgme"
	GPG_AGENT_INFO= python test_all.py -v &>$stdout
	grep -q "OK" $stdout
	tc_pass_or_fail $? "pygpgme tests failed"

	popd >$stdout 2>$stderr
}

#
# main
#

TST_TOTAL=1

tc_setup
install_check && run_test 
