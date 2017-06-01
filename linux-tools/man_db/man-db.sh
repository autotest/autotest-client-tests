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
############################################################################################
#
# File :        man-db.sh
#
# Description:  Test for the man-db package
#
# Author:       Loganathan G <loganag2@in.ibm.com>
############################################################################################
# source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/man_db
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/man_db/tests/
REQUIRED="libtool"

##############################################################################
# Utility functions
##############################################################################

function tc_local_setup()
{
    tc_exec_or_break $REQUIRED || exit
      tc_check_package man-db
    tc_break_if_bad $? "man-db not installed" || return
    ln -s /usr/bin/libtool $TESTS_DIR/libtool
    ln -s /usr/libexec/man-db/manconv $TESTS_DIR/manconv
}

function tc_local_cleanup()
{
    unlink $TESTS_DIR/libtool
    unlink $TESTS_DIR/manconv
}

#############################################################################
# Test functions
#############################################################################

function runtests()
{
    pushd $TESTS_DIR
    TESTS="lexgrog-1 man-1 man-2 man-3 manconv-1 manconv-2 manconv-3 mandb-1 mandb-2 mandb-3 mandb-4 mandb-5 mandb-6 whatis-1 zsoelim-1"
    export PATH=.:$PATH
    export top_builddir=$TESTS_DIR
    export CHARSETALIASDIR=$TESTS_DIR/gnulib/lib
    export DBTYPE=gdbm
    for tst in $TESTS
    do
        tc_register "$tst"
        ./$tst >$stdout
        retval=$?
        tc_pass_or_fail $retval "$tst failed"
    done
    popd
}

#############################################################################
# Main
#############################################################################
tc_setup
TST_TOTAL=15
runtests
