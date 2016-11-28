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
## File :	ftplib_sh.sh
##
## Description:	Test the ftplib functions .
##
## Author:	CSDL
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/ftplib
source $LTPBIN/tc_utils.source

################################################################################
#  test configuration
################################################################################

_FTPSRV="localhost"
_FTPUSR="root"
_FTPPSWD=""

################################################################################
# utility functions
################################################################################


usage()
{
	local tab=$'\t'
	cat <<-EOF

		usage:
		$tab$0 [-r host  [ -u user ] -p password ] [-h]
		$tab$0	-r : Set the remote ftpserver. If not set, will use localhost.
		$tab$0	-u : Set the remote ftp user name. Default is root. 
		$tab$0	-p : Set the remote ftp user's password.
		$tab$0	-h : Print this help text.
		
		If you designate a remote ftp server, you should have correctly configurated and started it for the user on the remote host.

	EOF
	exit 1
}


vsftpdconfig()
{
	[ -s /etc/vsftpd/vsftpd.conf ] && mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.testsave$$

	# The config file use for testing
	cat > /etc/vsftpd/vsftpd.conf <<-EOF	

	local_enable=YES
	write_enable=YES
	connect_from_port_20=YES
	ascii_upload_enable=YES
	ascii_download_enable=YES
	pam_service_name=vsftpd

	EOF

}


tftpdconfig()
{
	[ -s /etc/ftpaccess ] && mv /etc/ftpaccess /etc/ftpaccess.testsave$$
	# The config file use for testing

	cat > /etc/ftpaccess <<-EOF		
	class   local   real
	delete     yes  real               # delete permission?
	overwrite  yes  real               # overwrite permission?
	rename     yes  real               # rename permission?
	chmod      yes  real               # chmod permission?
	umask      yes  real               # umask permission?		

	EOF
	
}

localftpsrv_check()
{
	local vsftpdwhich=`which vsftpd 2>/dev/null `
	local wuftpdwhich=`which in.ftpd 2>/dev/null`
	local ftpcmd=""

	tc_add_user_or_break
	
	tc_info "Save current inetd/xinetd/ftp configuration."	
	
	_FTPUSR=$TC_TEMP_USER
	_FTPPSWD="$TC_TEMP_PASSWD"
	
	if [ ! "$vsftpdwhich" = "" ] ; then
		ftpcmd="vsftpd"
		vsftpdconfig		
	elif [ ! "$wuftpdwhich" = "" ] ; then
		ftpcmd="in.ftpd"
		tftpdconfig
	else 
		tc_info "No vsftpd and wuftpd installed on localhost."
		return 1
	fi
	
		if [ "$ftpcmd" == "vsftpd" ] ; then
			ftpcmd=$vsftpdwhich
		else
			ftpcmd=$wuftpdwhich
		fi
		mv /etc/xinetd.conf /etc/xinetd.conf.testsave$$ >&/dev/null
		cat > /etc/xinetd.conf <<-EOF
		
		defaults
		{
			log_type        = FILE /var/log/xinetd.log
			log_on_success  = HOST EXIT DURATION
			log_on_failure  = HOST ATTEMPT
			instances       = 2
		}

		service ftp
		{
			socket_type		= stream
			protocol        = tcp
			wait			= no
			user			= root
			server			= $ftpcmd
			instances       = UNLIMITED
		}

		EOF
		tc_service_start_and_wait vsftpd
		tc_break_if_bad $? "Unable to restart vsftpd"

	
}


parse_args()
{
	while getopts r:u:p:h opt ; do
		case "$opt" in
			r)	_FTPSRV=$OPTARG
				;;
			u)	_FTPUSR=$OPTARG
				;;
			p)	_FTPPSWD=$OPTARG
				;;
			h)	
				usage
				;;
			*)	usage	# exits
				;;
		esac
	done


	if [ "$_FTPSRV" = "127.0.0.1" ] ; then
		_FTPSRV="localhost"
	elif [ "$_FTPSRV" = "`hostname -i`" ] ; then
		_FTPSRV="localhost"
	fi 
	
	if  [  ! "$_FTPSRV" = "localhost" ]  && [ "$_FTPPSWD" = "" ] ; then
		echo 
		echo "You must give the password for remote ftp user."
		usage
	fi
}

