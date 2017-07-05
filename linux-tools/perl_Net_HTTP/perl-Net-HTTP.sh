#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
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
### File :       perl-Net-HTTP.sh                                           ##
##
### Description: Test for perl-Net-HTTP  package                             ##
##
### Author:      Basheer Khadarsabgari<bkhadars@in.ibm.com>                     ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_Net_HTTP
MAPPER_FILE="$LTPBIN/mapper_file"
source $LTPBIN/tc_utils.source
source  $MAPPER_FILE
TESTS_DIR="${LTPBIN%/shared}/perl_Net_HTTP/t"
REQUIRED="perl"
stop_httpd=0
SERVICE_NAME=""

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return 

}

function install_check()
{
        tc_check_package "$PERL_NET_HTTP"
	tc_break_if_bad $? "$PERL_NET_HTTP is not installed"

	grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
        if [ $? -eq 0 ];then  # Start of OS check
                SERVICE_NAME="apache2"
        else
                SERVICE_NAME="httpd"
		tc_install_testdep mod_ssl
        fi


	sed -i  's/www.apache.org/localhost/g' $TESTS_DIR/apache-https.t
	sed -i  's/www.apache.org/localhost/g' $TESTS_DIR/apache.t

	##LIVE_TESTS file is needded for the Execution Testcases
	touch $TESTS_DIR/LIVE_TESTS

	tc_service_status $SERVICE_NAME
	if [ $? -ne 0 ]; then
		tc_service_start_and_wait $SERVICE_NAME
		stop_httpd=1
	fi

}

function tc_local_cleanup()
{
	rm $TESTS_DIR/LIVE_TESTS
	[ $stop_httpd -eq 1 ] && tc_service_stop_and_wait $SERVICE_NAME
}

function run_test()
{
	pushd $TESTS_DIR >$stdout 2>$stderr
	TESTS=`ls *.t`
	TST_TOTAL=`echo $TESTS | wc -w` 
	for test in $TESTS; do
		grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
	        if [ $? -eq 0 ];then  # Start of OS check
			if [ "$test" == "apache.t" ];then
				TST_TOTAL=`expr $TST_TOTAL - 1`
				continue
			fi
		fi
		tc_register "Test $test" 
		perl $test >$stdout 2>$stderr
		RC=$?
		grep -iq "fail" $stderr
		RC1=$?
		if [ $RC -eq 1 ] || [ $RC1 -eq 0 ]
		then
			RC=1
		else
			tc_ignore_warnings "^$\|^*\| Using the default of SSL_verify_mode of SSL_VERIFY_NONE for client\| is deprecated! Please set SSL_verify_mode to SSL_VERIFY_PEER\| together with SSL_ca_file|SSL_ca_path for verification.\| If you really don't want to verify the certificate and keep the\| connection open to Man-In-The-Middle attacks please set\| SSL_verify_mode explicitly to SSL_VERIFY_NONE in your application.\|  at t\/apache-https.t line 36.\|"
		fi
		tc_pass_or_fail $RC "$test failed"
	done
	popd >$stdout 2>$stderr
}

#
# main
#
tc_setup
install_check && run_test 
