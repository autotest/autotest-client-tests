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
## File :	openssl.sh
##
## Description:	Test openssl package
##
## Author:	Robb Romans <robb@austin.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/openssl
source $LTPBIN/tc_utils.source

OPENSSL_BIN=openssl$BITS

TESTDIR=${LTPBIN%/shared}/openssl/openssl-tests

# global variables
#
#required executables:
REQUIRED="which cat cmp ls $OPENSSL_BIN rm sed"

################################################################################
# testcase functions
################################################################################

# Function:             testenc
#
# Description:          - test ssl encoding functions
#                         adapted from $OPENSSL_BIN 'make test'
#
# Parameters:           - none
#
function testenc() {

	tc_register "testenc_simple"

	local testsrc=openssl.sh
	local test=$TCTMP/p
	local cmd=$OPENSSL_BIN
	local message="Compare failed."

	tc_exist_or_break $testsrc || return
	cat $testsrc >$test;

	$cmd enc < $test > $test.cipher
	$cmd enc < $test.cipher >$test.clear
	cmp $test $test.clear 2>$stderr 1>$stdout
	tc_pass_or_fail $? "$message"
	rm -f $test.cipher $test.clear

	tc_register "testenc_simple_base64"
	$cmd enc -a -e < $test > $test.cipher
	$cmd enc -a -d < $test.cipher >$test.clear
	cmp $test $test.clear 2>$stderr 1>$stdout
	tc_pass_or_fail $? "$message"
	rm -f $test.cipher $test.clear

	for i in `$cmd list-cipher-commands`; do
		tc_register "testenc_$i"
		$cmd $i -bufsize 113 -e -k test < $test > $test.$i.cipher
		$cmd $i -bufsize 157 -d -k test < $test.$i.cipher >$test.$i.clear
		cmp $test $test.$i.clear 2>$stderr 1>$stdout
		tc_pass_or_fail $? "$message"
		rm -f $test.$i.cipher $test.$i.clear

		tc_register "testenc_base64_$i"
		$cmd $i -bufsize 113 -a -e -k test < $test > $test.$i.cipher
		$cmd $i -bufsize 157 -a -d -k test < $test.$i.cipher >$test.$i.clear
		cmp $test $test.$i.clear 2>$stderr 1>$stdout
		tc_pass_or_fail $? "$message"
		rm -f $test.$i.cipher $test.$i.clear
	done
	rm -f $test
}

# Function:		testss
#
# Description:		- test ssl certificate functions
#			  adapted from openssl 'make test'
#
# Parameters:		- 
#
# Return		- zero on success
#
function testss() {
	local digest='-sha1'
	local reqcmd="$OPENSSL_BIN req"
	local x509cmd="$OPENSSL_BIN x509 $digest"
	local verifycmd="$OPENSSL_BIN verify"
	local dummycnf="$TESTDIR/openssl.cnf"

	local CAkey="$TESTDIR/keyCA.ss"
	local CAcert="$TESTDIR/certCA.ss"
	local CAreq="$TESTDIR/reqCA.ss"
	local CAconf="$TESTDIR/CAss.cnf"
	local CAreq2="$TESTDIR/req2CA.ss"	# temp

	local Uconf="$TESTDIR/Uss.cnf"
	local Ukey="$TESTDIR/keyU.ss"
	local Ureq="$TESTDIR/reqU.ss"
	local Ucert="$TESTDIR/certU.ss"

	tc_register "testss_mkcertrec"
	tc_exist_or_break $dummycnf $CAkey $CAcert $CAreq $CAconf $Uconf $Ukey $Ureq $Ucert || return

	tc_info "$TCNAME: make a certificate request using 'req'"
	echo "string to make the random number generator think it has entropy" >> $TCTMP/.rnd

	if $OPENSSL_BIN no-rsa; then
		req_new='-newkey dsa:dsa512.pem'
	else
		req_new='-new'
	fi

	$reqcmd -config $CAconf -out $CAreq -keyout $CAkey $req_new &>$stdout
	tc_pass_or_fail $? "error using 'req' to generate a certificate request"
	
	tc_register "testss_certconvSS509"
	tc_info "convert the certificate request into a self signed certificate \
			 using 'x509'"
	$x509cmd -CAcreateserial -in $CAreq -days 30 -req -out $CAcert -signkey $CAkey &>$stdout
	tc_pass_or_fail $? "error using 'x509' to self sign a certificate request"
	
	tc_register "testss_certconvcertreq"
	tc_info "$TCNAME: convert a certificate into a certificate request using 'x509'"
	$x509cmd -in $CAcert -x509toreq -signkey $CAkey -out $CAreq2 &>$stdout
	tc_pass_or_fail $? "error using 'x509' convert a certificate to a certificate request"
	
	tc_register "testss_gen1streq"
	tc_info "$TCNAME: generating 1st request of certificate"
	$reqcmd -config $dummycnf -verify -in $CAreq -noout &>$stdout
	tc_pass_or_fail $? "first generated request is invalid"
	
	tc_register "testss_gen3rdreq"
	tc_info "$TCNAME: generating 2nd request of certificate"
	$verifycmd -CAfile $CAcert $CAcert &>$stdout
	tc_pass_or_fail $? "first generated cert is invalid"
	
	tc_register "testss_mk2ndcert"
	tc_info "$TCNAME: make another certificate request using 'req'"
	$reqcmd -config $Uconf -out $Ureq -keyout $Ukey $req_new &>$stdout
	tc_pass_or_fail $? "error using 'req' to generate a certificate request"
	
	tc_register "testss_signcert509"
	tc_info "$TCNAME: sign certificate request with the just created CA via 'x509'"
	$x509cmd -CAcreateserial -in $Ureq -days 30 -req -out $Ucert -CA $CAcert -CAkey $CAkey &>$stdout
	tc_pass_or_fail $? "error using 'x509' to sign a certificate request"

	$verifycmd -CAfile $CAcert $Ucert &>/dev/null
	tc_info "Certificate details:"
	tc_info "$($x509cmd -subject -issuer -startdate -enddate -noout -in $Ucert)"

	tc_info "The generated CA certificate is $CAcert"
	tc_info "The generated CA private key is $CAkey"
	tc_info "The generated user certificate is $Ucert"
	tc_info "The generated user private key is $Ukey"

	rm -f $CAreq2
}

