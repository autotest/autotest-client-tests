#!/bin/bash
############################################################################################
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
## File : libdrm.sh                                                           ##
##                                                                            ##
## Description: This testcase tests the libdrm package                        ##
##                                                                            ##
## Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
##                                                                            ##
################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libdrm
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libdrm/tests"

function tc_local_setup()
{
	# check installation and environment 
	set `find /usr/lib* -name libdrm\* `
	[ -f $1 ] &&  tc_break_if_bad $? "libdrm not properly installed"
	tc_get_os_arch
	if [ "$TC_OS_ARCH" = "x86_64" -o "$TC_OS_ARCH" = "i686" ];then
		drm_msg="failed to open intel drm device"
	else
		drm_msg="failed to open any drm device"
	fi

}


function run_test()
{
	pushd $TESTS_DIR &>/dev/null
        TST_TOTAL=`ls | wc -w`
        TESTS=`ls`
	for test in $TESTS
	  do
	    tc_register "Test $test"
	    ./$test >$stdout 2>$stderr
	    RC=$?
	    grep -q "$drm_msg" $stderr && tc_ignore_warnings "$drm_msg" && tc_conf "Skipping this test as \
there is no drm device" && continue
	    tc_pass_or_fail $RC "Test $test failed"
	  done
	popd &>/dev/null
}

#
# main
#
tc_setup
run_test 
