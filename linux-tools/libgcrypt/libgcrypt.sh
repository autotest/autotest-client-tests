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
## File : libgcrypt.sh
##
## Description: Test rsync package using tests from the source
##
## Author: Sheetal Kamatar <sheetal.kamatar@in.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libgcrypt
TESTDIR=${LTPBIN%/shared}/libgcrypt
source $LTPBIN/tc_utils.source 
LIBGCRYPT_DIR="${LTPBIN%/shared}/libgcrypt/tests"
FIPS_CONFIG=`find / -name libgcrypt.so.11 | head -1`

function tc_local_setup()
{
	rpm -q libgcrypt >$stdout 2>$stderr
	tc_break_if_bad $? "libgcrypt required, but not installed" || return
	fipshmac $FIPS_CONFIG>$stdout 2>$stderr
        tc_break_if_bad $? "Failed to create checksum file using fipshmac"

}

################################################################################
# Testcase functions
################################################################################
function run_test()
{
	pushd $LIBGCRYPT_DIR &> /dev/null
	TESTS="t-mpi-bit prime register ac ac-schemes ac-data basic mpitests tsexp keygen pubkey hmac keygrip fips186-dsa benchmark"	
	TST_TOTAL=`echo $TESTS | wc -w`
	for test in $TESTS; do
		tc_register "Testing $test"
		./$test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	done
	popd &> /dev/null
}

#################################################################################
#              main
#################################################################################
tc_setup
run_test
