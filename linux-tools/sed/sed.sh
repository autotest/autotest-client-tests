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
## File :	sed.sh
##
## Description:	Test the stream editor (sed)
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register "is sed installed?"
	tc_executes sed
	tc_pass_or_fail $? "sed not installed"
}

#
# test02	exercise sed a little
#
function test02()
{
	tc_register "sed"
	tc_exec_or_break cat chmod diff || return
	#
	# create source file
	cat > $TCTMP/sed_input <<-EOF
		line one
		line two
		line three
	EOF
	#
	# create sed script file
	local sed_cmd="`which sed`"
	cat > $TCTMP/sed_script <<-EOF
		#!$sed_cmd -f
		/two/s/line/LINE/
		/one/a\\
		first inserted line\\
		second inserted line
	EOF
	chmod +x $TCTMP/sed_script
	#
	# execute the sed command
	$TCTMP/sed_script $TCTMP/sed_input >$TCTMP/sed_output 2>$stderr
	tc_fail_if_bad $? "bad rc ($?) from sed" || return
	#
	# create file of expected results
	cat > $TCTMP/sed_exp <<-EOF
		line one
		first inserted line
		second inserted line
		LINE two
		line three
	EOF
	#
	# compare actual and expected results
	diff $TCTMP/sed_exp $TCTMP/sed_output >$TCTMP/sed_diff
	tc_pass_or_fail $? "actual and expected results do not compare" \
		"expected..."$'\n'"`cat $TCTMP/sed_exp`" \
		"actual..."$'\n'"`cat $TCTMP/sed_output`" \
		"difference..."$'\n'"`cat $TCTMP/sed_diff`"
}

################################################################################
# main
################################################################################

TST_TOTAL=2
tc_setup

test01 &&
test02
