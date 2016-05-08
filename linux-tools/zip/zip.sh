#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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
# File :	zip.sh
#
# Description:	Test zip
#
# Author:	Robert Paulsen, rpaulsen@us.ibm.com
#

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

test_data=${LTPBIN%/shared}/zip/tst_zip_dir.tgz

################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"installation check"
	tc_executes zip
	tc_pass_or_fail $? "zip not properly installed"
}

#
# test02	zip up a set of directories
#
function test02()
{
	tc_register	"zip"
	tc_exec_or_break tar || return

	tar zx -C $TCTMP -f $test_data
	tc_break_if_bad $? "failed to extract tar file to initialize test"

	(
	    cd $TCTMP
	    zip -r $TCTMP/tst_zip_dir.zip tst_zip_dir >$stdout 2>$stderr
	    tc_pass_or_fail $? "unexpected results from zip"
	)
}

#
# test03	Test that unzip can uncompress .zip file.
#
function test03()
{
	tc_register "unzip"
	tc_exec_or_break diff || return

	# -X  restore UID/GID info
	# -K  keep setuid/setgid/tacky permissions
	mkdir $TCTMP/unzip_here
	(
	    cd $TCTMP/unzip_here
	    unzip -XK $TCTMP/tst_zip_dir.zip >$stdout 2>$stderr
	    tc_fail_if_bad $? "unzip failed" || return
        )

	# compare file contents "side-by_side"
	diff -rN $TCTMP/tst_zip_dir $TCTMP/unzip_here/tst_zip_dir >$stdout 2>$stderr
	tc_fail_if_bad $? "Unzip did not create all files and directories"

	# compare permissions, UID/GID, timestamps
	# from the above diff, each line of stdout names a pair of files -- original and extracted
	local junk original_file unzipped_file original_info unzipped_info
	while read junk junk original_file unzipped_file junk ; do
		set - $(ls -la $original_file)
		original_info="$1 $2 $3 $3 $5 $6"
		set - $(ls -la $unzipped_file)
		unzipped_info="$1 $2 $3 $3 $5 $6"
		[ "$original_info" = "$unzipped_info" ]
		tc_fail_if_bad $? "original and unzipped file attributes mismatch" \
				"original: \"$original_info\""$'\t'"for file $original_file" \
				"unzipped: \"$unzipped_info\""$'\t'"for file $unzipped_file" || return
	done < $stdout

	tc_pass_or_fail 0	# PASS if we get this far
}

################################################################################
# main
################################################################################

TST_TOTAL=3

# standard tc_setup
tc_setup

test01 &&
test02 &&
test03

