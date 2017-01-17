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
### File : perl-Scalar-List-Utils                          		      ##
##
### Description: This testcase tests perl-Scalar-List-Utils package            ##
##
### Author:      Ravindran Arani <ravi@linux.vnet.ibm.com>                     ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_Scalar_List_Utils
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/perl_Scalar_List_Utils/"

function tc_local_setup()
{
    rpm -q perl-Scalar-List-Utils >$stdout 2>$stderr
    tc_break_if_bad $? "perl-Scalar-List-Utils is not installed"
}

function runtests()
{
    pushd $TESTDIR >$stdout 2>$stderr
    TST_TOTAL=`ls -1 t/*.t|wc -l`
    #create directory blib to make a test case work
    install -d blib
    for test in `ls t/*.t`
    do
    tc_register "Test $test"
    PERL_DL_NONLAZY=1
    perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" $test >$stdout 2>$stderr
    RC=$?
    tc_ignore_warnings "overload arg"
    tc_pass_or_fail $RC "$test failed"
    done
    rm -rf blib
    popd >$stdout 2>$stderr
}

#
#MAIN
#
tc_setup
runtests
