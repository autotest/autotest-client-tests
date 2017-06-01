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
## File:         libverto.sh
##
## Description:  This program tests libverto
##
## Author:       Athira Rajeev>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libverto
source $LTPBIN/tc_utils.source
TESTS_DIR=${LTPBIN%/shared}/libverto/tests/
MODULES=""

################################################################################
# Utility functions
################################################################################

#
# local setup
#
function tc_local_setup()
{
      tc_check_package libverto
    tc_break_if_bad $? "libverto not installed" || return

      tc_check_package libverto
    [ $? -eq 0 ] && MODULES="$MODULES glib"
      tc_check_package libverto
    [ $? -eq 0 ] && MODULES="$MODULES libevent"
      tc_check_package libverto
    [ $? -eq 0 ] && MODULES="$MODULES tevent"

    return 0
}

function runtests()
{
    pushd $TESTS_DIR/.libs &>/dev/null

    TESTS="read child signal idle write timeout"
    for t in $TESTS
    do
        for m in $MODULES
        do
	    # known problem upstream with tevent write test.  tevent does not fire a callback on error
	    # Reference link : https://github.com/gentoo/gentoo-gitmig-20150809-draft/blob/master/dev-libs/libverto/libverto-0.2.6.ebuild
	    if [ $m = "tevent" ] && [ $t = "write" ]; then
                continue
            fi

            tc_register "$t $m"
            ./$t $m >$stdout 2>$stderr
            tc_pass_or_fail $? "$t $m failed"
        done
    done
    popd &>/dev/null
}
tc_setup
TST_TOTAL=6
runtests 
