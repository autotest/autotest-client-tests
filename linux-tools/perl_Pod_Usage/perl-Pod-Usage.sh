#!/bin/sh
############################################################################################
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
## File :        perl-Pod-Usage.sh
##
## Description:  Test perl-Pod-Usage package
##
## Author:      Hoisaleshwara Madan V S  <madan.vsh@in.ibm.com>
###########################################################################################
## source the utility functions

#LTPBIN=${LTPBIN%/shared}/perl_Pod_Usage
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/perl_Pod_Usage"
################################################################################
#  Utility functions
################################################################################
#
#
# local setup
#
function tc_local_setup(){
	pushd $TESTS_DIR 1>$stdout 2>$stderr
	cp lib/Pod/Usage.pm blib/lib/Pod/Usage.pm
	cp scripts/pod2usage blib/script/pod2usage
	popd 1>$stdout 2>$stderr
}

function tc_local_cleanup(){
	pushd $TESTS_DIR 1>$stdout 2>$stderr
	rm blib/lib/Pod/Usage.pm
	rm blib/script/pod2usage
	popd 1>$stdout 2>$stderr
}

################################################################################
# testcase functions
################################################################################

# Function:             runtests
#
# Description:          - test perl-Pod-Usage
#
# Parameters:           - none
#
# Return                - zero on success
#                       - return value from commands on failure
#
function runtests(){
	tc_info "Exercising perl-Pod-Usage tests"
	pushd $TESTS_DIR 1>$stdout 2>$stderr
	/usr/bin/perl "-Iblib/arch" "-Iblib/lib" scripts/pod2usage.PL scripts/pod2usage >/dev/null
	/usr/bin/perl -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/pod2usage >/dev/null
	PERL_DL_NONLAZY=1
	TESTS=`ls t/pod/*.t`
    	TST_TOTAL=`echo $TESTS |wc -w`
    	for test in $TESTS; do
        	tc_register "Test $test"
        	/usr/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" $test 1> $stdout 2>$stderr
        	tc_pass_or_fail $? "perl-Pod-Usage $test failed !!"
    	done
	popd 1>$stdout 2>$stderr
	tc_info "Test run Completed !!"
	
}

# Function:     installation_check
#
# Description:  checks if necessary packages are installed
#
# Parameters:   none
#
# Return        breaks the test if packages are not istalled
#
#

function installation_check() {
        tc_info     "installation check"
        tc_executes prove
	tc_break_if_bad $? "Please check if perl-Test-Harness is installed properly !!"
      tc_check_package perl-Pod-Usage
	tc_break_if_bad $? "perl-Pod-Usage package is not installed !!"
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
installation_check
runtests
