#!/bin/sh
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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
## name of file	: Makefile						  #
## description	: make(1) description file for acl package tests      	  #
############################################################################################
#
# File :       pam_tests.sh
#
# Description: This program tests basic functionality of PAM authentication
#              and account manangement functions.
#
# Author:      Manoj Iyer  manjo@mail.utexas.edu
################################################################################
# Global definitions.
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/pam
source $LTPBIN/tc_utils.source

function tc_local_setup()
{
	[ -f /etc/pam.d/pam_authuser ] && 
		cp /etc/pam.d/pam_authuser ${TCTMP}/pam.saved &>/dev/null
	cat - >/etc/pam.d/pam_authuser <<-EOF
	auth     required       pam_unix_auth.so
	account  required       pam_unix_acct.so
	EOF
}

function tc_local_cleanup()
{
	rm -f /etc/pam.d/pam_authuser &>/dev/null
	[ -f ${TCTMP}/pam.saved ] && cp ${TCTMP}/pam.saved /etc/pam.d/pam_authuser &>/dev/null
}

################################################################################
# the testcase functions
################################################################################

#
# test01	good authorization with good password
#
function test01()
{
	tc_register	"expect good authorization with good password"

	echo "$TC_TEMP_PASSWD" | ./pam_authuser $TC_TEMP_USER &>$stdout
	tc_pass_or_fail $? "Unexpected response from \"pam_authuser $TC_TEMP_USER\""
}

#
# test02	bad authorization with bad password
#
function test02()
{
	tc_register	"expect bad authorization with bad password"
	tc_exec_or_break grep || return

	echo "bad$TC_TEMP_PASSWD" | ./pam_authuser $TC_TEMP_USER &>$stdout
	grep -q PAM_AUTH_ERR $stdout 2>$stderr
	tc_pass_or_fail $? "Unexpected response from \"pam_authuser $TC_TEMP_USER\""
}

# 
# main
# 
TST_TOTAL=2
tc_setup
tc_root_or_break || exit
tc_add_user_or_break || exit

test01 &&
test02
