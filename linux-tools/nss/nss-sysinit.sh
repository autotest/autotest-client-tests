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
## File :	nss-sysinit.sh
##
## Description:	Tests for nss-sysinit package.
##
## Author:	Gowri Shankar <gowrishankar.m@in.ibm.com>
###########################################################################################
## source the utility functions

#######cd $(dirname $0)
#LTPBIN="${LTPBIN%/shared}/nss"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
installed="setup-nsssysinit.sh"
required="egrep"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return
}

#
#  run tests for nss-sysinit
#
function test_nss_sysinit()
{
	tc_register "setup-nsssysinit.sh status"
	setup-nsssysinit.sh status >$stdout 2>$stderr
	egrep -qr 'NSS sysinit is .*bled' $stdout
	tc_pass_or_fail $? "failed to get status"

	tc_register "setup-nsssysinit.sh on"
	status="disabled"
	setup-nsssysinit.sh status |egrep -qr 'enabled' &&\
		status="enabled" && setup-nsssysinit.sh off

	setup-nsssysinit.sh on
	setup-nsssysinit.sh status >$stdout 2>$stderr
	egrep -qr 'NSS sysinit is enabled' $stdout
	tc_pass_or_fail $? "failed to enable nss sysinit"

	[ $status = "disabled" ] && setup-nsssysinit.sh off
}

################################################################################
# main
################################################################################
TST_TOTAL=2
tc_setup
test_nss_sysinit
