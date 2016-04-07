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
### File :        perl-Text-Iconv.sh                                           ##
##
### Description:  The Text::Iconv module provides a Perl interface to the      ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
ICONV_DIR="${LTPBIN%/shared}/perl_Text_Iconv"
PERL_CMD=`which perl`

function tc_local_setup()
{
        [ -f /usr/lib*/perl5/vendor_perl/auto/Text/Iconv/Iconv.so ]
        tc_break_if_bad $? "perl-Text-Iconv not installed"

        tc_exec_or_break $PERL_CMD
}

function run_test()
{
 pushd $ICONV_DIR >$stdout 2>$stderr
 TESTS=`ls t/*.t`
 TST_TOTAL=`echo $TESTS | wc -w`

 for test in $TESTS; do
 tc_register "Test $test"
 $PERL_CMD $test >$stdout 2>$stderr
 tc_pass_or_fail $? "$test failed"
 done

 popd >$stdout 2>$stderr
}
 
################################################################################
# main
################################################################################
tc_setup && \
run_test 
