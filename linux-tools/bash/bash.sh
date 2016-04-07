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
## File :	bash.sh
##
## Description:	Check that the bash shell can run
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break cat grep chmod || return

	ARGS=""
	grep -q bash /etc/jlbd.manifest && ARGS="-s /bin/bash"

	tc_add_user_or_break user$$ "$ARGS" || return
	
	cat > $TCTMP/sedcmd <<-EOF
		#!$(which sed) -f
		/$TC_TEMP_USER/s/\/bin\/bash$/\/usr\/bin\/rbash/
	EOF
	chmod +x $TCTMP/sedcmd
	$TCTMP/sedcmd /etc/passwd > $TCTMP/passwd
	tc_break_if_bad $? "could not set rbash in /etc/passwd" || return
	cp  $TCTMP/passwd /etc/passwd	# will be cleaned up automatically
					# when temp user is deleted

	#ln -sf /bin/bash /bin/rbash
	ln -sf /bin/bash /usr/bin/rbash
}

tc_local_cleanup()
{
	rm /usr/bin/rbash
}

################################################################################
# the testcase functions
################################################################################

function test01()
{
	tc_register "check that bash can execute"

	local expected="running in bash shell"
	cat > $TCTMP/trybash <<-EOF
		echo "$expected"
		exit 0
	EOF
	chmod +x $TCTMP/trybash

	$TCTMP/trybash >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response" || return

	grep -q "$expected" $stdout 2>$stderr
	tc_pass_or_fail $? "Did not see expected output \"$expected\" in stdout"

}

function test02()
{
	tc_register "su to restricted bash user prevents \"cd /\""

	su $TC_TEMP_USER -c "cd /" &>$stdout
	rc=$?
	[ $rc -ne 0 ]
	tc_fail_if_bad $? "Expected bad RC, got $rc" || return

	grep -q restricted $stdout
	tc_pass_or_fail $? "Expected to see \"restricted\" in stdout"
	
}

# assumes test02 ran to setup user
function test03()
{
	tc_register "su -l to restricted bash user prevents \"cd /\""

	su -l $TC_TEMP_USER -c "cd /" &>$stdout
	rc=$?
	[ $rc -ne 0 ]
	tc_fail_if_bad $? "Expected bad RC, got $rc" || return

	grep -q restricted $stdout
	tc_pass_or_fail $? "Expected to see \"restricted\" in stdout"
}

#test for cve regressions
#bug 117235
function test04()
{
	tc_register "Regressions on CVE's"

	$LTPBIN/shellshock_test.sh >$stdout 2>$stderr
	tc_pass_or_fail $? "Machine is vulnerable"
}

################################################################################
# main
################################################################################

TST_TOTAL=4
tc_setup			# standard tc_setup

test01 &&
test02 
test03
test04
