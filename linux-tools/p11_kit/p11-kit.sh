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
## File:         p11-kit.sh
##
## Description:  This program tests basic functionality of p11-kit program
##
## Author:       Athira Rajeev <atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/p11_kit
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/p11_kit"

################################################################################
# Utility functions
################################################################################

#
# local setup
#        
function tc_local_setup()
{       
	tc_exec_or_break p11-kit || return

	# Add the module info under /usr/share/p11-kit/modules/
	cp $TEST_DIR/dummy.module /usr/share/p11-kit/modules/

	# Installation check for ca-certificates
	rpm -q ca-certificates >$stdout 2>$stdout 2>$stderr
	tc_break_if_bad $? "ca-certificates not installed"

	# Check for PKCS#11 proxy module installed
	set `find /usr/lib* -name p11-kit-trust.so`
	[ -f $1 ] &&  tc_break_if_bad $? "PKCS#11 proxy module missing"

	# Get the library path for pkcs11
	LIB_PATH="/usr/lib/pkcs11"

	tc_get_os_arch
	[ $TC_OS_ARCH = "x86_64" ] || [ $TC_OS_ARCH = "ppc64le" ] || [ $TC_OS_ARCH = "ppc64" ] || [ $TC_OS_ARCH = "s390x" ] \
	&& LIB_PATH="/usr/lib64/pkcs11"

	# Copy the mock dummy pkcs#11 module to /usr/lib64/pkcs11
	cp -r $TEST_DIR/p11-kit/tests/.libs/mock-one.so $LIB_PATH/
	
	#Copy the files and input folders to trust/.libs 
	cp -r $TEST_DIR/trust/tests/files $TEST_DIR/trust/tests/input $TEST_DIR/trust/tests/.libs

}

function tc_local_cleanup()
{
	#Remove the dummy module configurations
	rm /usr/share/p11-kit/modules/dummy.module
	rm $LIB_PATH/mock-one.so


	#Restore the configuration
	rm /etc/pki/ca-trust/source/blacklist/blacklist.p11-kit

	p11-kit extract-trust >$stdout 2>$stderr
	tc_fail_if_bad $? "p11-kit extract-trust failed while restoring the configuration"
	
	rm -rf  $TEST_DIR/trust/tests/.libs/files $TEST_DIR/trust/tests/.libs/input
}
################################################################################
# Testcase functions
################################################################################

#
# test01	p11-kit list-modules
#
function test01()
{
	tc_register     "p11-kit list-modules"
        p11-kit list-modules >$stdout 2>$stderr
	tc_fail_if_bad $? "p11-kit list-modules failed"

	#Grep for test module information in p11-kit list-modules
	[ `grep -E "dummy: mock-one.so|token: TEST LABEL|library-description: MOCK LIBRARY" $stdout | wc -l` -eq 3 ]
	tc_fail_if_bad $? "p11-kit list-modules failed to list the dummy module"

	#Grep for pkcs#11 proxy module information in p11-kit list-modules
	[ `grep -E "library-description: PKCS#11 Kit Trust Module|token: System Trust|token: Default Trust|p11-kit-trust: p11-kit-trust.so" $stdout | wc -l` -eq 4 ]
	tc_pass_or_fail $? "p11-kit list-modules failed to list pkcs#11 proxy module"
}

#
# test02        p11-kit extract-trust
#
function test02()
{
	tc_register     "p11-kit extract-trust with /etc/pki/ca-trust/"
 
	#Copy test certificate to /etc/pki/ca-trust/source/
	cp $TEST_DIR/cert.p11-kit /etc/pki/ca-trust/source/
	
	# Run p11-kit extract-trust
	p11-kit extract-trust >$stdout 2>$stderr
	tc_fail_if_bad $? "p11-kit extract-trust failed"

	# Verify the certificate configuration files are updated
	grep -F -f $TEST_DIR/cert.p11-kit.exp /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt > $TCTMP/file_to_compare
	diff -Naurp $TEST_DIR/cert.p11-kit.exp $TCTMP/file_to_compare
	tc_fail_if_bad $? "p11-kit extract-trust failed to update the ca-certificates conf files" || return

	grep -F -f $TEST_DIR/cert.p11-kit /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem > $TCTMP/file_to_compare
	diff -Naurp $TEST_DIR/cert.p11-kit.exp $TCTMP/file_to_compare
	tc_pass_or_fail $? "p11-kit extract-trust failed to update /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"

	#Restore the configuration
	rm /etc/pki/ca-trust/source/cert.p11-kit

	p11-kit extract-trust >$stdout 2>$stderr
	tc_fail_if_bad $? "p11-kit extract-trust failed while restoring the configuration" || return

	tc_register 	"p11-kit extract-trust with /usr/share/pki/ca-trust-source/"
	
	#Copy test certificate to /usr/share/pki/ca-trust-source/
	cp $TEST_DIR/cert.p11-kit /usr/share/pki/ca-trust-source/

	# Run p11-kit extract-trust
	p11-kit extract-trust >$stdout 2>$stderr
	tc_pass_or_fail $? "p11-kit extract-trust failed"

	# Verify the certificate configuration files are updated
	grep -F -f $TEST_DIR/cert.p11-kit.exp /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt > $TCTMP/file_to_compare
	diff -Naurp $TEST_DIR/cert.p11-kit.exp $TCTMP/file_to_compare
	tc_fail_if_bad $? "p11-kit extract-trust failed to update /etc/pki/tls/certs/ca-bundle.crt" || return
	
	grep -F -f $TEST_DIR/cert.p11-kit /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem > $TCTMP/file_to_compare
	diff -Naurp $TEST_DIR/cert.p11-kit.exp $TCTMP/file_to_compare
	tc_pass_or_fail $? "p11-kit extract-trust failed to update /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
}

