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
### File : patchutils.sh                                                       ##
##
### Description: This testcase tests the patchutils package                    ##
##
### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/patchutils
source $LTPBIN/tc_utils.source
PATCHUTILS_TESTS_DIR="${LTPBIN%/shared}/patchutils"
grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
if [ $? -eq 0 ];then  # Start of OS check
	REQUIRED="sed awk interdiff combinediff filterdiff fixcvsdiff lsdiff splitdiff rediff \
		grepdiff recountdiff unwrapdiff dehtmldiff flipdiff editdiff"
else
	REQUIRED="sed awk interdiff combinediff filterdiff fixcvsdiff lsdiff splitdiff rediff \
                grepdiff recountdiff unwrapdiff dehtmldiff espdiff flipdiff editdiff"
fi



function tc_local_setup()
{
        tc_check_package "patchutils"
	tc_break_if_bad $? "patchutils not installed" || return
	tc_exec_or_break $REQUIRED
	sed -i 's:${top_builddir}/src/::g' $PATCHUTILS_TESTS_DIR/tests/common.sh
	sed -i 's:${top_builddir}/::g' $PATCHUTILS_TESTS_DIR/tests/common.sh
}

function tc_local_cleanup()
{
	rm -f $PATCHUTILS_TESTS_DIR/test.patch.part001
	rm -f $PATCHUTILS_TESTS_DIR/test.patch.part002
	rm -f $PATCHUTILS_TESTS_DIR/test.patch
	rm -f $PATCHUTILS_TESTS_DIR/fixcvsdiff.test*
}

## Test Function ##
function run_test()
{
pushd $PATCHUTILS_TESTS_DIR >$stdout 2>$stderr
grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
if [ $? -eq 0 ];then  # Start of OS check
	TST_TOTAL=`expr $TST_TOTAL - 1`
else
	TST_TOTAL=`ls tests -I common.sh -I soak-test | wc -l`
fi
for dir in `cd tests; find . -mindepth 1 -type d -not -name delhunk5  -not -name delhunk6`
do
	test_name=`echo $dir | awk -F/ '{print $2}'`
	tc_register "Test $test_name"
	$PATCHUTILS_TESTS_DIR/tests/$dir/run-test >$stdout 2>$stderr
	tc_pass_or_fail $? "Test $test_name Failed"
done

tc_register "Test splitdiff"
#Make incremental changes to a single file as two diffs and put in a patch file 
#Later split the file by splitdiff. It will list the two files as *part001 and *part002
cat <<-EOF> test.patch
--- testfile.org	2013-01-15 02:37:31.000000000 -0500
+++ testfile	2013-01-15 02:37:42.000000000 -0500
@@ -1 +1,2 @@
 splitdiff testfile
+PATCH_ONE

--- testfile.org	2013-01-15 02:38:44.000000000 -0500
+++ testfile	2013-01-15 02:38:59.000000000 -0500
@@ -1,2 +1,3 @@
 splitdiff testfile
 ONE
+PATCH_TWO
EOF
tc_fail_if_bad $? "Failed to create the splitdiff test patch file" || return
splitdiff -a -E test.patch >$stdout 2>$stderr
tc_fail_if_bad $? "splitdiff command could not split the patch" || return
grep PATCH_ONE test.patch.part001 >$stdout 2>$stderr && grep PATCH_TWO test.patch.part002 >$stdout 2>$stderr
tc_pass_or_fail $? "splitdiff test failed"

tc_register "Test fixcvsdiff"
cat <<-EOF> fixcvsdiff.test
#The below file has a tab after the lines on which patch is applied
#fixcvsdiff considers that the filename ends at the first TAB
Index: example_bug/report
===================================================================
diff -r1.6.4.1
--- example_bug.org/report	
+++ /dev/null	
@@ -1,389 +0,0 @@
-fixcvsdifftest
EOF
tc_fail_if_bad $? "Failed to create fixcvsdiff test file" || return
fixcvsdiff -b -p fixcvsdiff.test >$stdout 2>$stderr
cat $stdout | grep "cvs remove example_bug/report"
tc_fail_if_bad $? "fixcvsdiff didnt print output for cvs remove" || return
grep "diff -r1.6.4.1 example_bug/report" fixcvsdiff.test >$stdout 2>$stderr
tc_pass_or_fail $? "fixcvsdiff test failed"

tc_register "Test dehtmldiff"
#There is a bug present for this testcase
#https://fedorahosted.org/patchutils/ticket/20
dehtmldiff page.html > dehtmldiff.patch >$stdout 2>$stderr
tc_pass_or_fail $? "Test dehtmldiff test failed"


TST_TOTAL=$TST_TOTAL+3
popd >$stdout 2>$stderr
}

#
#main
#
tc_setup && run_test
