#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
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
############################################################################################
#
# File :        gdk-pixbuf2.sh
#
# Description:  Test for the gdk-pixbuf2 package
#
# Author:       Charishma M <charism2@in.ibm.com>
############################################################################################
# source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/gdk_pixbuf2
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/gdk_pixbuf2

##############################################################################
# Utility functions
##############################################################################

function tc_local_setup()
{
      tc_check_package gdk-pixbuf2
    tc_break_if_bad $? "gdk-pixbuf2 not installed" || return

# gdk-pixbuf2-tests rpm provides the testsuite for gdk-pixbuf2 package
      tc_check_package gdk-pixbuf2
    tc_break_if_bad $? "gdk-pixbuf2-tests not installed" || return

    ln -s /usr/libexec/installed-tests/gdk-pixbuf $TESTS_DIR/gdk-pixbuf >$stdout 2>$stderr
}

function tc_local_cleanup()
{
    unlink $TESTS_DIR/gdk-pixbuf
}

#############################################################################
# Test functions
#############################################################################

function runtests()
{
    pushd $TESTS_DIR/gdk-pixbuf
    TESTS=`find . -type f -executable`
    TST_TOTAL=`echo $TESTS | wc -w`
    for tst in $TESTS
    do
	test_name=`echo $tst | sed 's/^..//'`	
        tc_register "$test_name"
        $tst >$stdout
        tc_pass_or_fail $? "$tst_name failed"
    done
    popd
}

#############################################################################
# Main
#############################################################################
tc_setup
TST_TOTAL=1
runtests
