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
### File :       urlview.sh                                                    ##
##
### Description: Test for urlview package                                      ##
##
### Author:      Kingsuk Deb <kingsdeb@linux.vnet.ibm.com>                     ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/urlview"
required="urlview url_handler.sh screen"

function tc_local_setup()
{
	# Check installation 
	tc_exec_or_break $required 
	# Create test file with diff types of URLs
	cat <<-EOF > $TCTMP/urlview_test_file
		I was trying to access ftp://anonymous:yourid@server:port/path but 
		could not.Then I decided to connect url http://server:port/path#fragment.
		I had problem there too. I emailed admin by clicking on mailto:address.
		He suggested to BSO on telnet://user:password@server:port/ and 
		advised to access file://server/path and https://server:port/ .

		# To note: I did not have problem to access www.w3.org . 	
	EOF
}

function tc_local_cleanup()
{
	[ -f /etc/urlview.conf.bak ] && mv /etc/urlview.conf.bak \
	/etc/urlview.conf
        pgrep screen | xargs kill -9
        screen -wipe >&/dev/null
        cat /dev/null > screenlog.0
}

function run_test()
{
	tc_register "Test urlview"
	screen -dmSL test  urlview $TCTMP/urlview_test_file
	sleep 10;sync
	grep -q "5 matches" screenlog.0
	tc_pass_or_fail $? "urlview failed" 
	tc_register "Test urlview.conf"
	[ -f /etc/urlview.conf ] && mv /etc/urlview.conf /etc/urlview.conf.bak
	cat <<-EOF > /etc/urlview.conf
		# Dummy urlview.conf for test purpose

		REGEXP (((https?|gopher)://|(news):)[^' \t<>"]+|(web)\.[-a-z0-9.]+)[^' \t.,;<>"\):]
	EOF
	screen -dmSL test  urlview $TCTMP/urlview_test_file  
	sleep 10; sync
	grep -q "2 matches" screenlog.0
	tc_pass_or_fail $? "Reading from urlview.conf fail"
	tc_register "Test url_handler.sh"
	url_handler.sh "www.w3.org"
	tc_fail_if_bad $? " url_handler.sh fail" || return 
	echo "\n" | url_handler.sh "some junk text" >$stdout 2>$stderr
	grep -q "Unknown URL type." $stdout
	tc_pass_or_fail $? "url_handler.sh fail"
}

#
# main
#
tc_setup
TST_TOTAL=3
run_test 
