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
### File :        libcap.sh                                                    ##
##
### Description: This testcase tests libcap package                            ##
##
### Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libcap"
INSTALLED="capsh getcap getpcaps setcap"
REQUIRED="cmp cut grep sed"
TEST=$TESTS_DIR/quicktest.sh

function tc_local_setup()
{
	## First check if capability is supported by kernel ##
	## remove the below check since that will not be set in kernel 3.0.x onwards - http://lwn.net/Articles/363565/
#	tc_check_kconfig "CONFIG_SECURITY_FILE_CAPABILITIES" || return
	
	tc_root_or_break || return
	tc_exec_or_break $INSTALLED || return
	tc_exec_or_break $REQUIRED || return
	test -e /lib*/libcap.so.2   && \
	test -f /lib*/security/pam_cap.so 
	tc_break_if_bad $? "libcap not installed" || return	

	## Copy the utilities to TESTDIR as required by test script ##
	cp `which capsh` $TESTS_DIR && \
	cp `which getpcaps` $TESTS_DIR && \
	cp `which setcap` $TESTS_DIR && \
	cp `which ping` $TCTMP
	tc_break_if_bad $? "Test require copying of ping and libcap utilities..failed" || return

}

function tc_local_cleanup()
{
	rm -f $TESTS_DIR/capsh $TESTS_DIR/getpcaps $TESTS_DIR/setcap 
}

function runtest()
{
	tc_register "Test getcap"
	setcap all=ep $TCTMP/ping >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to set capabilities" || return
	out=`getcap $TCTMP/ping` >$stdout 2>$stderr
	[ `echo $out | cut -d= -f2` = "ep" ]
	tc_pass_or_fail $? "getcap failed"

	pushd $TESTS_DIR &>/dev/null
	tc_register "libcap tests"
	$TEST >$stdout 2>$stderr
	rc=$?
	[ $rc -eq 0 ] && {
	    cmp $stderr stderr_exp && echo -n >$stderr
	}
	tc_pass_or_fail $rc "$TEST failed"
	popd &>/dev/null
}

#
#main
#
TST_TOTAL=2
tc_setup && runtest
