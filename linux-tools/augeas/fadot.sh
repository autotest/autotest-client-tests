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
## File :        fadot.sh                                                      #
##
## Description:  This script tests basic functionality of fadot tool           #
##
## Author:       Mithu Ganesan<miganesa@in.ibm.com>                            #
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/augeas
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/augeas"
REQUIRED="fadot"
################################################################################
# Testcase functions
################################################################################

function tc_local_setup()
{
        rpm -q "graphviz" >$stdout 2>$stderr
        tc_break_if_bad $? "graphviz package is not installed, needed for creating finite automata images"
        tc_exec_or_break $REQUIRED
        dest=$TEST_DIR/fadot-output
        mkdir -p $dest
}

function test01()
{
        tc_register    "Testing show operation"
	fadot -f $dest/sample.dot     -o show         "[a-z]*" &> $stdout 2>$stderr
        tc_break_if_bad $? "fadot failed to create sample.dot file" || return
	dot -Tpng -o $dest/sample.png $dest/sample.dot &> $stdout 2>$stderr
        tc_pass_or_fail $? "show test failed"
	
	tc_register    "Testing concat operation"
        fadot -f $dest/concat.dot     -o concat       "[a-b]" "[b-c]" &> $stdout 2>$stderr
        tc_break_if_bad $? "fadot failed to create concat.dot file" || return
        dot -Tpng -o $dest/concat.png $dest/concat.dot &> $stdout 2>$stderr
        tc_pass_or_fail $? "concat test failed"

        tc_register    "Testing union operation"
	fadot -f $dest/union.dot      -o union        "[a-b]" "[b-c]" &> $stdout 2>$stderr
        tc_break_if_bad $? "fadot failed to create union.dot file" || return
        dot -Tpng -o $dest/union.png $dest/union.dot &> $stdout 2>$stderr
        tc_pass_or_fail $? "union test failed"
	
	tc_register    "Testing intersect operation"
        fadot -f $dest/intersect.dot  -o intersect    "[a-b]" "[b-c]" &> $stdout 2>$stderr
        tc_break_if_bad $? "fadot failed to create intersect.dot file" || return
        dot -Tpng -o $dest/intersect.png $dest/intersect.dot &> $stdout 2>$stderr
        tc_pass_or_fail $? "intersect test failed"

        tc_register    "Testing complement operation"
	fadot -f $dest/complement.dot -o complement   "[a-z]" &> $stdout 2>$stderr
        tc_break_if_bad $? "fadot failed to create complement.dot file" || return
        dot -Tpng -o $dest/complement.png $dest/complement.dot &> $stdout 2>$stderr
        tc_pass_or_fail $? "complement test failed"

        tc_register    "Testing minus operation"
	fadot -f $dest/minus.dot      -o minus        "[a-z]" "[a-c]" &> $stdout 2>$stderr
        tc_break_if_bad $? "fadot failed to create minus.dot file" || return
        dot -Tpng -o $dest/minus.png $dest/minus.dot &> $stdout 2>$stderr
        tc_pass_or_fail $? "minus test failed"
	
	tc_info		"Results are available in $dest directory. Compare the images in $dest directory with respective images in sample-images directory"		
}

################################################################################
# main
################################################################################
tc_setup

TST_TOTAL=6
test01
