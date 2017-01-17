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
## File :	ncftp.sh
##
## Description:	Test the ncftp package
##
## Author:	Robb Romans <robb@austin.ibm.com>
###########################################################################################
## source the utility functions
##		Jul 17 2003 - fixed sourcing of utility functions so that

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

CASEBIN=${LTPBIN%/shared}/ncftp
# global variables
#
REQUIRED="cat ls rm tail"
# ncftpbatch reads this environment variable:
export HOME=`pwd`

# for uploads NOT YET IMPLEMENTED
SERVER2=""
UPFILE=$CASEBIN/ncftp-test/ncftp_testfile.txt
CMDFILE=$CASEBIN/ncftp-test/test_01.txt
vsftp_path="$LTPBIN/../vsftpd"
# array to parse error codes into readable string
errmsg[1]="ERROR: Could not connect to remote host."
errmsg[2]="ERROR: Could not connect to remote host - timed out."
errmsg[3]="ERROR: Transfer failed."
errmsg[4]="ERROR: Transfer failed - timed out."
errmsg[5]="ERROR: Directory change failed."
errmsg[6]="ERROR: Directory change failed - timed out."
errmsg[7]="ERROR: Malformed URL."
errmsg[8]="ERROR: Usage error."
errmsg[9]="ERROR: Error in login configuration file."
errmsg[10]="ERROR: Library initialization failed."
errmsg[11]="ERROR: Session initialization failed."

################################################################################
# testcase functions
################################################################################

function start_server()
{
	tc_register "Dummy register to keep PAN happy on early exit."
	tc_executes vsftpd || {
		tc_info "We don't have a local vsftpd server. Please provide one on command line."
		tc_info "Make sure the following two files are present in the ftp server"
		tc_info "/pub/MIRRORS.TXT /pub/NOTICE.TXT"
		tc_info "Invoke the test as \"ncftp.sh <server>\""
		exit 0
	}

        STOP_SERVER=1
	$vsftp_path/vsftpd.sh START_SERVER || return
	tc_break_if_bad $? "Our local vsftpd server is busted!" || exit

	# Create the files required at the server side.
	mkdir -p /var/ftp/pub/
	[ ! -e /var/ftp/pub/MIRRORS.TXT ] && cp $CMDFILE /var/ftp/pub/MIRRORS.TXT
	[ ! -e /var/ftp/pub/NOTICE.TXT  ] && cp $CMDFILE /var/ftp/pub/NOTICE.TXT
	return 0
}

function tc_local_setup {
	tc_info "Using $SERVER as the server"
	((START_SERVER)) && start_server
}

function tc_local_cleanup {
	((STOP_SERVER)) && $vsftp_path/vsftpd.sh "STOP_SERVER"
}
		
function ncftp_00 {
    tc_register "Test that required ncftp programs exist"
    tc_executes ncftp ncftpls ncftpget ncftpput ncftpbatch ncftpspooler
    tc_pass_or_fail $? "ncftp package is not properly installed" || return
}

function ncftp_01 {
	tc_register "Test downloading a file"
	cat $CMDFILE | ncftp $SERVER &>/dev/null
	ls MIRRORS.TXT 1>/dev/null 2>$stderr
	tc_pass_or_fail "$?" "expected download file not found."
	rm -f MIRRORS.TXT &>/dev/null
}

function ncftp_02 {
	tc_register "Test NcFTPls"
	# -d writed debugging information
	ncftpls -d $TCTMP/ncftp_02.out ftp://$SERVER/pub/ &>/dev/null
	tc_pass_or_fail "$?" "Failed: ${errmsg[$?]}" "`tail -20 $TCTMP/ncftp_02.out`"
}

function ncftp_03 {
	tc_register "Test NcFTPGet"
	# -d writes debugging information
	ncftpget -d $TCTMP/ncftp_03.out $SERVER $TCTMP /pub/NOTICE.TXT 2>/dev/null
	tc_fail_if_bad "$?" ${errmsg[$?]} || return
	ls $TCTMP/NOTICE.TXT 1>/dev/null 2>$stderr
	tc_pass_or_fail "$?" "expected download file not found" "`tail -20 $TCTMP/ncftp_03.out`"
	rm -f $TCTMP/NOTICE.TXT $TCTMP/ncftp_03.out &>/dev/null
}

function ncftp_04 {
	tc_register "Test NcFTPPut"
	# -d writed debugging information
	ncftpput -d $TCTMP/ncftp_04.out ftp://$SERVER2/incoming/ $TCTMP/$UPFILE &>/dev/null
	tc_pass_or_fail "$?" "Failed: ${errmsg[$?]}" "`tail -20 $TCTMP/ncftp_04.out`"
}

function ncftp_05 {
	tc_register "Test NcFTPbatch"
	# Create a job queue
	ncftpget -bb $SERVER $TCTMP /pub/NOTICE.TXT 2>/dev/null
	tc_fail_if_bad "$?" "Unable to create the job queue: ${errmsg[$?]}"
	# process the job queue
	ncftpbatch -D &>/dev/null
	tc_fail_if_bad "$?" "Unable to process the job queue: ${errmsg[$?]}" || return
	ls $TCTMP/NOTICE.TXT >/dev/null 2>$stderr
	tc_pass_or_fail "$?" "expected download file not found"
	rm -f $TCTMP/NOTICE.TXT &>/dev/null
}

function ncftp_06 {
	# this testcase requires root priveleges.
	# spooler must access global dir /var/spool/ncftp
	tc_root_or_break || return
	tc_register "Test NcFTPspooler"
	killall ncftpspooler &>/dev/null
	# Create a job queue
	ncftpget -bb $SERVER $TCTMP /pub/NOTICE.TXT 2>/dev/null
	tc_fail_if_bad "$?" "Unable to create the job queue: ${errmsg[$?]}" || return
	# Process the queue
	ncftpspooler -d
	tc_pass_or_fail "$?" "Unable to process the job queue: ${errmsg[$?]}"
	rm -f $TCTMP/NOTICE.TXT &>/dev/null
	killall ncftpspooler &>/dev/null
}



####################################################################################
# MAIN
####################################################################################

if [ "$1" ]
then
	SERVER=$1
	START_SERVER=0
else
	SERVER="127.0.0.1"
	START_SERVER=1
fi

tc_setup 120
tc_exec_or_break $REQUIRED || exit
ncftp_00 &&
ncftp_01 &&
ncftp_02 &&
ncftp_03 &&
# ncftp_04 &&
ncftp_05 &&
ncftp_06
