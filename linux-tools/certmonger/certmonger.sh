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
#cd `dirname $0` 
#LTPBIN=${LTPBIN%/shared}/certmonger
source $LTPBIN/tc_utils.source 

## Author:  Sohny Thomas <sohthoma@in.ibm.com>
###########################################################################################
## source the utility functions

TSTDIR=${LTPBIN%/shared}/certmonger/Tests 
REQUIRED="certmaster-getcert getcert ipa-getcert selfsign-getcert"

function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break  $REQUIRED || exit
	service certmonger status &>/dev/null
        if [ $? -eq 3 ]; then
                service certmonger start &>/dev/null
                restore_certmonger_deamon="yes"
        fi 
	# create non-root user to execute some of the tests, bug 116821
	# since tests create out file, changing ownership
	tc_add_user_or_break && chown -R $TC_TEMP_USER:$TC_TEMP_USER $TSTDIR
	cp /etc/krb5.conf $TCTMP/
	sed -i -r -e 's/#//g' /etc/krb5.conf
	
}

function tc_local_cleanup()
{
	if [ "$restore_certmonger_deamon" == "yes" ]; then
		service certmonger stop &>/dev/null	
	fi
	# replace the ownership to root!
	chown -R root:root $TSTDIR
	
	cp $TCTMP/krb5.conf /etc/
	
}


function test_certmonger()
{
	pushd $TSTDIR > /dev/null
	
	certcommands="certmaster ipa selfsign"
	for cmd in $certcommands; do 
	        tc_register "Adding a Authentication signing request with  $cmd-getcert "
		$cmd-getcert request -d $TCTMP -n temp1 -Sv 1>$stdout 2>stderr	
		tc_pass_or_fail $? "Adding a tracking request with $cmd-getcert failed"
		reqid=`cat $stdout | cut -d \" -f2`
		
		tc_register "Tracking a signing request with $cmd-getcert "
		$cmd-getcert start-tracking -i $reqid -d $TCTMP -n temp1 -Sv 1>$stdout 2>stderr
		tc_pass_or_fail $? "Tracking of signing request with $cmd-getcert failed"
	
		tc_register "Resubmitting  a signing request with $cmd-getcert "
		$cmd-getcert resubmit -i $reqid -d $TCTMP -n temp1 -Sv 1>$stdout 2>stderr
		tc_pass_or_fail $? "Resubmitting of signing request with $cmd-getcert failed"
		
		tc_register "listing  currently all tracking signing request with $cmd-getcert "
		$cmd-getcert list -Sv 1>$stdout 2>stderr
		tc_pass_or_fail $? "listing of currently tracked signing request with $cmd-getcert failed"

		tc_register "listing  currently all tracking signing request with getcert"
       		getcert list -c $cmd -Sv 1>$stdout 2>stderr
	        tc_pass_or_fail $? "listing of currently tracked signing request with getcert $cmd failed"
		
		tc_register "listing of certificate signing authorities with $cmd-getcert "
		$cmd-getcert list-cas -Sv 1>$stdout 2>stderr
		tc_pass_or_fail $? "listing of certificate signing authorities with $cmd-getcert failed"

	        tc_register "listing of certificate signing authorities with getcert $cmd "
       		getcert list-cas -Sv -c $cmd 1>$stdout 2>stderr
       		tc_pass_or_fail $? "listing of certificate signing authorities with getcert $cmd failed"
		
		tc_register "stoping tracking of signing request with $cmd-getcert "
		$cmd-getcert stop-tracking -i $reqid -d $TCTMP -n temp1 -Sv 1>$stdout 2>stderr
		tc_pass_or_fail $? "listing of certificate signing authorities with $cmd-getcert failed"
	done

        tc_register "Tests for certmonger deamon process for various CAs methods"
        su - $TC_TEMP_USER -c "cd $TSTDIR;./run-tests.sh" 1>$stdout 2>$stderr
        tc_pass_or_fail $? "Tests for certmonger deamon process failed"

	popd > /dev/null

}

TST_TOTAL=25
tc_setup 
test_certmonger
