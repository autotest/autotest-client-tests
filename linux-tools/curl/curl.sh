#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
###########################################################################################
## Copyright 2004, 2015 IBM Corp                                                          ##
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
# File :	curl.sh
#
# Description:	wrapper for curltests.pl
#
# Author:	Robert Paulsen, rpaulsen@us.ibm.com
#
################################################################################
# source the standard utility functions
################################################################################

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/curl
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/curl/curl-tests


rejected="225 226 231 240 242 254 263"	# Flakey test cases

################################################################################
# utility functions
################################################################################

#
# tc_local_setup
#
function tc_local_setup()
{
	datadir=$TESTDIR/data
	mkdir -p $datadir/rejected
	for n in $rejected ; do
		[ -f "$datadir/test$n" ] && mv $datadir/test$n $datadir/rejected/
	done
	return 0
}

#
# tc_local_cleanup
#
function tc_local_cleanup()
{
	[ $? -ne 0 ] && type netstat && netstat -lpen  # capture port info if failure
	type killall && killall sws &>/dev/null
	rm -rf .http.pid .https.pid .http6.pid .ftp.pid \
	       .ftp2.pid .ftp6.pid .ftps.pid .tftpd.pid
	for t in $datadir/rejected/* ; do
		mv $t $datadir/
	done
}

################################################################################
# the test functions
################################################################################

#
# test01	run the curl tests
#
function test01()
{
	tc_register	"run the curl tests"
	
	killall sws &>/dev/null

	cd $TESTDIR
	rm -rf /tmp/curl-data
	ln -s $PWD/curl-data /tmp/curl-data
	export TCTMP
	export LTPBIN

        # Disable valgrind since customer may not have valgrind
	./runtests.pl -k -n     # -p	# -k = keep log files after run
				# -p show logs on failure
				# -n disable valgrind
	tc_pass_or_fail $? "Unexpected results" || {
	#	cp -ax log /usr/local/autobench/logs/002*.test/results/ltp/
		return 1
	}
}

################################################################################
# main
################################################################################

TST_TOTAL=1

tc_setup	# standard setup
tc_run_me_only_once

test01
