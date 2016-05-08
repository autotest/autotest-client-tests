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
## File :       tcpd_tests.sh
##
## Description: This program tests basic functionality of tcpd (tcp wrappers)
##
## Author:      Manoj Iyer  manjo@mail.utexas.edu
###########################################################################################

SSH_SUCCESS=0      # pam authentication success
TCLUSE_ERR=1       # expect program usage error
TIME_OUT=2         # expect did not send passwd, timed out.
SPAWN_ERR=3        # expect failed to spawn pam_authuser program

# array contains the error messages indexed by error type 
# retuned by the pam_loguser.tcl program.
errmsg[SSH_SUCCESS]="ssh to user $(whoami) success"
errmsg[TCLUSE_ERR]="expect program (do_ssh.tcl) usage error"
errmsg[TIME_OUT]="ssh $(whoami)@localhost refused connection."
errmsg[SPAWN_ERR]="expect failed to spawn ssh program"


# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
testdir=${LTPBIN%/shared}/tcp_wrappers

# test setup functions
tc_local_setup() {

	touch /etc/hosts.deny
	mv /etc/hosts.deny $TCTMP
}

tc_local_cleanup() {

	if [ -f $TCTMP/hosts.deny ] ; then
		mv $TCTMP/hosts.deny /etc
	fi
}

#
# Function: test01
#
# Description: This testcase tests the basic functionality of tcpd
#              - deny ssh access to ALL add sshd : ALL to hosts.deny
#              - call utility that does ssh, this should fail
#              - remove from deny list, the entry  sshd : ALL 
#              - utility should return authentication success.
# 
# Inputs:      NONE
#
# Exit:        0        - on success.
#              non-zero - on failure.
#
test01()
{

	tc_register "tcpd deny for $1"

	# modify hosts.deny file to add ssh
	echo "sshd : ALL" > /etc/hosts.deny 
	# call utility to ssh to $(whoami)@localhost
	$testdir/do_ssh.tcl $(whoami)@localhost ~. >$stdout 2>$stderr

	[ $? -eq 2 ] 
	tc_pass_or_fail $? ${errmsg[$?]}		
}

# Disable PublicKey Authentication in do_ssh.tcl,
# Here actual password is trivial
test02()
{
	tc_register "tcpd allow for $1"

	# comment out the deny entry
	echo "#sshd : ALL" > /etc/hosts.deny 
	tc_wait_for_file_text /etc/hosts.deny "\#sshd" 3
    
	$testdir/do_ssh.tcl $(whoami)@localhost ~. >$stdout 2>$stderr
	tc_pass_or_fail $? ${errmsg[$?]}		
}


# Function: main
# 
# Description: - call setup function.
#              - execute each test.
#
# Inputs:      NONE
#
# Exit:        zero - success
#              non_zero - failure
#
TST_TOTAL=2
tc_setup
tc_root_or_break || exit
tc_exec_or_break cp ssh expect whoami || exit

test01 ipv4
test02 ipv4

tc_ipv6_info || exit
[ "$TC_IPV6_host_ADDRS" ] || exit
tc_info "BEGIN IPv6 host scope TESTS"
((TST_TOTAL+=2))
localhost=$TC_IPV6_host_ADDRS
test01 ipv6-host &&
test02 ipv6-host

[ "$TC_IPV6_global_ADDRS" ] || exit
tc_info "BEGIN IPv6 global scope TESTS"
localhost=$TC_IPV6_global_ADDRS
((TST_TOTAL+=2))
test01 ipv6-global &&
test02 ipv6-global
