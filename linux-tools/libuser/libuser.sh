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
## File :	libuser.sh
##
## Description:	Test the libuser package
##
## Author:	Athira Rajeev <atrajeev@in.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libuser
source $LTPBIN/tc_utils.source
FIVDIR=${LTPBIN%/shared}/libuser/
TESTDIR=${LTPBIN%/shared}/libuser/tests

REQUIRED="lusermod luserdel luseradd lpasswd lnewusers lgroupmod lid lgroupdel lgroupadd lchage"

################################################################################
# the testcase functions
################################################################################

#
# local_setup	installation check
#
function tc_local_setup()
{

	tc_root_or_break || exit 
	tc_exist_or_break /etc/libuser.conf
	tc_break_if_bad $? "libuser.conf file doesnot exists" || return

	tc_exec_or_break $REQUIRED || return
	
	tc_get_os_arch
	
	modulelibs=/usr/lib/libuser
        [ $TC_OS_ARCH = "x86_64" ] || [ $TC_OS_ARCH = "ppc64" ] || [ $TC_OS_ARCH = "s390x" ] || [ $TC_OS_ARCH = "ppc64le" ] \
        && modulelibs=/usr/lib64/libuser

	tc_exist_or_break $modulelibs/libuser_files.so $modulelibs/libuser_ldap.so $modulelibs/libuser_shadow.so 
	tc_break_if_bad $? "libuser is not installed properly" 

}

#
# set_paths
function set_paths()
{
	# Replace the moduledir path to /usr/lib*/libuser
	pushd $FIVDIR &>/dev/null 
	result=`find $FIVDIR -name *.in`
	set $result
        while [ $1 ]; do
		sed -i "s:moduledir = @TOP_BUILDDIR@/modules/.libs:moduledir = $modulelibs:" $1
        	shift
	done

	# Set the path of srcdir to $TESTDIR
	TESTS=`find $TESTDIR -type f -not -name config_test -name *_test -o -name *_test.sh`
	set $TESTS

	while [ $1 ]; do
                # set the path of srcdir to $TESTDIR/tests
                sed -i 's:srcdir=$srcdir/tests:srcdir=$(pwd)/tests:' $1
                shift
        done
	popd &>/dev/null
	sed -i 's:\$(pwd)/apps:/usr/sbin:' $TESTDIR/utils_test >$stdout 2>$stderr
}

#
# test01	libuser tests	
#
function test01()
{
	set_paths

	pushd $FIVDIR &>/dev/null
	TST_TOTAL=`echo $TESTS | wc -w` 
	for test in $TESTS; do
	        tc_register "Test $test"
        	$test 1>$stdout
		RC=$?
		if [ $RC == 77 ];then RC=0;fi
        	tc_pass_or_fail $RC "$test failed"
	done 
	popd &>/dev/null 
}


################################################################################
# main
################################################################################

TST_TOTAL=1

(
	# standard tc_setup
	tc_setup &&
	test01  
)
