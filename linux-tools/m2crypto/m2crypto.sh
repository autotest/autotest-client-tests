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
### File :        m2crypto.sh                                                  ##
##
### Description: This testcase tests m2crypto package                          ##
##
### Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
M2CRYPTO_TESTS_DIR="${LTPBIN%/shared}/m2crypto"
OPENSSLCONF=/etc/pki/tls/openssl.cnf
REQUIRED="python rpm openssl awk sed expect"
CAKEY=demoCA/private/cakey.pem
CAREQ=demoCA/careq.pem
CACERT=demoCA/cacert.pem
NEWKEY=demoCA/newkey.pem
NEWREQ=demoCA/newreq.pem
NEWCERT=demoCA/newcert.pem
PASSWD=password
STATE=Karnataka 
CN=localhost   
EMAIL=""

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED

      tc_check_package "m2crypto"
	tc_break_if_bad $? "m2crypto not installed" || return

	[ -f $OPENSSLCONF ]
	tc_break_if_bad $? "No openssl config found" || return
	cp $OPENSSLCONF ${OPENSSLCONF}.bak

	pushd $M2CRYPTO_TESTS_DIR &>/dev/null
	mkdir -p demoCA/private
	mkdir -p demoCA/newcerts
	touch demoCA/index.txt

	### Modify conf file to gen certs in ./demoCA dir ###
	pat1=`grep "# Where everything is kept" $OPENSSLCONF | awk '{print $3}'`
	sed -i "s:$pat1:$M2CRYPTO_TESTS_DIR/demoCA:" $OPENSSLCONF

	echo "Creating new certs..."
	./gen_key_req.exp $CAKEY $CAREQ $PASSWD $STATE $CN >$stdout 2>$stderr 
	tc_break_if_bad $? "Failed to create cakey.pem" || return
	
	./gen_cacert.exp $CACERT $CAKEY $CAREQ $PASSWD >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create cacert.pem" || return
	cp demoCA/cacert.pem tests/ca.pem

	./gen_key_req.exp $NEWKEY $NEWREQ $PASSWD $STATE $CN >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create newkey.pem" || return

	### Generate server certs as req by tests ###
	TMPKEYFILE=$TCTMP/key-file
	./gen_newcert.exp $NEWCERT $NEWREQ $PASSWD >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create server cert" || return
	cp demoCA/newcert.pem tests/server.pem
	expect -c "spawn openssl rsa -in $NEWKEY -out $TMPKEYFILE; expect \"Enter pass phrase*:\"; 
		send \"password\r\"; expect eof " >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create RSA key for server cert" || return 
	cat $TMPKEYFILE >>tests/server.pem

	### Generate x509 certs as req by tests ###
	cp demoCA/newcert.pem tests/x509.pem
	expect -c "spawn openssl rsa -in $NEWKEY -out $TMPKEYFILE; expect \"Enter pass phrase*:\"; 
		send \"password\r\"; expect eof " >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create RSA key for x509 cert" || return
	cat $TMPKEYFILE >>tests/x509.pem
	openssl x509 -in tests/x509.pem -out tests/x509.der -outform DER >$stdout 2>$stderr

	### Generate sender certs as req by tests ###
	EMAIL=signer@example.com
	./gen_key_req.exp $NEWKEY $NEWREQ $PASSWD $STATE $CN $EMAIL >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create sender request key" || return
	./gen_newcert.exp $NEWCERT $NEWREQ $PASSWD >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create sender cert" || return
	cp demoCA/newcert.pem tests/signer.pem
	expect -c "spawn openssl rsa -in $NEWKEY -out tests/signer_key.pem; expect \"Enter pass phrase*:\"; 
		send \"password\r\"; expect eof " >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create RSA key for sender cert" || return

	### Generate recipient certs as req by tests ###
	EMAIL=recipient@example.com
	./gen_key_req.exp $NEWKEY $NEWREQ $PASSWD $STATE $CN $EMAIL >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create recipient request key" || return
	./gen_newcert.exp $NEWCERT $NEWREQ $PASSWD >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create recipient cert" || return
	cp demoCA/newcert.pem tests/recipient.pem
	expect -c "spawn openssl rsa -in $NEWKEY -out tests/recipient_key.pem; expect \"Enter pass phrase*:\"; 
		send \"password\r\"; expect eof " >$stdout 2>$stderr
	tc_break_if_bad $? "Failed to create RSA key for recipient cert" || return

	### Check EC Support ###
	python -c "from M2Crypto import EC" >$stdout 2>$stderr
	[ $? -ne 0 ] && EXCLUDE_EC_TESTS=1
	echo -n >$stderr

	### Fix the Hash Keys in tests ###
	fingerprint=`openssl x509 -hash -fingerprint -in  tests/server.pem | awk -F"=" '/SHA1 Fingerprint/ {print $2}' | \
		awk -F ":" '{out=""; for(i=1; i<=NF; i++){ out=out$i }; print out}'`

	pat2=`grep "expected = " tests/test_x509.py | uniq | awk -F "'" '{print $2}'`
	sed -i "/expected = / s/$pat2/$fingerprint/" tests/test_x509.py

	pat3=`grep peerCertHash tests/test_ssl.py | awk -F "'" '{print $2}'`
	sed -i "/peerCertHash/ s/$pat3/$fingerprint/" tests/test_ssl.py

        sed -i "/import SSL/ s/import SSL/import SSL,Rand/" tests/test_ssl_offline.py   
        pat4=`grep peerCertHash tests/test_ssl_offline.py | awk -F "'" '{print $2}'`
        sed -i "/peerCertHash/ s/$pat4/$fingerprint/" tests/test_ssl_offline.py

	popd &>/dev/null
}

function tc_local_cleanup()
{
	pushd $M2CRYPTO_TESTS_DIR &>/dev/null
	sed -i "/peerCertHash/ s/$fingerprint/$pat3/" tests/test_ssl.py
	sed -i "/expected = / s/$fingerprint/$pat2/" tests/test_x509.py
	sed -i "s:$M2CRYPTO_TESTS_DIR/demoCA:$pat1:" $OPENSSLCONF
        sed -i "/peerCertHash/ s/$fingerprint/$pat4/" tests/test_ssl_offline.py
        sed -i "/import SSL/ s/import SSL,Rand/import SSL/" tests/test_ssl_offline.py 
	mv ${OPENSSLCONF}.bak $OPENSSLCONF
	rm -rf demoCA
	popd &>/dev/null
}

function run_test()
{
	pushd $M2CRYPTO_TESTS_DIR &>/dev/null
	all_tests=`ls tests/test*.py`
	TST_TOTAL=`echo $all_tests | wc -w`
	for test in $all_tests
	do
		tc_register "${test##tests/}"
		if [ ${test##tests/} = test_ssl_win.py ]; then
			tc_info "Skipping the test as it is not supported"
			continue
		fi
		[ $EXCLUDE_EC_TESTS ] && {
			if [[ $test = *test_ec* ]]; then
				tc_info "No EC support. Skip ${test##tests/}"
				continue
			fi
		}
		python $test &>$stdout 
		grep -q OK $stdout
		tc_pass_or_fail $? "${test##tests/} failed"
	done
	popd &>/dev/null
}

#
# main
#
tc_setup && run_test