#
# test03        p11-kit extract
#
function test03()
{
	tc_register     "p11-kit extract --filter=certificates"

	# Test differnt --filter and --format options
	p11-kit extract --filter=certificates --format=openssl-bundle --comment $TCTMP/result1 >$stdout 2>$stderr
	tc_fail_if_bad $? "p11-kit extract --filter=certificates failed"

	# Check the certificate contents of cert.p11-kit 
	# are present in the output
	grep -F -f $TEST_DIR/cert.p11-kit.exp $TCTMP/result1 > $TCTMP/file_to_compare
	diff -Naurp $TEST_DIR/cert.p11-kit.exp $TCTMP/file_to_compare
	tc_pass_or_fail $? "p11-kit extract --filter=certificates failed to show $TEST_DIR/cert.p11-kit"

	tc_register     "p11-kit extract --format=pem-directory"

	p11-kit extract --filter=certificates --format=pem-directory $TCTMP/result2
	tc_fail_if_bad $? "p11-kit extract --filter=certificates --format=pem-directory failed"

	set `find $TCTMP/result2 -name *.pem`
	[ -f $1 ] && tc_pass_or_fail $? "p11-kit extract --format=pem-directory failed"

	# Restore the configuration
	rm /usr/share/pki/ca-trust-source/cert.p11-kit

	p11-kit extract-trust >$stdout 2>$stderr
	tc_fail_if_bad $? "p11-kit extract-trust failed"

	tc_register     "p11-kit extract --filter=blacklist"

	#Add certificate to blacklist
	cp $TEST_DIR/blacklist.p11-kit /etc/pki/ca-trust/source/blacklist/

	p11-kit extract-trust >$stdout 2>$stderr
	tc_fail_if_bad $? "p11-kit extract-trust failed"	

	#Extract the blacklisted certificates and verify blacklist.p11-kit
	# contents are present in the output
	p11-kit extract --filter=blacklist --format=openssl-bundle --comment --overwrite $TCTMP/result1 >$stdout 2>$stderr
	tc_fail_if_bad $? "p11-kit extract --filter=blacklist failed"

	grep -F -f $TEST_DIR/blacklist.p11-kit.exp $TCTMP/result1 > $TCTMP/file_to_compare
	diff -Naurp $TEST_DIR/blacklist.p11-kit.exp $TCTMP/file_to_compare
	tc_pass_or_fail $? "p11-kit extract --filter=blacklist failed to show $TEST_DIR/cert.p11-kit"
}


#
# test04 
#
function test04()
{
	# Execute the tests from the sources
	
	# Tests from p11-kit/tests/
	pushd $TEST_DIR/p11-kit/tests/ >$stdout 2>$stderr


	for t in `ls test-*`; do
		tc_register	"Test $t"
		./$t &>$stdout 2>$stderr
		if [ $? -eq 0 ]; then
			grep -iq OK $stdout
			if [ $? -eq 0 ]; then
				cat /dev/null > $stderr
				tc_pass
			else
				tc_fail	"Expected OK in stdout"
			fi
		else
			tc_fail	"$t failed with non-zero RC"
		fi
	done

	popd >$stdout 2>$stderr

	# Tests from common/tests
	pushd $TEST_DIR/common/tests >$stdout 2>$stderr

	for t in `ls test-*`; do
		tc_register     "Test $t"
		./$t &>$stdout 2>$stderr
		if [ $? -eq 0 ]; then
			grep -iq OK $stdout
			if [ $? -eq 0 ]; then
				cat /dev/null > $stderr
				tc_pass
			else
				tc_fail	"Expected OK in stdout"
			fi
		else
			tc_fail	"$t failed with non-zero RC"
		fi
	done

	popd >$stdout 2>$stderr

#	# Tests from tools/tests
#	pushd $TEST_DIR/tools/tests/ >$stdout 2>$stderr
#	TESTS=`ls test-*`
#	for t in $TESTS; do
#               tc_register     "Test $t"
#                ./$t &>$stdout 2>$stderr
#		if [ $? -eq 0 ]; then
#			grep -q OK $stdout
#			if [ $? -eq 0 ]; then
#				cat /dev/null > $stderr
#				tc_pass
#			else
#				tc_fail	"Expected OK in stdout"
#			fi
#		else
#			tc_fail	"$t failed with non-zero RC"
#		fi
#       done
#
#	popd >$stdout 2>$stderr

	# Tests from trust/tests
	pushd  $TEST_DIR/trust/tests/.libs/ 
	TESTS="test-base64 test-builder test-index test-module test-oid test-pem test-parser test-persist test-token test-utf8 test-x509"
	
	for t in $TESTS; do
                tc_register     "Test $t"
		if [ $t == "test-token" ]; then
			tc_add_user_or_break || exit
			su - $TC_TEMP_USER -c "cd $TEST_DIR/trust/tests/.libs/; ./test-token" 1>$stdout 2>$stderr
			tc_pass_or_fail $? "Tests for test-token failed"
			tc_del_user_or_break || exit
		else
			./$t &>$stdout 2>$stderr
			if [ $? -eq 0 ]; then
				grep -iq OK $stdout
				if [ $? -eq 0 ]; then
					cat /dev/null > $stderr
					tc_pass
				else
					tc_fail	"Expected OK in stdout"
				fi
			else
				tc_fail	"$t failed with non-zero RC"
			fi
		fi
        done

	popd >$stdout 2>$stderr
}

################################################################################
# main
################################################################################

TST_TOTAL=42

tc_setup

test01
test02
test03
test04
