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
## File:         libbonobo.sh
##
## Description:  This program tests libbonobo
##
## Author:       Athira Rajeev
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libbonobo
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/libbonobo/tests

################################################################################
# Utility functions
################################################################################

#
# local setup
#
function tc_local_setup()
{
    rpm -q libbonobo 1>$stdout 2>$stderr
    tc_break_if_bad $? "libbonobo not installed" || return

    sed -i "s:^BONOBO_ACTIVATION_SERVER=.*:BONOBO_ACTIVATION_SERVER=\"/usr/libexec/bonobo-activation-server\";:g" \
    $TESTS_DIR/test-activation/test.sh
}

function runtest()
{
    pushd $TESTS_DIR/test-activation &>/dev/null

    tc_register "bonobo-activation test"   
    BONOBO_ACTIVATION_DEBUG=1 BONOBO_ACTIVATION_PATH=".:$BONOBO_ACTIVATION_PATH" ./test.sh 1>$stdout 2>$stderr
    RC=$?
    grep -q FAILED $stdout
    if [ $? -ne 0 ]; then
        cat /dev/null > $stderr
    fi
    tc_pass_or_fail $RC "bonobo-activation test failed"

    popd  &>/dev/null

    pushd $TESTS_DIR/.libs  &>/dev/null
    TESTS="test-moniker test-event-source test-object test-stream-mem test-storage-mem test-main-loop"
    for t in $TESTS
    do
        tc_register $t
        ./$t >$stdout 2>$stderr   
        RC=$?
        tc_ignore_warnings "^$\|Wrong permissions for \/tmp\/orbit-root"
        grep -q "passed" $stderr
        [ $? -eq 0 ] && cat /dev/null > $stderr
        echo $t | grep -q test-moniker
        if [ $? -eq 0 ]; then
            grep -q ERROR $stderr
            [ $? -ne 0 ] && cat /dev/null > $stderr
        fi
        tc_pass_or_fail $RC "$t failed"
    done
    popd &>/dev/null
}

function test01()
{
    tc_register "bonobo-activation-sysconf --config-file-path"
    bonobo-activation-sysconf --config-file-path >$stdout 2>$stderr
    tc_fail_if_bad $? "bonobo-activation-sysconf --config-file-path failed" || return

    grep -q "/etc/bonobo-activation/bonobo-activation-config.xml" $stdout
    tc_pass_or_fail $? "bonobo-activation-sysconf --config-file-path failed to dispaly path"

    tc_register "bonobo-activation-sysconf --add-directory"
    bonobo-activation-sysconf --add-directory="/bonobo/servers/" >$stdout 2>$stderr
        tc_pass_or_fail $? "bonobo-activation-sysconf --add-directory failed"

    tc_register "bonobo-activation-sysconf --display-directories"
    bonobo-activation-sysconf --display-directories >$stdout 2>$stderr
    tc_fail_if_bad $? "bonobo-activation-sysconf failed" || return

    grep -q "/bonobo/servers/" $stdout
    tc_pass_or_fail $? "bonobo-activation-sysconf failed display directories"

    tc_register "bonobo-activation-run-query"
    bonobo-activation-run-query "_active == true"  >$stdout 2>$stderr
    RC=$?
    tc_ignore_warnings "^$\|Wrong permissions for \/tmp\/orbit-root"
    tc_fail_if_bad $RC "bonobo-activation-run-query failed" || return

    grep -q "OAFIID:Bonobo_CosNaming_NamingContext" $stdout
    tc_pass_or_fail $? "bonobo-activation-run-query failed to display"   

    tc_register "activation-client"
    activation-client -q -s "iid == 'OAFIID:Bonobo_CosNaming_NamingContext'" >$stdout 2>$stderr
    RC=$?
    tc_ignore_warnings "^$\|Wrong permissions for \/tmp\/orbit-root"
        tc_fail_if_bad $RC "activation-client failed" || return

    [ `grep -E "repo_ids|location|name" $stdout | wc -l` -eq 3 ]
    tc_pass_or_fail $? "activation-client failed to list repo_ids locations and name"

    tc_register "activation-client -s"
    activation-client -q -s "repo_ids.has ('IDL:CosNaming/NamingContext:1.0')" >$stdout 2>$stderr
    RC=$?
    tc_ignore_warnings "^$\|Wrong permissions for \/tmp\/orbit-root"
    tc_fail_if_bad $RC "activation-client -s failed"
   
    grep -q "OAFIID:Bonobo_CosNaming_NamingContext" $stdout
    tc_pass_or_fail $? "activation-client -s"
}
tc_setup
TST_TOTAL=13
runtest
test01
