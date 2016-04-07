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
## File :	star.sh
##
## Description:	Test the functions provided by star.
##
## Author:	Liu Deyan, liudeyan@cn.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

IMAGE=${LTPBIN%/shared}/star/test/image
MNT=${LTPBIN%/shared}/star/test/mnt
OUTPUT="star: 1 blocks + 0 bytes (total of 10240 bytes = 10.00k)"
OUTPUT1=${LTPBIN%/shared}/star/test/output1
OUTPUT2=${LTPBIN%/shared}/star/test/output2

################################################################################
# utility functions
################################################################################

function tc_local_setup()
{
	if [ -d $MNT ]; then
		mount -o loop,user_xattr,acl $IMAGE $MNT
	else
		mkdir $MNT
		mount -o loop,user_xattr,acl $IMAGE $MNT
	fi
	
	cd $MNT
	touch f
 	setfattr -n user.name -v value f
	setfattr -n user.name2 -v value2 f
	setfacl -m u:bin:rw f	
}

function tc_local_cleanup()
{
	rm * -rf
	cd ..
	umount $MNT

}

################################################################################
# the testcase function
################################################################################

#
# test01 Create a file with extended attributes. Archive the file with and
# without extended attributes. 
#
function test01()
{
	tc_register "star - Archive the file with and without extended attributes."
	star -c H=exustar -silent f > f-no.pax 2>$stdout 
	star -c H=exustar -xattr -silent f > f-xattr.pax 2>>$stdout 
	star -c H=exustar -acl -silent f > f-acl.pax 2>>$stdout 
	star -c H=exustar -xattr -acl -silent f > f-all.pax 2>>$stdout 
	
	rm f

	set `cat $stdout | grep "$OUTPUT" | wc -l`
	[ $1 -eq 4 ]
	tc_pass_or_fail $? "star with and without extended attributes."
}

#
# test02  	No extended attributes were archived without the -xattr option.	
#
function test02()
{
	tc_register "star - without -xattr option"

	star -x -xattr -acl -silent < f-no.pax 2>$stdout
	getfattr -m- -d f >>$stdout 2>$stderr
	rm f
	
	
	num1=`cat $stdout| grep "$OUTPUT" | wc -l`
	
	set `wc -l $stdout`
	
	cat $stdout | grep "security.selinux" >/dev/null
	if [ $? -eq 0 ];then
		num2=$(($1-3))    # subtracting those line counts which are result of SELINUX
	else
		num2=$1
	fi
	[ $num1 -eq $num2 ]
	tc_pass_or_fail $? "star without -xattr option"
}

#
# test03	Make sure only xattr were archived with the -xattr option	
#
function test03()
{
	tc_register "star - with -xattr option"

	star -x -xattr -acl -silent < f-xattr.pax 2>$stdout 
	cat $stdout|grep "$OUTPUT" >/dev/null
	tc_fail_if_bad $? "star with -xattr option" || return

	#getfattr -m- -d f >$stdout 2>$stderr
	getfattr -m- -d f | grep -v "security.selinux" >$stdout 2>$stderr
	rm f

	diff $stdout $OUTPUT1

	tc_pass_or_fail  $? "bad results from diff of z compressed tar"
}

#
# test04	star with -acl option
#
function test04()
{
	tc_register "star - archived with -acl option"

	star -x -xattr -acl -silent < f-acl.pax 2>$stdout 
	cat $stdout | grep "$OUTPUT" >/dev/null
	tc_fail_if_bad $? "star - archived with -acl option" || return

	#getfattr -m- -d f>$stdout 2>$stderr
	getfattr -m- -d f | grep -v "security.selinux" >$stdout 2>$stderr
	rm f
	
	diff $stdout $OUTPUT2
	
	tc_pass_or_fail $? "star archived with -acl option"
}

function test05()
{
	tc_register "star - without any options"

	star -x -silent < f-all.pax 2>$stdout 
	getfattr -m- -d f >>$stdout 2>$stderr
	rm f

	num1=`cat $stdout| grep "$OUTPUT" | wc -l`
	set `wc -l $stdout`

	cat $stdout | grep "security.selinux" >/dev/null
	if [ $? -eq 0 ];then
		num2=$(($1-3))    # subtracting those line counts which are result of SELINUX
	else
		num2=$1
	fi
	
	[ $num1 -eq $num2 ]
	tc_pass_or_fail $? "star without any option"
	
}

function test06()
{
	tc_register "star - with -xattr option"

	star -x -xattr -silent < f-all.pax 2>$stdout
	cat $stdout | grep "$OUTPUT" >/dev/null
	tc_fail_if_bad $? "star - with -xattr option" || return

	#getfattr -m- -d f >$stdout 2>$stderr
	getfattr -m- -d f | grep -v "security.selinux" >$stdout 2>$stderr
	rm f
	
	diff $stdout $OUTPUT1
	
	tc_pass_or_fail $? "star - with -xattr option"
}

function test07()
{
	tc_register "star - extracted with -acl option"

	star -x -acl -silent < f-all.pax 2>$stdout 
	cat $stdout | grep "$OUTPUT">/dev/null
	tc_fail_if_bad $? "star - with -acl option" || return

	#getfattr -m- -d f>$stdout 2>$stderr
	getfattr -m- -d f | grep -v "security.selinux" >$stdout 2>$stderr
	rm f
	
	diff $stdout $OUTPUT2
	
	tc_pass_or_fail $? "star extracted with -acl option"
}


################################################################################
# main
################################################################################

TST_TOTAL=7
tc_setup


test01 
test02 
test03
test04
test05
test06
test07
