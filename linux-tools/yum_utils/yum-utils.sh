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
## File :        yum-utils.sh
##
## Description:  Test the tools of yum-utils package.
##
## Author:       Kumuda G, kumuda@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TESTS_DIR="${LTPBIN%/shared}/yum_utils"

REQUIRED="yumdownloader package-cleanup repoclosure repo-graph repoquery repo-rss reposync repotrack"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    tc_exec_or_break $REQUIRED || return
    # Replace test scripts to call the binaries installed on SUT
    # instead of calling those present in the RPM sources
    sed -i 's/python yumdownloader.py/yumdownloader/g' $TESTS_DIR/test/test-yumdownloader
    sed -i 's/python package-cleanup.py/package-cleanup/g' $TESTS_DIR/test/test-package-cleanup
    sed -i 's/python repoclosure.py/repoclosure/g' $TESTS_DIR/test/test-repoclosure
    sed -i 's/python repo-graph.py/repo-graph/g' $TESTS_DIR/test/test-repo-graph
    sed -i 's/python repoquery.py/repoquery/g' $TESTS_DIR/test/test-repoquery
    sed -i 's/python repo-rss.py/repo-rss/g' $TESTS_DIR/test/test-repo-rss
    sed -i 's/python reposync.py/reposync/g' $TESTS_DIR/test/test-reposync
    sed -i 's/python repotrack.py/repotrack/g' $TESTS_DIR/test/test-repotrack
}

function run_test()
{
    pushd $TESTS_DIR &> /dev/null 
    tc_register "yumdownloader"
    test/test-yumdownloader 1>$stdout 2>$stderr
    tc_pass_or_fail $? "test failed"

    tc_register repo-rss
    test/test-repo-rss 1>$stdout 2>$stderr
    #repo-rss.xml does not exist in 1st attempt as the test script first removes this file 
    #and then starts the test. Hence this would fail in 1st run; so ignoring 
    #this error from stderr.
    if [ `grep -cvi "cannot remove .repo-rss.xml" $stderr` -eq 0 ]; then
	cat /dev/null > $stderr
    fi
    tc_pass_or_fail $? "test failed"

    tc_register package-cleanup
    test/test-package-cleanup 1>$stdout 2>$stderr
    tc_pass_or_fail $? "test failed"

    tc_register repoquery
    test/test-repoquery 1>$stdout 2>$stderr
    tc_pass_or_fail $? "test failed"

    tc_register repoclosure
    test/test-repoclosure 1>$stdout 2>$stderr
    tc_pass_or_fail $? "test failed"

    tc_register reposync
    test/test-reposync 1>$stdout 2>$stderr
    tc_pass_or_fail $? "test failed"

    tc_register repotrack
    test/test-repotrack 1>$stdout 2>$stderr
    # Here test/test-repotrack deletes yum*.rpm which are not available and 
    #then starts the test. So, there would error for rm yum*.rpm; hence ignoring 
    #this error from stderr.
    if [ `grep -cvi "cannot remove .yum" $stderr` -eq 0 ]; then
	cat /dev/null > $stderr
    fi
    tc_pass_or_fail $? "test failed"

    tc_register repo-graph
    test/test-repo-graph 1>$stdout 2>$stderr
    tc_pass_or_fail $? "test failed"

    popd &> /dev/null 	
}

################################################################################
# MAIN
################################################################################
TST_TOTAL=8
tc_setup
run_test
