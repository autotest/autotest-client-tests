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
## File :	sh-utils.sg
##
## Description:	Test the functions provided by sh-utils.
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
REQUIRED="tar date"

################################################################################
# the testcase function
################################################################################


function tc_local_setup()
{
        tc_exec_or_break $REQUIRED
	#in ppcnf fails complaining timestamp is in future,sequoia boards doesnot have hardware clock.
	#Changing the test to just set a date far into the future, just before the Jan 19, 2038 date 
	#that's the 32-bit limit of seconds for Linux.
	tc_get_os_arch 
	if [ "$TC_OS_ARCH" = "ppcnf" ]; then
		currentdate=`date +%d\ %b\ %Y\ %T`
		date -s "1 JAN 2038 8:00:00"
        fi
	
}

function tc_local_cleanup()
{
      if [ -z $currentdate ]; then
	     date -s "$currentdate"
      fi
}
#
# test01	installation check
#
function test01()
{
	tc_register "is tar installed?"
	tc_executes tar
	tc_pass_or_fail $? "tar not installed"
}

#
# test02	tar/untar w/o compression
#
function test02()
{
	tc_register "tar/untar w/o compression"

	# create a small directory structure to tar up
	mkdir $TCTMP/tarme
	echo "Hello" > $TCTMP/tarme/hello.txt
	echo "Goodbye" > $TCTMP/tarme/goodbye.txt
	mkdir $TCTMP/tarme/subdir
	echo "White Rabbit" > $TCTMP/tarme/subdir/rabbit

	# tar without compression
	tar cf $TCTMP/tarme.tar -C $TCTMP tarme 2>$stderr
	tc_fail_if_bad $? "bad response from tar cf" || return

	# untar without compression
	mkdir $TCTMP/untar
	tar xf $TCTMP/tarme.tar -C $TCTMP/untar 2>$stderr
	tc_fail_if_bad $? "bad response from tar xf" || return

	# compare results
	diff -r $TCTMP/untar/tarme $TCTMP/tarme >$stderr 2>$stdout
	tc_pass_or_fail $? "bad results from diff of uncompressed tar"
}

#
# test03	tar/untar with -z compression
#
function test03()
{
	tc_register "tar/untar with -z compression"

	# busybox tar does not support compression
	if tc_is_busybox tar ; then
		tc_info "Skipped test of compression since"
		tc_info "it is not supported by busybox."
		cat /dev/null > $stderr
		tc_pass_or_fail 0 ""
		return
	fi
	# tar using "z" compression
	tar zcf $TCTMP/tarme.tar.gz -C $TCTMP tarme 2>$stderr
	tc_fail_if_bad $? "bad response from tar zcf" || return

	# untar using "z" compression
	mkdir $TCTMP/untarz
	tar zxf $TCTMP/tarme.tar.gz -C $TCTMP/untarz 2>$stderr
	tc_fail_if_bad $? "bad response from tar zxf" || return

	# compare results
	diff -r $TCTMP/untarz/tarme $TCTMP/tarme >$stdout 2>$stderr
	tc_pass_or_fail  $? "bad results from diff of z compressed tar"
}

#
# test04	tar/untar with -j compression
#
function test04()
{
	tc_register "tar/untar with -j compression"

	# busybox tar does not support compression
	if tc_is_busybox tar ; then
		tc_info "Skipped test of compression since"
		tc_info "it is not supported by busybox."
		cat /dev/null > $stderr
		tc_pass_or_fail 0 ""
		return
	fi

	# tar using "j" compression
	tar jcf $TCTMP/tarme.tar.bz2 -C $TCTMP tarme 2>$stderr
	tc_fail_if_bad $? "bad response from tar jcf" || return

	# untar using "j" compression
	mkdir $TCTMP/untarj
	tar jxf $TCTMP/tarme.tar.bz2 -C $TCTMP/untarj 2>$stderr
	tc_fail_if_bad $? "bad response from tar jxf" || return

	# compare results:
	diff -r $TCTMP/untarz/tarme $TCTMP/tarme >$stdout 2>$stderr
	tc_pass_or_fail $? "bad results from diff of j compressed tar"
}

################################################################################
# main
################################################################################

TST_TOTAL=4
tc_setup

tc_exec_or_break mkdir echo diff || exit

test01 || exit
test02 || exit
test03
test04
