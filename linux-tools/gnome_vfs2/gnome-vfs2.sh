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
### File :        gnome-vfs2.sh                                                ##
##
### Description: This testcase tests pango package                             ##
##
### Author:      Ramesh YR, rameshyr@linux.vnet.ibm.com                        ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/gnome_vfs2
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/gnome_vfs2/tests"
REQUIRED="vncserver"
function tc_local_setup()
{
        rpm -q "gnome-vfs2" >$stdout 2>$stderr
	tc_break_if_bad $? "gnome-vfs2 package is not installed"
	tc_exec_or_break $REQUIRED
	#tests need X-window environment as it's obvious 
	#from gnome-vfs2 package name !
	vncserver :123 -SecurityTypes None >/dev/null
	export DISPLAY=:123
}

function tc_local_cleanup()
{
	vncserver -kill :123 >/dev/null
}

function run_test()
{
        pushd $TESTS_DIR &>/dev/null
        TESTS=`ls | grep -v "test.input"` 
        TST_TOTAL=`echo $TESTS | wc -w`
        for test in $TESTS
        do
                if [ $test == "test-async" ]
                then
			#test-async expects URI of a file as an argument
			#test.input is just a text file
                        tc_register "Test $test"
                        ./$test file://$TESTS_DIR/test.input >$stdout 2>$stderr
			RC=$?
		elif [ $test == "test-async-cancel" ]
		then
			tc_register "Test $test"
			# See https://bugzilla.linux.ibm.com/show_bug.cgi?id=122541#c10
			for((i=0;i<5;i++))
			do
				./$test  >$stdout 2>$stderr
				RC=$?
				[ x$RC == x0 ] &&  break
			done
                else
                        tc_register "Test $test"
                        ./$test >$stdout 2>$stderr
			RC=$?
                fi
		grep -i "test failed" $stderr
		if [ $? -eq 0 ]; then
		    tc_pass_or_fail $RC "test failed"
		else
		    cat /dev/null >$stderr
		    tc_pass_or_fail $RC "test failed"
		fi
 
	done
        popd &>/dev/null
}
#
# main
#
tc_setup && \
run_test 
