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
## File :        perl-Net-DNS.sh
##
## Description:  Tests for perl-Net-DNS package
##
## Author:       Kumuda G, kumuda@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/perl_Net_DNS
source $LTPBIN/tc_utils.source

TESTS_DIR="${LTPBIN%/shared}/perl_Net_DNS"

function tc_local_setup()
{
    tc_root_or_break
    tc_get_os_arch
    # check versions of installed perl modules instead of src files
    cp $TESTS_DIR/t/00-version.t $TESTS_DIR/t/00-version.t.orig
    if [ "$TC_OS_ARCH" = "x86_64" -o "$TC_OS_ARCH" = "ppc64" -o "$TC_OS_ARCH" = "s390x" ]; then
        sed -i 's|blib lib|/usr lib64 perl5 Net|' $TESTS_DIR/t/00-version.t
    else
        sed -i 's|blib lib|/usr lib perl5 Net|' $TESTS_DIR/t/00-version.t
    fi
    # Cygwin module is not packaged, exclude that test
    cp $TESTS_DIR/t/00-load.t $TESTS_DIR/t/00-load.t.orig
        sed -i -e '/Cygwin/ s/^/#/' -e 's/=> 81/=> 80/' $TESTS_DIR/t/00-load.t

}

function tc_local_cleanup()
{
    mv $TESTS_DIR/t/00-version.t.orig $TESTS_DIR/t/00-version.t
    mv $TESTS_DIR/t/00-load.t.orig $TESTS_DIR/t/00-load.t
}

function run_test()
{
    pushd $TESTS_DIR &> /dev/null
    tests=`ls t/*.t`
    TST_TOTAL=$(echo $tests|wc -w)
    for i in $tests; do
        tc_register $i
        perl $i 1>$stdout 2>$stderr
        rc=$?
        # Some lines are throwed to stderr with hash, so ignore them
	tc_ignore_warnings "^#"
        tc_pass_or_fail $rc "$i failed"
    done
    popd &> /dev/null
}
################################################################################
# MAIN
################################################################################
tc_setup
run_test
