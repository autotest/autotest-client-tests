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
##                                                                            ##
## File : perl-Crypt-SSleay                                                   ##
##                                                                            ##
## Description: This testcase tests perl-Crypt-SSleay package                 ##             
##                                                                            ##
## Author:      Sheetal Kamatar <sheetal.kamatar@in.ibm.com>                  ##
##                                                                            ##
################################################################################
######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_Crypt_SSLeay
MAPPER_FILE="$LTPBIN/mapper_file"
source $LTPBIN/tc_utils.source
source  $MAPPER_FILE
PERL_CRYPT_TESTDIR="${LTPBIN%/shared}/perl_Crypt_SSLeay/t"
REQUIRED="perl"
function tc_local_setup()
{
    tc_exec_or_break $REQUIRED
    tc_check_package "$PERL_CRYPT_SSLEAY"
    tc_break_if_bad $? "$PERL_CRYPT_SSLEAY not installed"
    # Creating and enabling 02-live.t test in configuration file.
    cat <<EOF > $PERL_CRYPT_TESTDIR/test.config
    network_tests	1
EOF
    # Changing the rt.cpan.org https server to kjhub1.au.example.com 
    # as all the machines do not have outbound access by default
    [ -e $PERL_CRYPT_TESTDIR/02-live.t ] && sed -i "s/rt.cpan.org/kjhub1.au.example.com/g" $PERL_CRYPT_TESTDIR/02-live.t
}

function runtests()
{
	pushd $PERL_CRYPT_TESTDIR >$stdout 2>$stderr
	TESTS=`ls *.t`
	TST_TOTAL=`echo $TESTS | wc -w`
	for test in $TESTS; do
		tc_register "Test $test"
		perl $test &>$stdout 2>$stderr
		RC=$?
		if [ $test == 02-live.t ];
		then
			tc_ignore_warnings "Reading configuration from 'test.config' on linux"
			tc_ignore_warnings "network_tests : 1"
			tc_ignore_warnings "Cheat by disabling LWP::UserAgent host verification"
		fi
		tc_pass_or_fail $RC "$test failed"
	done
	popd >$stdout 2>$stderr
}

#
#MAIN
#
tc_setup
runtests
