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
## File :        gpgme.sh                                                     ##
##                                                                            ##
## Description:  GPGME provides a high-level crypto API for                   ##
##               encryption, decryption, signing, signature verification and  ##
##               key management.                                              ##
##                                                                            ##
## Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
##                                                                            ##
################################################################################
# source the utility functions
#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/gpgme
source $LTPBIN/tc_utils.source
GPGME_TEST_DIR="${LTPBIN%/shared}/gpgme_test/tests"

function tc_local_setup()
{
        [ -f /usr/lib*/libgpgme.so.11 ] 
        tc_break_if_bad $? "gpgme not installed" 
	# If any existing gpg-agent running, killing them
	ps -e | grep -i gpg-agent >/dev/null
	if [ $? -eq 0 ]; then
		pkill gpg-agent > /dev/null
	else
		gpg_agent_running=0
	fi
	tc_install_package libksba
	tc_break_if_bad $? "Failed to install libksba"
}

function tc_local_cleanup()
{
	if [ "$gpg_agent_running" == 0 ]; then
		pkill gpg-agent > /dev/null
	fi
}	


function run_gpgtest()
{
   pushd $GPGME_TEST_DIR/gpg &> /dev/null
   export GNUPGHOME=`pwd`
   sed -i 's:/builddir/build/BUILD/gpgme-[0-9]*.[0-9]*.[0-9]*/tests/gpg/pinentry:'${GPGME_TEST_DIR}'/gpg/pinentry:' gpg-agent.conf
   TESTS=`ls bin/*`

   TOTAL=`echo $TESTS | wc -w` 
   for test in $TESTS; do 
       tc_register "Testing $test"
       ./$test >$stdout 2>$stderr
     tc_pass_or_fail $? "$test failed" 
   done
   popd &> /dev/null 
}

function run_gpgsmtest()
{
   pushd $GPGME_TEST_DIR/gpgsm &> /dev/null
   export GNUPGHOME=`pwd`
   TESTS="bin/t-decrypt  bin/t-encrypt  bin/t-export bin/t-import  bin/t-keylist  bin/t-sign  bin/t-verify"
  
   TOTAL1=`echo $TESTS | wc -w`
   for test in $TESTS; do
   	tc_register "Testing $test"
	./$test >$stdout 2>$stderr
	RC=$?
	if ( [ "$test" == "bin/t-keylist" ] && [ `grep -ivc "Warning: Skipping unknown key" $stderr` -eq 0 ] )
	then
		cat /dev/null > $stderr
	fi
	tc_pass_or_fail $RC "$test failed"
   done
   popd &> /dev/null
}

#################################################################################
#         main
#################################################################################

tc_setup
run_gpgtest
run_gpgsmtest
TST_TOTAL=$((TOTAL + TOTAL1))