tc_local_setup()
{	

	WFIFO=$TCTMP/fifo1
	RFIFO=$TCTMP/fifo2

	mkfifo $WFIFO $RFIFO
	cp -r ${LTPBIN%/shared}/ftplib/ftplib-data $TCTMP/

	# run ftptest asynchronously
	./ftptest $WFIFO $RFIFO > /dev/null  &
	killit=$!	

	if [ "$_FTPSRV" = "localhost"  ] ; then
		localftpsrv_check
	fi	
	
}

tc_local_cleanup()
{
	sendcmd testover
	kill $killit &>/dev/null

	if [ "$_FTPSRV" = "localhost" ]; then 
	
		tc_del_user_or_break $_FTPUSR
		
		tc_info "Restore inetd/xinetd/ftp."	
		
		if [ -e /etc/vsftpd/vsftpd.conf.testsave$$ ]; then
			mv /etc/vsftpd/vsftpd.conf.testsave$$ /etc/vsftpd/vsftpd.conf
		fi		
		
		if [ -e /etc/ftpaccess.testsave$$ ]; then
			mv /etc/ftpaccess.testsave$$ /etc/ftpaccess
		fi			
		

		mv /etc/xinetd.conf.testsave$$ /etc/xinetd.conf >&/dev/null
		tc_service_stop_and_wait vsftpd 
	fi
}

sendcmd()
{
	echo $* > $WFIFO 
}

checkresponse()
{
	ErrorInfo=`./qcat $RFIFO`
	echo $ErrorInfo > $stdout
	echo $ErrorInfo | grep "Ok:$1" >/dev/null
}

################################################################################
# the testcase functions
################################################################################

# $1:info to tc_register , $2:APItested , $3: cmd sent to ftptest
test_template()
{
	tc_register "$1"
	sendcmd $3
	checkresponse $2
	tc_pass_or_fail $? "$3 Failed."
}
 
test_connect()
{
	tc_register	"FtpConnect"
	sendcmd host $_FTPSRV
	checkresponse FtpConnect
	tc_pass_or_fail $?  "check ftpserv configuration."
}

test_login()
{
	tc_register "FtpLogin"
	sendcmd user $_FTPUSR $_FTPPSWD
	checkresponse Ftplogin
	tc_pass_or_fail $?  "error user or password."
}


test_get()
{
	sendcmd mode i
	checkresponse mode
	test_template "FtpGet test of binary mode" FtpGet "get $TCTMP/test.bin test.bin"

	sendcmd mode a
	checkresponse mode
	test_template "FtpGet test of ascii mode" FtpGet "get $TCTMP/test.txt test.txt"

}

test_put()
{
	sendcmd mode a
	checkresponse mode
	test_template "FtpPut test of ascii mode" FtpPut "put $TCTMP/ftplib-data/test.txt test.txt"

	sendcmd mode i
	checkresponse mode
	test_template "FtpPut test of binary mode" FtpPut "put $TCTMP/ftplib-data/test.bin test.bin"
}

################################################################################
#  main
################################################################################

TST_TOTAL=21
parse_args $*
tc_setup
	


# If these two don't work it is not worth trying the rest.
test_connect || exit
test_login || exit

test_template FtpPwd     FtpPwd     "pwd"

test_template FtpMkdir   FtpMkdir   "mkdir dirtestdir" || exit 
test_template FtpChdir   FtpChdir   "chdir dirtestdir" || exit 
test_put || exit
test_get 
test_template FtpCDUp    FtpCDUp    "cdup" || exit 
test_template FtpNlst    FtpNlst    "nlist dirtestdir"
test_template FtpDir     FtpDir     "ftpdir dirtestdir"
test_template FtpSize    FtpSize    "size dirtestdir/test.txt"
test_template FtpModDate FtpModDate "moddate dirtestdir/test.txt"
test_template FtpDelete  FtpDelete  "delete dirtestdir/test.bin" || exit
test_template FtpRename  FtpRename  "rename dirtestdir/test.txt ./test.txt" || exit
test_template FtpRmdir   FtpRmdir   "rmdir dirtestdir"
test_template FtpDelete  FtpDelete  "delete test.txt" 
test_template FtpSysType FtpSysType "systype"
test_template FtpSite    FtpSite    "site umask"
test_template FtpQuit    FtpQuit    "quit"
