#!/bin/bash
###########################################################################################
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
# File :	lzo.sh
#
# Description:	Test lzo compression library
#
# Author:	Suzuki K P <suzukikp@in.ibm.com> 
#

############cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/lzo
TESTDIR=${LTPBIN%/shared}/lzo

source $LTPBIN/tc_utils.source

function test_lzopack()
{
	lzopack_cmd=$TESTDIR/tests/examples/lzopack
	input=$TESTDIR/tests/examples/lzopack.c #input file for compression

	tc_register "lzopack test"
# Pack the file.
	$lzopack_cmd -9 $input $TCTMP/output.comp >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to pack the file" || return

# Test the output file above using -t
	$lzopack_cmd -t $TCTMP/output.comp >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to test the packed file" || return

# Uncompress the file using -d
	$lzopack_cmd -d $TCTMP/output.comp $TCTMP/output.img >$stdout 2>$stderr
	tc_fail_if_bad $? "Faild to decompress the packed file" || return

# Compare the input and the decompressed file
	diff -up $input $TCTMP/output.img >$stdout 2>$stderr
	tc_pass_or_fail $? "Pack/Unpack modifies the input file"
}


function test_lzotest()
{
	lzotest=$TESTDIR/tests/lzotest/lzotest
	args="-b128 -n100 $TESTDIR/tests/lzotest/lzotest.c"

	$lzotest -m | grep "\-m[0-9]" | 
	( while read marg name junk
	do
		tc_register "compression : $name"
		$lzotest $marg $args >$stdout 2>$stderr
		tc_pass_or_fail $? 
	done )
}
		

tc_setup

test_lzopack &&
test_lzotest
