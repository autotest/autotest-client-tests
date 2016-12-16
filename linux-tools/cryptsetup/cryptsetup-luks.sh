#!/bin/sh
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##      1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##      2.Redistributions in binary form must reproduce the above copyright notice, this  ##
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
### File :        cryptsetup-luks.sh                                           ##
##
### Description: This testcase tests cryptsetup-luks and libs package          ##
##
### Author: Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/cryptsetup
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/cryptsetup/tests"
required="cryptsetup which"
BIN_DIR="${TESTS_DIR%tests}src"

function tc_local_setup()
{
	# check installation and environment 
	tc_root_or_break || return
	tc_exec_or_break $required || return 

	if [[ -a /lib*/libcryptsetup.so.1 ]];then
		tc_break_if_bad $? "lib not installed properly" || return
	fi

	mkdir $BIN_DIR
	ln -s `which cryptsetup` $BIN_DIR
	ln -s `which cryptsetup-reencrypt` $BIN_DIR
	ln -s `which veritysetup` $BIN_DIR
	sed -i 's/grep scsi_debug/grep -H scsi_debug/' $TESTS_DIR/align-test \
	$TESTS_DIR/discards-test $TESTS_DIR/reencryption-compat-test
}

function tc_local_cleanup()
{
	rm -rf $BIN_DIR

}

function run_test()
{
	pushd $TESTS_DIR &>/dev/null
	TESTS=`ls *-test`
	TST_TOTAL=`echo $TESTS | wc -w`
	
	for test in $TESTS; do
		tc_register "Test $test"
		if [ $test = api-test ]; then
			./$test &>$stdout 
		else
			./$test >$stdout 2>$stderr
		fi
		RC=$?
		[ $test = "reencryption-compat-test" ] && tc_ignore_warnings "device-mapper: remove ioctl on reenc9768 failed: Device or resource busy"
		[ $test = "verity-compat-test" ] && tc_ignore_warnings "device-mapper: remove ioctl on verity3273 failed: Device or resource busy"
		tc_fail_if_bad $RC "Test $test fail" || continue
		rv=`grep "test skipped." $stdout`	
		if [[ ! -z $rv ]]; then
			tc_conf "$test skipped. Check stdout" 
			continue
		fi
		tc_pass 0
	done
	popd &>/dev/null
}

#
# main
#
tc_setup
tc_run_me_only_once #run cryptsetup for only once
run_test 
