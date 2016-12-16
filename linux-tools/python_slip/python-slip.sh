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
### File :        python-slip.sh                                                          ##
##											  ##
### Description: This testcase tests python-slip package                                  ##
##											  ##
### Author:      Basheer Khadarsabgari, basheer@linux.vnet.ibm.com                        ##
############################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/python_slip
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/python_slip/example"
REQUIRED="python rpm"

servicedir="/usr/share/dbus-1/system-services"
service_DATA="org.fedoraproject.slip.example.mechanism.service"

confdir="/etc/dbus-1/system.d"
conf_DATA="org.fedoraproject.slip.example.mechanism.conf"

policy0dir="/usr/share/PolicyKit/policy"
policy0_DATA="org.fedoraproject.slip.example.policy"

policy1dir="/usr/share/polkit-1/actions"
policy1_DATA="org.fedoraproject.slip.example.policy"

libexecdir="/usr/local/libexec"
libexec_SCRIPTS="example-conf-mechanism.py"

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return
}

function install_check()
{
        rpm -q "python-slip" >$stdout 2>$stderr
        tc_break_if_bad $? "python-slip package is not installed"
}


function tc_local_cleanup()
{
	#Uninstalling example service after execution
	rm -f "$libexecdir/$libexec_SCRIPTS"
	rm -f "$servicedir/$service_DATA"
	rm -f "$confdir/$conf_DATA"
	rm -f "$policy0dir/$policy0_DATA"
	rm -f "$policy1dir/$policy1_DATA"
}


function run_test()
{
	tc_register "Test python-slip"
	pushd $TESTS_DIR >$stdout 2>$stderr
	##installing example service 
	install -m0755 $libexec_SCRIPTS $libexecdir && install -m0644 $service_DATA $servicedir && install -m0644 $conf_DATA $confdir && touch $confdir/$conf_DATA && \
	install -d $policy0dir && install -m0644 $policy0_DATA $policy0dir && install -m0644 $policy1_DATA $policy1dir && \
	/sbin/restorecon -v -R $libexecdir $servicedir $confdir $policy0dir $policy1dir
	RC=$? 
	if [ $RC -eq 0 ] 
	then
		python example-conf-mechanism.py >$stdout 2>$stderr &  ##starting the service in background
		pid=`echo $!`
		tc_wait_for_pid $pid  
		if [ $? -eq 0 ] ; then
			python example-conf-client.py >$stdout 2>$stderr
			[ $? -eq 0 ] || tc_break_if_bad $? "Client failed to use the example service"
			[ $? -eq 0 ] && tc_wait_for_no_pid $pid
			tc_pass_or_fail $? "python-slip testcase failed" 
		else
			tc_pass_or_fail $? "Failed to start the installed example service"
		fi
	else
		tc_pass_or_fail $RC "Failed to installed the example service"		
	fi
	popd >$stdout 2>$stderr

}

tc_setup
install_check && run_test

