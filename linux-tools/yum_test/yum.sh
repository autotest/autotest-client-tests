#!/bin/sh
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
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
# File :        yum.sh
#
# Description:  Test the tools of yum package.
#
# Author:      Tejaswini Sambamurthy <tejaswin.linux.vnet.ibm.com> 
#	       Hariharan T S <hari@linux.vnet.ibm.com>
#
################################################################################
# source the utility functions
################################################################################
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/yum
source $LTPBIN/tc_utils.source
source $LTPBIN/domain_names.source
TESTS_DIR="${LTPBIN%/shared}/yum_test"

REQUIRED="yum yumdownloader"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    REPOLINK="http://$TEST1_AUSLAB/yumtestrepo/myrepo"
    UPDATESREPOLINK="http://$TEST1_AUSLAB/yumtestrepo/updatesrepo"
    DISTROYUMREPO="/etc/yum.repos.d/myrepo.repo"
    
    tc_exec_or_break $REQUIRED
   
    cat > $DISTROYUMREPO <<- REPODATA
[myrepo]
name=This is myrepo
baseurl=$REPOLINK
enabled=1
gpgcheck=0

[myrepo-updates]
name=This is my updates repo
baseurl=$UPDATESREPOLINK
enabled=1
gpgcheck=0
REPODATA
    
}

function tc_local_cleanup()
{
    # Remove the testrepo under /etc/yum.repos.d
    rm -rf $DISTROYUMREPO
    
    yum clean all >$stdout 2>$stderr
    tc_fail_if_bad $? "yum clean failed in clenaup" || return
}

function run_test()
{
    pushd $TESTS_DIR &> /dev/null 
    tc_register "yum"
    ./yum-release-test.sh 1>$stdout 2>$stderr
    RC=$?
    tc_ignore_warnings "^$\|There is no installed groups file\|Maybe run: yum groups mark convert\|No environment named MyGroup3 exists"
    if [ `grep -vc "Error: Nothing to do" $stderr` -eq 0 ];then cat /dev/null > $stderr; fi
    grep -q FAILED $stdout
    if [ $? -eq 0 ]; then
     	tc_fail "yum failed"
    else
	tc_pass_or_fail $RC "test failed"
     fi

    popd &> /dev/null 	
}

################################################################################
# MAIN
################################################################################
TST_TOTAL=1
tc_setup
run_test
