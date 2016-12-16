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
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/virt_what
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/virt_what/tests/

################################################################################
# Utility functions
################################################################################
function tc_local_setup()
{
    rpm -q virt-what 1>$stdout 2>$stderr
    tc_break_if_bad $? "virt-what not installed" || return
    ln -s /usr/libexec/virt-what-cpuid-helper ${PWD}/virt-what-cpuid-helper
    ln -s /usr/sbin/virt-what ${PWD}/virt-what
    if [ ! -e ${PWD}/tests ] ; then
	ln -s $TESTS_DIR ${PWD}/tests
    fi
}
function tc_local_cleanup()
{
    unlink ${PWD}/virt-what-cpuid-helper
    unlink ${PWD}/virt-what
    if [ -h ${PWD}/tests ] ; then
	unlink {PWD}/tests
    fi
}

#############################################################################
# Test functions
#############################################################################
function runtests()
{
    pushd $TESTS_DIR >$stdout 2>$stderr
    TESTS=`ls *.sh`
    popd >$stdout 2>$stderr
    for tst in $TESTS
    do
        tc_register "$tst"
	sed -i "s|root=tests|root=${TESTS_DIR}|g" $TESTS_DIR/$tst
        $TESTS_DIR/$tst 1>$stdout >$stderr 
        retval=$?
        tc_pass_or_fail $retval "$tst failed"
    done
}

#############################################################################
# Main
#############################################################################
tc_setup
TST_TOTAL=`echo $TESTS | wc -l`
runtests
