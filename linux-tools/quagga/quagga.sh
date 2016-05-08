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
### File : quagga.sh                                                           ##
##
### Description: This testcase tests quagga package                            ##
##
### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/quagga/tests"
EXPECT=`which expect`
tmpfile="$TCTMP/testchecksum.exp"
required="expect"

function tc_local_setup()
{
	# check installation and environment 
        if [ -f /usr/lib*/quagga ]; then
        tc_break_if_bad $? "quagga not installed"
        fi
	tc_exec_or_break $required || return
	cat <<-EOF >$tmpfile
	#!$EXPECT
	set root_prompt \#
	# set the timeout value
	set timeout 1000
	spawn /bin/bash
	expect {
        	"\$root_prompt" { }
        	default { exit 3 }
	}
	send "$TESTS_DIR/testchecksum\r"
	expect {
        	-re "ospfd.*failed" { exit 3 }
        	-re "lib.*failed" { exit 4 }
        	-re "ospfd.*mismatch" { exit 5 }
        	default { exit 0 }
	}
	EOF
}

function run_test()
{
	pushd $TESTS_DIR &>/dev/null
	# Making the testcase testsig manual. 
	TESTS=`ls | grep -v testsig`
	TST_TOTAL=`echo $TESTS | wc -w`
        for test in $TESTS; do
             tc_register "Test $test"
               if [ "$test" = "testbuffer" ]
               then
                    ./$test 100 >$stdout 2>$stderr
                    tc_pass_or_fail $? "Test $test fail"
               elif [ "$test" = "testchecksum" ]
               then 
                    $EXPECT $tmpfile
                    tc_pass_or_fail $? "Test $test fail"
               elif [ "$test" = "aspathtest" ]
               # output on stderr does not indicate failure
               then
	            ./$test >$stdout 2>$stderr 
		    RC=$?
                    cat /dev/null > $stderr
                    tc_pass_or_fail $RC "Test $test fail"
               elif [ "$test" = "testbgpcap" ]
               # output on stderr does not indicate failure
               then
	            ./$test >$stdout 2>$stderr 
		    RC=$?
                    cat /dev/null > $stderr
                    tc_pass_or_fail $RC "Test $test fail"
               else
	            ./$test >$stdout 2>$stderr 
		    RC=$?
		    len=`grep -v "foo" $stderr | wc -l`
		    if [ $len -eq 0 ] 
		    then 
	            	cat /dev/null > $stderr
		    fi
                    tc_pass_or_fail $RC "Test $test fail"
               fi
        done	
	popd &>/dev/null
}

#
# main
#
tc_setup
run_test 
