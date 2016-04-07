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
## File :	gnutls.sh
##
## Description:	Tests for gnutls package.
##
## Author:	Gowri Shankar <gowrishankar.m@in.ibm.com>
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN="${PWD%%/testcases/*}/testcases/bin"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
installed="certtool gnutls-serv gnutls-cli-debug"
required="echo grep"
port=""
pid=""

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return

	tc_find_port && port=$TC_PORT
	tc_break_if_bad $? "no free port available" || return
}

function tc_local_cleanup()
{
	:
}

#
# test A
#  create self-signed certificate using certtool
#
function test_ca()
{
	tc_register "creating CA"
	local issuer=""
	certtool --generate-privkey > $TCTMP/ca-key.pem 2>$stderr
	tc_fail_if_bad_rc $? "unable to create CA private key" || return

	# common name of certificate owner
	echo 'cn = gnutls CA test' > $TCTMP/ca.tmpl
	# this is a CA certificate
	echo 'ca'                 >> $TCTMP/ca.tmpl
	# this key will be used to sign other certificates
	echo 'cert_signing_key'   >> $TCTMP/ca.tmpl
	# create self-signed CA certificate
	certtool --generate-self-signed \
		 --load-privkey $TCTMP/ca-key.pem \
		 --template $TCTMP/ca.tmpl --outfile $TCTMP/ca-cert.pem \
		   >$stdout 2>$stderr
	tc_fail_if_bad_rc $? "unable to create CA certificate" || return

	# verify certificate information
	certtool --certificate-info \
		 --infile $TCTMP/ca-cert.pem \
		   1>$stdout 2>$stderr
	issuer=$(grep Issuer $stdout | awk -F= '{print $2}')
	[ "$issuer" = "gnutls CA test" ]
	tc_pass_or_fail $? "mismatching issuer name found"
}

#
# test B
#  1. list supported algorithms using gnutls-serv
#  2. start gnutls test server instance
#
function test_server()
{
	tc_register "checking if supported algorithms are listed"
	gnutls-serv -l 1>$stdout 2>$stderr
	tc_pass_or_fail $? "unable to list supported algorithms"

	tc_register "setting up gnutls test server"
	certtool --generate-privkey > $TCTMP/ca-server-key.pem
	# organization of the subject
	echo 'organization = GnuTLS test server' > $TCTMP/ca-server.tmpl
	# common name of certificate owner
	echo 'cn = test.example.com'                >> $TCTMP/ca-server.tmpl
	# this certificate will be used for a TLS server
	echo 'tls_www_server'                   >> $TCTMP/ca-server.tmpl
	# this certificate will be used to encrypt data
	echo 'encryption_key'                   >> $TCTMP/ca-server.tmpl
	# this certificate will be used to sign data
	echo 'signing_key'                      >> $TCTMP/ca-server.tmpl
	# dns name of WWW server
	echo 'dns_name = test.example.com'          >> $TCTMP/ca-server.tmpl
	certtool --generate-certificate \
		 --load-privkey $TCTMP/ca-server-key.pem \
		 --load-ca-certificate $TCTMP/ca-cert.pem \
		 --load-ca-privkey $TCTMP/ca-key.pem \
		 --template $TCTMP/ca-server.tmpl \
		 --outfile $TCTMP/ca-server-cert.pem \
		   &>$stdout
	tc_fail_if_bad $? "unable to generate server side certificate" || return

	# start the server side instance
	gnutls-serv --http \
		    --port $port \
		    --x509cafile $TCTMP/ca-cert.pem \
		    --x509keyfile $TCTMP/ca-server-key.pem \
		    --x509certfile $TCTMP/ca-server-cert.pem \
		      1>$stdout 2>$stderr &
	tc_pass_or_fail $? "unable to start gnutls test server"
	pid=$!
	TC_SLEEPER_PIDS=$pid
}

#
# test C
#  1. list supported algorithms using gnutls-cli
#  2. start gnutls test server instance and check with gnutls debug client
#  3. connect gnutls client tool with server in various ways.
#
function test_client()
{
	tc_register "list supported algorithms/protocols"
	gnutls-cli --list 1>$stdout 2>$stderr
	tc_pass_or_fail $? "unable to list algorithms supported"


	tc_register "checking with gnutls test client (for debugging)"
	tc_info "generating client side certificate"

	certtool --generate-privkey > $TCTMP/ca-client-key.pem
	# organization of the subject
	echo 'organization = GnuTLS test client' > $TCTMP/ca-client.tmpl
	# this certificate will be used for a TLS client
	echo 'tls_www_client'                   >> $TCTMP/ca-client.tmpl
	# this certificate will be used to encrypt data
	echo 'encryption_key'                   >> $TCTMP/ca-client.tmpl
	# this certificate will be used to sign data
	echo 'signing_key'                      >> $TCTMP/ca-client.tmpl
	certtool --generate-certificate \
		 --load-privkey $TCTMP/ca-client-key.pem \
		 --load-ca-certificate $TCTMP/ca-cert.pem \
		 --load-ca-privkey $TCTMP/ca-key.pem \
		 --template $TCTMP/ca-client.tmpl \
		 --outfile $TCTMP/ca-client-cert.pem \
		   &>$stdout
	tc_fail_if_bad $? "unable to generate client side certificate"

	# check if client debug tool can connect the server
	gnutls-cli-debug -p $port localhost 1>$stdout 2>$stderr &
	tc_wait_for_pid $! && tc_pass_or_fail $? "unable to connect gnutls server"


	# tests below verifies the server/client connections.
	# bug 83535 is blocking further checks with gnutls-server.

	# tests below verifies the usecases of gnutls in vnc, lp/cups, libvirtd
	# which will be enhanced later.
}

################################################################################
# main
################################################################################
TST_TOTAL=5
tc_setup

test_ca && test_server
test_ca && test_client
