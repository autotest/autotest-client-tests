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
### File :        perl-LDAP.sh                                                 ##
##
### Description:  Test for Perl-LDAP                                           ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_LDAP
source $LTPBIN/tc_utils.source
PERL_LDAP_DIR="${LTPBIN%/shared}/perl_LDAP"
PERL_CMD=`which perl`
LDAP=`which slapd`

function tc_local_setup()
{
        tc_exec_or_break $PERL_CMD
        #Edit test.cfg file so the tests can find the executable and know what type of server it is
        sed -i "s:<path to ldap server executable>:$LDAP:g" $PERL_LDAP_DIR/test.cfg
        # Change the port on which openldap listens
        sed -i 's:9009:389:g' $PERL_LDAP_DIR/t/common.pl
        #Testing with package provided schema
        sed -i 's:$SCHEMA_DIR = "":$SCHEMA_DIR = "/etc/openldap/schema":g' $PERL_LDAP_DIR/test.cfg
        #ldbm is not supported in openldap2.4 (http://www.openldap.org/doc/admin24/appendix-changes.html#Obsolete Features Removed From 2.4)
        sed -i 's:# $SLAPD_DB = :$SLAPD_DB = :g' $PERL_LDAP_DIR/test.cfg
        #schemacheck also not supported in openldap 2.4 (http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=518797)
        sed -i 's:# $SCHEMA_CHECK = 0:$SCHEMA_CHECK = 0:g' $PERL_LDAP_DIR/test.cfg
        sed -i 's|SERVER_TYPE = \x27openldap\x27|SERVER_TYPE = \x27openldap2\x27|g' $PERL_LDAP_DIR/test.cfg
}

function run_test()
{
 pushd $PERL_LDAP_DIR >$stdout 2>$stderr
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
