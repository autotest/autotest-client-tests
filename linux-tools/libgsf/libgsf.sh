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
## File:         ttmkfdir.sh
##
## Description:  This program tests ttmkfdir
##
## Author:       Athira Rajeev>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libgsf
source $LTPBIN/tc_utils.source
TEST_DIR=${LTPBIN%/shared}/libgsf/tests/.libs
TESTS_DIR=${LTPBIN%/shared}/libgsf/

################################################################################
# Utility functions
################################################################################

#
# local setup
#        
function tc_local_setup()
{       
	rpm -q libgsf 1>$stdout 2>$stderr
	tc_break_if_bad $? "libgsf not installed" || return
	mkdir $TCTMP/out-dir
	echo "test file" >> $TCTMP/outt
	echo "TEST FILE" >> $TCTMP/input-file
}

function runtest()
{
	pushd $TEST_DIR
	TESTSEXCLUDE="test-out-bzip test-out-gzip1 test-out-gzip2 test-outmem-printf test-out-printf test-restore-msole test-textline test-zip2 test-zip-out test-cat-zip test-cp test-cp-zip test-gio test-input1 test-ls-zip test-msole-printf test-msvba-zip test-cp-msole test-dump-msole test-msole2 test-zip-out-subdirs"
	
	test_excl=${TESTSEXCLUDE//-/_}
	TESTS=`ls`
	ls -1F $1 | grep '*' > filelist
	:>tests
	cat filelist | while read line ; do
        	line=${line%\*}
        	test_line=${line//-/_}
		echo $test_excl | grep -q "\<$test_line\>" && continue
		echo $line >> tests
	done
	TESTS=`cat tests`

	for t in $TESTS; do
		tc_register $t
		./$t >$stdout 2>$stderr
		tc_pass_or_fail $? "$t failed" 
	done

	tc_register "test-out-bzip"
	./test-out-bzip $TCTMP/out >$stdout 2>$stderr
	tc_fail_if_bad $? "test-out-bzip failed" || return

	file $TCTMP/out | grep -q bzip
	tc_pass_or_fail $? "test-out-bzip failed"

	tc_register "test-out-gzip1"

	./test-out-gzip1 $TCTMP/out >$stdout 2>$stderr
	tc_fail_if_bad $? "test-out-gzip1 ailed" || return
	
	file $TCTMP/out | grep -q gzip 
	tc_pass_or_fail $? "test-out-gzip1 failed"

	tc_register "test-out-gzip2"

	./test-out-gzip2 $TCTMP/out >$stdout 2>$stderr
        tc_pass_or_fail $? "test-out-gzip2 ailed" 

	tc_register "test-outmem-printf"

	./test-outmem-printf $TCTMP/out >$stdout 2>$stderr
	tc_pass_or_fail $? "test-outmem-printf failed" 

	tc_register "test-out-printf"

	./test-out-printf $TCTMP/out >$stdout 2>$stderr
	tc_pass_or_fail $? "test-out-printf failed" 

	tc_register "test-restore-msole"

	./test-restore-msole $TCTMP/out-dir $TCTMP/out-test-restore >$stdout 2>$stderr
	RC=$?
	if [ `grep -vc $TCTMP/out-dir $stderr` -eq 0 ];then cat /dev/null > $stderr; fi 
	tc_fail_if_bad $RC "test-restore-msole failed" || return

	file $TCTMP/out-test-restore | grep -q "Composite Document File V2 Document" 
	tc_pass_or_fail $? "test-restore-msole failed"

	tc_register "test-textline"

	./test-textline $TCTMP/input-file >$stdout 2>$stderr
	RC=$?
	if [ `grep -vc $TCTMP/input-file $stderr` -eq 0 ];then cat /dev/null > $stderr; fi
	tc_fail_if_bad $RC "test-textline failed" || return

	grep -q "TEST FILE" $stdout
	tc_pass_or_fail $? "test-textline failed"

	tc_register "test-zip2"

	./test-zip2 $TESTS_DIR/test.odp >$stdout 2>$stderr
	tc_pass_or_fail $? "test-zip2 failed"

	tc_register "test-zip-out"

	./test-zip-out $TCTMP/zip-out >$stdout 2>$stderr
        tc_fail_if_bad $? "test-zip-out failed" || return

	file $TCTMP/zip-out | grep -q "Zip archive data"
	tc_pass_or_fail $? "test-zip-out failed"

	tc_register "test-cat-zip"

	./test-cat-zip $TESTS_DIR/test.odp >/dev/null
        tc_pass_or_fail $? "test-cat-zip failed"

	tc_register "test-cp"

	./test-cp $TCTMP/input-file $TCTMP/output-file >$stdout 2>$stderr	
	tc_fail_if_bad $? "test-cp failed" || return

	diff -Naurp $TCTMP/input-file $TCTMP/output-file
	tc_pass_or_fail $? "test-cp failed"

	tc_register "test-cp-zip"

	./test-cp-zip $TESTS_DIR/test.odp $TCTMP/output-file >$stdout 2>$stderr
	RC=$?
	if [ `grep -vc $TESTS_DIR/test.odp $stderr` -eq 0 ];then cat /dev/null > $stderr; fi
	tc_fail_if_bad $RC "test-cp-zip failed" || return

	file $TCTMP/output-file | grep -q "OpenDocument Presentation"
	tc_pass_or_fail $? "test-cp-zip failed"

	tc_register "test-gio"

	./test-gio $TCTMP/input-file $TCTMP/output-file >$stdout 2>$stderr
        tc_fail_if_bad $? "test-gio failed" || return

	diff -Naurp $TCTMP/input-file $TCTMP/output-file
        tc_pass_or_fail $? "test-gio failed"

	tc_register "test-input1"

	./test-input1 $TCTMP/input-file $TCTMP/output-file >$stdout 2>$stderr
        tc_pass_or_fail $? "test-input1 failed"

	tc_register "test-ls-zip"

	./test-ls-zip $TESTS_DIR/file.zip >$stdout 2>$stderr
	RC=$?
	if [ `grep -vc $TESTS_DIR/file.zip $stderr` -eq 0 ];then cat /dev/null > $stderr; fi
	tc_fail_if_bad $RC "test-ls-zip failed" || return

	grep -q "text-input-file" $stdout
	tc_pass_or_fail $? "test-ls-zip failed"

	tc_register "test-msole-printf"

	./test-msole-printf $TCTMP/output-file >$stdout 2>$stderr
        tc_pass_or_fail $? "test-msole-printf failed"

	tc_register "test-cp-msole"

	./test-cp-msole $TCTMP/out-test-restore $TCTMP/out-cp-msole >$stdout 2>$stderr
	RC=$?
	if [ `grep -vc $TCTMP/out-test-restore $stderr` -eq 0 ];then cat /dev/null > $stderr; fi
	tc_fail_if_bad $RC "test-cp-msole failed" || return

	file $TCTMP/out-cp-msole | grep -q "Composite Document File V2 Document"
	tc_pass_or_fail $? "test-cp-msole failed"

	tc_register "test-zip-out-subdirs"
	./test-zip-out-subdirs $TCTMP/out-zip-out-subdirs >$stdout 2>$stderr
	tc_pass_or_fail $? "test-zip-out-subdirs failed"

	popd
    tc_register "gsf-office-thumbnailer"
	gsf-office-thumbnailer -i $TESTS_DIR/test.odp -o $TCTMP/foo.png -s 300 
	tc_fail_if_bad $? "gsf-office-thumbnailer failed" || return

	file $TCTMP/foo.png | grep -q "PNG image"
	tc_pass_or_fail $? "gsf-office-thumbnailer failed" 
}
tc_setup
runtest	
