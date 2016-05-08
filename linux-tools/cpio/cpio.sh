#!/bin/bash
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
#
# File :        cpio_test.sh
#
# Description:  Test basic functionality of cpio command
#				- Test #1:  cpio -o can create an archive.
#               
# Author:       Manoj Iyer, manjo@mail.utexas.edu
#
#

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source


# Function:	tc_local_setup
#
# Description:	- Invoked from tc_setup.
# 		- Check if command cpio is available.
#               - Create temprary directory, and temporary files.
#               - Initialize environment variables.
#
# Return	- zero on success
#               - non zero on failure. return value from commands ($RC)
tc_local_setup()
{
	
	tc_info "INIT: Inititalizing tests."

	tc_exec_or_break cpio || return

	mkdir -p $TCTMP/tst_cpio.tmp &> $TCTMP/tst_cpio.err || return
	
	for i in a b c d e f g h i j k l m n o p q r s t u v w x y z
	do
		touch $TCTMP/tst_cpio.tmp/$i &> $TCTMP/tst_cpio.err 
	done
}


# Function:	test01
#
# Description	- Test #1: Test that cpio -o will create a cpio archive. 
#
# Return	- zero on success
#               - non zero on failure. return value from commands ($RC)

test01()
{

	tc_register "Test #1: cpio -o: create an archive."

	find  $TCTMP/tst_cpio.tmp/ -type f | cpio -o > $TCTMP/tst_cpio.out \
		2>$TCTMP/tst_cpio.err 
	tc_fail_if_bad $? "creating cpio archive" || return

	if [ -f $TCTMP/tst_cpio.out ]
	then
		type file &>/dev/null || return 0	# don't check this if no file cmd
		file $TCTMP/tst_cpio.out 2>&1 | grep -i "cpio archive" | grep -vq grep
		tc_pass_or_fail $? "bad output, not cpio format." || return
	else
		tc_pass_or_fail $? "cpio file not created." || return
	fi

}

# Function:	main
#
# Description:	- Execute all tests, report results.
#               
# Exit:		- zero on success
# 		- non-zero on failure.

TST_TOTAL=1	# total numner of tests in this file.

tc_setup

test01 	# Test #1