# Function:		testssl
#
# Description:		- test ssl functions
#			  adapted from openssl 'make test'
#
# Parameters:		- 
#
# Return		- zero on success
#			- return value from commands on failure
#
function testssl()
{

	local key=$TESTDIR/keyU.ss
	local key2=$TESTDIR/keyU.ss
	local cert=$TESTDIR/certU.ss
	local ssltest="$TESTDIR/ssltest -key $key -cert $cert -c_key $key -c_cert $cert"
	local CA="-CAfile $TESTDIR/certCA.ss"
	local comp_curve="-zlib -named_curve secp384r1"
	local message="ssl test failure - see error report to follow."

	tc_exist_or_break $key $key2 $cert $TESTDIR/ssltest || return

	if $OPENSSL_BIN x509 -in $cert -text -noout | fgrep 'DSA Public Key' >/dev/null; then
		local dsa_cert=YES
	else
		local dsa_cert=NO
	fi

	
	tc_register "testssl_sslv2"
	tc_info "$TCNAME: test sslv2"
	$ssltest $comp_curve -ssl2 &>$stdout
	tc_pass_or_fail $? "$message"

	tc_register "testssl_sslv2sa"
	tc_info "$TCNAME: test sslv2 with server authentication"
	$ssltest $comp_curve -ssl2 -server_auth $CA &>$stdout
	tc_pass_or_fail $? "$message"

	if [ $dsa_cert = NO ]; then
		tc_register "testssl_sslv2ca"
		tc_info "$TCNAME: test sslv2 with client authentication"
		$ssltest $comp_curve -ssl2 -client_auth $CA &>$stdout
		tc_pass_or_fail $? "$message"
	else
		tc_register "testssl_sslv2casa"
		tc_info "$TCNAME: test sslv2 with client and server authentication"
		$ssltest $comp_curve -ssl2 -server_auth -client_auth $CA &>$stdout
		tc_pass_or_fail $? "$message"
	fi

        tc_register "testssl_sslv3"
        tc_info "$TCNAME: test sslv3"
        $ssltest $comp_curve -ssl3 &>$stdout
        tc_pass_or_fail $? "$message"

        tc_register "testssl_sslv3sa"
        tc_info "$TCNAME: test_sslv3 with server authentication"
        $ssltest $comp_curve -ssl3 -server_auth $CA &>$stdout
        tc_pass_or_fail $? "$message"

        tc_register "testssl_sslv3ca"
        tc_info "$TCNAME: test_sslv3 with client authentication"
        $ssltest $comp_curve -ssl3 -client_auth $CA &>$stdout
        tc_pass_or_fail $? "$message"

        tc_register "testssl_sslv3casa"
        tc_info "$TCNAME: test sslv3 with both client and server authentication"
        $ssltest $comp_curve -ssl3 -server_auth -client_auth $CA &>$stdout
        tc_pass_or_fail $? "$message"

        tc_register "testssl_sslv23"
        tc_info "$TCNAME: test sslv2 and sslv3 at once"
        $ssltest  &>$stdout
        tc_pass_or_fail $? "$message"

        tc_register "testssl_sslv23sa"
        tc_info "$TCNAME: test sslv2 and sslv3 with server auth"
        $ssltest -server_auth $CA $comp_curve  &>$stdout
        tc_pass_or_fail $? "$message"

        tc_register "testssl_sslv23ca"
        tc_info "$TCNAME: test sslv2 and sslv3 with client auth"
        $ssltest -client_auth $CA $comp_curve  &>$stdout
        tc_pass_or_fail $? "$message"

        tc_register "testssl_sslv23casa"
        tc_info "$TCNAME: test sslv2 and sslv3 with client/server auth"
        $ssltest -server_auth -client_auth $CA $comp_curve &>$stdout
        tc_pass_or_fail $? "$message"

	tc_register "testssl_sslv2bio"
	tc_info "$TCNAME: test sslv2 via BIO pair"
	$ssltest -bio_pair -ssl2 $comp_curve &>$stdout
	tc_pass_or_fail $? "$message"

	tc_register "testssl_sslv2sabio"
	tc_info "$TCNAME: test sslv2 with server auth via BIO pair"
	$ssltest -bio_pair -ssl2 -server_auth $CA $comp_curve &>$stdout
	tc_pass_or_fail $? "$message"

	if [ $dsa_cert = NO ]; then
		tc_info "Skipping DSA AUTH TEST on this platform"
		
		tc_register "testssl_sslv2cabio"
		tc_info "$TCNAME: test sslv2 with client auth via BIO pair"
		$ssltest -bio_pair -ssl2 -client_auth $CA $comp_curve &>$stdout
		tc_pass_or_fail $? "$message"

		tc_register "testssl_sslv2casabio"
		tc_info "$TCNAME: test sslv2 with client/server auth via BIO pair"
		$ssltest -bio_pair -ssl2 -server_auth -client_auth $CA $comp_curve &>$stdout
		tc_pass_or_fail $? "$message"
	fi

       tc_register "testssl_sslv3bio"
       tc_info "$TCNAME: test sslv3 via BIO pair"
       $ssltest -bio_pair -ssl3 $comp_curve &>$stdout
       tc_pass_or_fail $? "$message"

       tc_register "testssl_sslv3sabio"
       tc_info "$TCNAME: test sslv3 with server authentication via BIO pair"
       $ssltest -bio_pair -ssl3 -server_auth $CA $comp_curve  &>$stdout
       tc_pass_or_fail $? "$message"

       tc_register "testssl_sslv3cabio"
       tc_info "$TCNAME: test sslv3 with client authentication via BIO pair"
       $ssltest -bio_pair -ssl3 -client_auth $CA $comp_curve &>$stdout
       tc_pass_or_fail $? "$message"

       tc_register "testssl_sslv3casabio"
       tc_info "$TCNAME: test sslv3 with client/server authentication via BIO pair"
       $ssltest -bio_pair -ssl3 -server_auth -client_auth $CA  $comp_curve &>$stdout
       tc_pass_or_fail $? "$message"

       if [ $dsa_cert = NO ]; then
                tc_register "testssl_sslv23noDHEbio"
                tc_info "$TCNAME: test sslv2/sslv3 w/o DHE via BIO pair"
                $ssltest -bio_pair -no_dhe  $comp_curve &>$stdout
                tc_pass_or_fail $? "$message"
       fi

       tc_register "testssl_sslv23dhebio"
       tc_info "$TCNAME: test sslv2/sslv3 with 1024bit DHE via BIO pair"
       $ssltest -bio_pair -dhe1024dsa -v &>$stdout
       tc_pass_or_fail $? "$message"

       tc_register "testssl_sslv23sa"
       tc_info "$TCNAME: test sslv2/sslv3 with server authentication"
       $ssltest -bio_pair -server_auth $CA $comp_curve  &>$stdout
       tc_pass_or_fail $? "$message"

       tc_register "testssl_sslv23cabio"
       tc_info "$TCNAME: test sslv2/sslv3 with client authentication via BIO pair"
       $ssltest -bio_pair -client_auth $CA $comp_curve &>$stdout
       tc_pass_or_fail $? "$message"

       tc_register "testssl_sslv23casabio"
       tc_info "$TCNAME: test sslv2/sslv3 with client/server authentication via BIO pair"
       $ssltest -bio_pair -server_auth -client_auth $CA $comp_curve &>$stdout
       tc_pass_or_fail $? "$message"
	
       tc_register "testssl_tls1"
       tc_info "$TCNAME: test tls1 with 1024bit anonymous DH, multiple handshakes"
       $ssltest -v -bio_pair -tls1 -cipher ADH -dhe1024dsa -num 10 -f -time $comp_curve &>$stdout
       tc_pass_or_fail $? "$message"
}

####################################################################################
# MAIN
####################################################################################

# Function:	main
#
# Description:	- Execute all tests, report results
#
# Exit:		- zero on success
#		- or number of failed tests
#
tc_setup
tc_exec_or_break $REQUIRED || exit

testenc &&
testss &&
testssl
