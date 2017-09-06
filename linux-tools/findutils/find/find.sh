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
## File :	find.sh
##
## Description:	This is a test kit to test linux command find
##
## Author:	Helen Pang, hpang@us.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/findutils
source $LTPBIN/tc_utils.source

###############################################################################
#
# utility functions specific to this testcase
###############################################################################
#

################################################################################
# the testcase functions
################################################################################

#
# test01    find (check name)
#
function test01()
{
	tc_register "\"find $TCTMP -name name\" check name"

	tc_exec_or_break echo touch || return

	name=test1_1
	touch $TCTMP/$name
	find $TCTMP -name $name >$stdout 2>$stderr
	tc_pass_or_fail $? "Unexpected Name check fail"
}

#
# test02	find (check name with wild card)
#
function test02()
{
	tc_register "\"find $TCTMP -name name\" check name with wild card"

	tc_exec_or_break echo touch grep || return 

	name="t*"
	s1=$TCTMP/tea
	s2=$TCTMP/team
	s3=$TCTMP/two
	touch $s1
	touch $s2
	touch $s3
	find $TCTMP -name "$name" >$stdout 2>$stderr
	grep $s1 $stdout >/dev/null
	tc_fail_if_bad $? "Unexpected no $s1 check out" || return
	grep $s2 $stdout >/dev/null
	tc_fail_if_bad $? "Unexpected no $s2 check out" || return
	grep $s3 $stdout >/dev/null
	tc_fail_if_bad $? "Unexpected no $s3 check out" || return
	
	tc_pass_or_fail 0 "Will never fail here to check name w/ wide card"
}

#
# test03	find (check newer that yield true))

function test03()
{
	tc_register "\"find $TCTMP -newer $compare\" check newer"

	tc_exec_or_break  touch sleep || return 

	name=$TCTMP/test3_1
	compare=$TCTMP/test3_2
	touch $compare
	sleep 1
	touch $name
	find $TCTMP -newer $compare >$stdout 2>$stderr
	grep $name $stdout > /dev/null
	tc_pass_or_fail $? "Unexpected check newer fail."
}


#
# test04    find (check -perm with chmod syntax)
#
function test04()
{
	tc_register "\"find $TCTMP -perm -$mode \" check -perm with chmod syntex"

	tc_exec_or_break  touch chmod || return 

	name=$TCTMP/test4_1
	mode=u+wrx
	touch $name
	chmod $mode $name
	find $TCTMP -perm -$mode >$stdout 2>$stderr
	grep $name $stdout >/dev/null
	tc_pass_or_fail $? "Unexpected check perm with chmod syntex fail"
}

#
# test05    find (check -perm with octal syntax)
#
function test05()
{
	tc_register "\"find $TCTMP -perm -$mode \" check -perm with chmod syntex"

	tc_exec_or_break touch chmod || return 

	name=$TCTMP/test5_1
	mode=644
	touch $name
	chmod $mode $name
	find $TCTMP -perm -$mode >$stdout 2>$stderr
	grep $name $stdout >/dev/null
	tc_pass_or_fail $? "Unexpected check perm w/ octal syntex fail."
}

#
# test06    find (check regular expression)
#
function test06()
{
	tc_register "\"find $TCTMP -regex $rexp\" check regular expression"

	tc_exec_or_break  touch || return 

	name=$TCTMP/fubar3
	rexp=".*b.*3"
	touch $name
	find $TCTMP -regex "$rexp" >$stdout 2>$stderr
	grep $name $stdout >/dev/null
	tc_fail_if_bad $? "Expect check regular expression pass" || return
	
	rexp="*bar."
	find $TCTMP -regex "$rexp" >$stdout 2>$stderr
	cc=`cat $stdout | wc -c`
	[ $cc == 0 ]
	tc_pass_or_fail $? "check regular expression no pass w/ wrong regex" 
}

#
# test07     find  (check anewer expression)
#
function test07()
{
	tc_register "\"find $TCTMP -anewer $compare\" check anewer"
	tc_exec_or_break touch sleep cat || return 

	name=$TCTMP/test7_1
	compare=$TCTMP/test7_2
	touch $compare
	sleep 1
	touch $name
	sleep 1
	cat $compare
	cat $name
	
	find $TCTMP -anewer $compare >$stdout 2>$stderr
	grep $name $stdout >/dev/null
	tc_pass_or_fail $? "Expect check anewer pass" 
}

################################################################################
# main
################################################################################

TST_TOTAL=7
# standard tc_setup
tc_setup

test01
test02
test03
test04
test05
test06
test07
