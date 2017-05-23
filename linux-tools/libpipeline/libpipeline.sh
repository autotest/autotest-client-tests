#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##    1.Redistributions of source code must retain the above copyright notice,            ##
##        this list of conditions and the following disclaimer.                           ##
##    2.Redistributions in binary form must reproduce the above copyright notice, this    ##
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
################################################################################
#
# File :        libpipeline.sh
#
# Description:  Test libpipeline package
#
# Author:     Basheer Khadarsabgari<bkhadars@in.ibm.com> 
#
# History:     March 2, 2015 Created
#
#
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libpipeline
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libpipeline/tests/.libs"
################################################################################
#  Utility functions
################################################################################
#
#
# local setup
#
#function tc_local_setup(){
#}

#function tc_local_cleanup(){
#}

################################################################################
# testcase functions
################################################################################

# Function:             runtests
#
# Description:          - test libpipeline
#
# Parameters:           - none
#
# Return                - zero on success
#                       - return value from commands on failure
#
function runtests(){
    tc_info "Exercising libpipeline tests"
    pushd $TESTS_DIR >$stdout 2>$stderr
    TESTS=`ls`
    for test in $TESTS; do
        tc_register "Test $test"
        ./$test 1> $stdout 2>$stderr
        tc_pass_or_fail $? "libpipeline $test failed !!"
    done
    popd >$stdout 2>$stderr
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
    tc_register     "installation check"
      tc_check_package libpipeline
    tc_break_if_bad $? "Perl-Exporter is not installed!!"
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
