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
### File :        perl-HTML-Format.sh                                          ##
##
### Description: This testcase tests perl-HTML-Format package                  ##
##
### Author: Ramya BS , ramya@linux.vnet.ibm.com                                ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_HTML_Format
MAPPER_FILE="$LTPBIN/mapper_file"
source $LTPBIN/tc_utils.source
source $MAPPER_FILE
TESTS_DIR="${LTPBIN%/shared}/perl_HTML_Format/t"
required="perl"
LINK="/usr/share/perl5/vendor_perl/HTML"
function tc_local_setup()
{
	# check installation and environment
	tc_exec_or_break $required

	# install check
        tc_check_package "$PERL_HTML_FORMAT"
	tc_break_if_bad $? "$PERL_HTML_FORMAT not installed"
	
	#creating folder lib and soft linking modules (instead of copying lib folder from test source as this modules will be installed along with source dpkg ) ,as one of the test provided by source is written to take this modules from  lib folder and execute test.
	mkdir -p $TESTS_DIR/lib
	ln -s $LINK/FormatPS.pm $TESTS_DIR/lib
	ln -s $LINK/FormatRTF.pm $TESTS_DIR/lib
	ln -s $LINK/Formatter.pm $TESTS_DIR/lib
	ln -s $LINK/FormatText.pm $TESTS_DIR/lib

}

function tc_local_cleanup()
{
	rm -rf $TESTS_DIR/lib
}
################################################################################
# testcase functions                                                           #
################################################################################
#
# Function:             runtests
#
# Description:          - test perl-HTML-Format
#
# Parameters:           - none
#
# Return                - zero on success
#                       - return value from commands on failure
################################################################################

function run_test()
{
	pushd $TESTS_DIR &>/dev/null
	TESTS=`ls *.t`
	TST_TOTAL=`echo $TESTS | wc -w`
	for test in $TESTS; do
		tc_register "Test $test"
		perl $test >$stdout 2>$stderr
		rc=`grep "not ok" $stdout`
		[ -z "$rc" ]
		tc_pass_or_fail $? "Test $test fail"
	done
	popd &>/dev/null
}


##############################################
#MAIN                                        #
##############################################
TST_TOTAL=1
tc_setup && \
run_test

