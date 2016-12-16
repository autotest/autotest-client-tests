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
## File :	xargs.sh
##
## Description:	This is a test kit to test linux command xargs
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

function tc_local_cleanup()
{
	rm test_worker.sh &> /dev/null  # used in test03()
}

################################################################################
# the testcase functions
################################################################################

#
# test01	xargs (set/check max args)
#
function test01()
{
	tc_register "set/check max args"

	tc_exec_or_break  touch ls || return
	
	# set max args(num) for xargs
	name=$TCTMP/file
	touch $name
	ls $TCTMP >$name
	num=3
	xargs -n $num <$name >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected result"
	# check max args(num) for xargs
	nlc=$(wc -l <$name)
	slc=$(wc -l <$stdout)
	# $slc == ceil(nlc / $num) ?
	[ $slc -eq $(( ( $nlc + $num - 1 ) / $num )) ]
	tc_pass_or_fail $? " failed to set max numbers of args in xargs"
}

#
# test02       xargs  (set/check interactive)
#
function test02()  # this test is skipped now
{
	tc_register "set/check interactive"
	tc_exec_or_break  touch ls yes || return 
	
	# set/check interactive for xargs
	name=$TCTMP/file
	touch $name
	ls $TCTMP/* > $name
	xargs -p < $name
	tc_pass_or_fail $? "failed to check xargs's interactive in xargs"
}

#
# test03	xargs (set/check max processes) 
#
function test03()
{
	tc_register "set/check max processes (arg: -P)"
	tc_exec_or_break  touch ls || return

	# In order to check the function of sub-processes, this test
	# will let xargs launch workers to copy files from one
	# directory to another, 3 files at a time (by using xargs
	# -P). The sub-process will sleep after copying files and the
	# count of "sleeping workers" are to be checked to see if 3
	# sub-processes are forked.

	# prepare source directory and files
	dir_name=$TCTMP/fiv.xargs.test
	rm $dir_name -rf &> /dev/null
	mkdir -p $dir_name
	echo "1" > $dir_name/file_one
	echo "2" > $dir_name/file_two
	echo "3" > $dir_name/file_three

	# prepare destination directory
	dst_dir_name=$TCTMP/fiv.xargs.test.dst
	rm $dst_dir_name -rf &> /dev/null
	mkdir $dst_dir_name

	# prepare default value
	sleep_time=5
	num=3

	# generate worker script
	cat > test_worker.sh <<EOF
cp \$1 $dst_dir_name/
sleep $sleep_time
EOF
	chmod +x test_worker.sh

	# work
	echo $dir_name/* | xargs -P $num -n 1 ./test_worker.sh >$stdout 2>$stderr &
	wait_me=$!
	sleep 1 # let xargs start all sub-processes
	
	# check the number of sleeping processes
	sleep_process_count=$((`ps -ef | grep -v grep | grep "test_worker.sh" | wc -l` - 1 ))
	tc_info "the count of sub-processes is $sleep_process_count."
	[ $sleep_process_count -eq $num ] && (diff $dir_name $dst_dir_name >$stdout 2>$stderr)
	tc_pass_or_fail $? " count of sub-processes error or file copy error"

	# clean up
	tc_info "wait for all workers to stop"
	wait $wait_me
}

#
# test04	xargs (set/check max lines)
#
function test04()
{
	tc_register "set/check max lines"

	tc_exec_or_break  touch ls || return 
	
	# set max number lines for xargs
	name=$TCTMP/file
	touch $name
	ls $TCTMP >$name
	xargs -l <$name >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected result"
	# check max number lines for xargs
	nlc=$(wc -l <$name)
	slc=$(wc -l <$stdout)
	[ $slc -eq $nlc ]
	tc_pass_or_fail $? " failed to set max numbers of lines in xargs"
}

#
# test05       xargs (set/check NULL(-0) option)
#
function test05()
{
	tc_register "set/check NULL"

	tc_exec_or_break  touch ls || return 

	# set NULL for xargs
	name=$TCTMP/file
	touch $name
	ls $TCTMP >$name
	xargs -0 <$name >$stdout 2>$stderr
	tc_fail_if_bad $? "Unexpected result"
	# check NULL for xargs
	nlc=$(wc -l <$name)
	slc=$(wc -l <$stdout)
	[ $slc -eq $(( $nlc + 1 )) ]
	tc_pass_or_fail $? " failed to set NULL in xargs"
}

################################################################################
# main
################################################################################

TST_TOTAL=4

# standard tc_setup
tc_setup

test01
# test02	can't run interactive tests!
test03
test04
test05
