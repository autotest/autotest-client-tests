#!/bin/bash
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
### File :        perl-Net-LibIDN.sh                                           ##
##
### Description:  Test for perl-Net-LibIDN                                     ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_Net_LibIDN
source $LTPBIN/tc_utils.source
NETLIBIDN_TEST_DIR="${LTPBIN%/shared}/perl_Net_LibIDN/test"

function tc_local_setup()
{
     [ -f /usr/lib*/perl5/vendor_perl/auto/Net/LibIDN/LibIDN.so ]
     tc_break_if_bad $? "perl-Net-LibIDN not installed"
}

function run_test()
{
    pushd $NETLIBIDN_TEST_DIR >$stdout 2>$stderr
    tc_register "testing perl-Net-LibIDN"
    perl test.pl >$stdout 2>$stderr
    tc_pass_or_fail $? "perl-Net-LibIDN tests failed"
    popd >$stdout 2>$stderr
}

################################################################################
# main
################################################################################

TST_TOTAL=1
tc_setup && \
run_test
