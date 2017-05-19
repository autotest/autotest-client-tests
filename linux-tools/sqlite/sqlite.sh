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
## File :	sqlite.sh
##
## Description:	Verify sqlite3 operations
##
## Author:	Shruti Bhat , shruti.bhat@in.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/sqlite
source $LTPBIN/tc_utils.source
test_dir=${LTPBIN%/shared}/sqlite/test_files
test_dir1=${LTPBIN%/shared}
cp $test_dir/c_sqlite3  $LTPBIN

################################################################################
# the testcase functions
################################################################################


function test01()
{
	tc_register "Sqlite3 Insert commands test"
        sqlite3 < $test_dir/insert > $TCTMP/test01.out 2>$stderr
	tc_fail_if_bad $? "Unexpected response from sqlite3 command" || return
	diff $TCTMP/test01.out $test_dir/sample01
	tc_pass_or_fail $? "Unexpected output" || return
}


function test02()
{
	tc_register "Sqlite3 log, date and trigger test"
        sqlite3 < $test_dir/log_date_trigger > $TCTMP/test02.out 2>$stderr
	tc_fail_if_bad $? "Unexpected response from sqlite3 command" || return
	$test_dir/sample02.sh > $test_dir/sample02
	diff -I'^[1-2]|UPDATE' $TCTMP/test02.out $test_dir/sample02
	tc_pass_or_fail $? "Unexpected output" || return
}


function test03()
{
	tc_register "Sqlite3 pivot and attach test"
	cp $test_dir/sample03 $test_dir/sample03.backup
	sed -i "s:testdir:$test_dir1:g" $test_dir/sample03
        $test_dir/runpivot.sh > $TCTMP/test03.out 2>$stderr
	tc_fail_if_bad $? "Unexpected response from sqlite3 command" || return
	diff $TCTMP/test03.out $test_dir/sample03 
	tc_pass_or_fail $? "Unexpected output" || return
	mv  $test_dir/sample03.backup $test_dir/sample03
}

function test04()
{
	tc_register "Sqlite3 libsqlite3.so test with c program"
        $test_dir/runctest.sh > $TCTMP/test04.out 2>$stderr
	tc_fail_if_bad $? "Unexpected response from sqlite3 command" || return
	diff $TCTMP/test04.out $test_dir/sample04
	tc_pass_or_fail $? "Unexpected output" || return
}

##############################################################################
# main
################################################################################

TST_TOTAL=4
tc_setup			# standard tc_setup

test01 
test02 
test03 
test04
