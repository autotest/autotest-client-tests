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
## File :	vsftpd.sh
##
## Description:	Test vsftpd package
##
## Author:	Andrew Pham, apham@austin.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TST_TOTAL=1
REQUIRED="hostname grep cat mv cd which chmod rm pftp expect"

################################################################################
# utility functions
################################################################################
function tc_local_setup()
{
	LOGFILE=$TMPBASE/fiv_ftp_log	# use a name that will be the same from one
					# invocation to the next

	[ "$REQUEST" = "STOP_SERVER" ] && return	# server will stop in tc_local_cleanup

	systemctl status vsftpd &> /dev/null
	[ $? -eq 0 ] && status=1
	[ $? -ne 0 ] && status=0
	
	! [ -f "$LOGFILE" ]
	tc_break_if_bad $? "Sorry, vsftpd is already in use for another purpose!" || exit

	local VSFTP_USER=nobody
	# see if user nobody exists
	if ! grep nobody /etc/passwd &>/dev/null ; then
		 tc_add_user_or_break &>/dev/null
		 VSFTP_USER=$temp_user
	fi
	 
	[ -e /etc/vsftpd/vsftpd.conf ] && mv /etc/vsftpd/vsftpd.conf $TMPBASE

	# The config file use for testing
	cat > /etc/vsftpd/vsftpd.conf <<-EOF
	#
	# Allow anonymous FTP?
	anonymous_enable=YES
	#
	# Uncomment this to allow local users to log in.
	local_enable=YES
	#
	# Uncomment this to enable any form of FTP write command.
	write_enable=YES
	#
	# Uncomment this to allow the anonymous FTP user to upload files. This only
	# has an effect if the above global write enable is activated. Also, you will
	# obviously need to create a directory writable by the FTP user.
	anon_upload_enable=YES
	#
	# Uncomment this if you want the anonymous FTP user to be able to create
	# new directories.
	anon_mkdir_write_enable=YES
	#
	# Activate directory messages - messages given to remote users when they
	# go into a certain directory.
	dirmessage_enable=YES
	#
	# Activate logging of uploads/downloads.
	xferlog_enable=YES
	#
	# Make sure PORT transfer connections originate from port 20 (ftp-data).
	connect_from_port_20=YES
	#
	# If you want, you can arrange for uploaded anonymous files to be owned by
	# a different user. Note! Using "root" for uploaded files is not
	# recommended!
	chown_uploads=YES
	chown_username=$VSFTP_USER
	#
	# You may override where the log file goes if you like. The default is shown
	# below.
	#xferlog_file=$LOGFILE
	vsftpd_log_file=$LOGFILE
	#
	# By default the server will pretend to allow ASCII mode but in fact ignore
	# the request. Turn on the below options to have the server actually do ASCII
	# mangling on files when in ASCII mode.
	# Beware that turning on ascii_download_enable enables malicious remote parties
	# to consume your I/O resources, by issuing the command "SIZE /big/file" in
	# ASCII mode.
	# These ASCII options are split into upload and download because you may wish
	# to enable ASCII uploads (to prevent uploaded scripts etc. from breaking),
	# without the DoS risk of SIZE and ASCII downloads. ASCII mangling should be
	# on the client anyway..
	ascii_upload_enable=YES
	ascii_download_enable=YES
	#
	# You may fully customise the login banner string:
	ftpd_banner=Welcome to FIV testing vsftpd!! 
	#
	# You may activate the "-R" option to the builtin ls. This is disabled by
	# default to avoid remote users being able to cause excessive I/O on large
	# sites. However, some broken FTP clients such as "ncftp" and "mirror" assume
	# the presence of the "-R" option, so there is a strong case for enabling it.
	ls_recurse_enable=YES

	pam_service_name=vsftpd
	listen=YES
	EOF
	
	tc_executes vsftpd
	tc_fail_if_bad $? "vsftpd not properly installed" || exit

	local mcmd=`which vsftpd`	
	
	tc_service_restart_and_wait vsftpd
	tc_fail_if_bad $? "vsftpd not properly restarted" || exit
	tc_info "Started vsftpd"

        if [ ! -d /srv/ftp/incoming ];then
  		mkdir -p /srv/ftp/incoming
		chmod a+wx /srv/ftp/incoming 
 	fi
}

function tc_local_cleanup()
{
	[ "$REQUEST" = "START_SERVER" ] && return	# don't stop server. Do an exit
							# instead of return so temp dir and files 
							# stay alive.
	[ -e $TMPBASE/vsftpd.conf ] && mv $TMPBASE/vsftpd.conf /etc/vsftpd/
	
	rm -rf $LOGFILE
	if [ x$status == x1 ]; then
	    tc_service_start_and_wait vsftpd 
	    return
	fi
 	tc_service_stop_and_wait vsftpd	
}

################################################################################
# testcase functions
################################################################################

#
# test file xfer via vsftpd
#
#   $1  A name to register this instance of the test
#   $2  The vsftpd host ip address to use
#
function TC_vsftpd()
{	
	(($# == 2))
	tc_break_if_bad $? "INTERNAL SCRIPT ERROR: $FUNCNAME requires two arguments" || exit

	local name=$1
	local ip=$2
	local exp_path=`which expect`

	#
	rm -rf /srv/ftp/incoming/*

	tc_register "vsftpd $name"
        local filename="send_this_file"
	local my_srchstring="findthis$$"
	tc_add_user_or_break &>/dev/null || return
	
	# create a test file
	cat > $TCTMP/$filename <<-EOF
	this is a test file to be sent by ftp
	for the purpose of testing vsftpd.
	now insert a $my_srchstring
	that's all folks.
	EOF

	cat > $TCTMP/exp1.exp <<-EOF
	#!$exp_path -f
	spawn pftp -p $ip
	expect "Name ($ip:root):"
	send "$TC_TEMP_USER\r"
	expect "Password:"
	send "$TC_TEMP_PASSWD\r"
	expect "ftp>"
	send "cd /srv/ftp/incoming/\r"
	send "send ./$filename\r"
	sleep 3
	expect "ftp>"
	send "quit\r"
	EOF

	cd $TCTMP
	chmod a+x $TCTMP/exp1.exp
        $TCTMP/exp1.exp >$stdout 2>$stderr
        tc_fail_if_bad $? "ftp send failed"

	tc_wait_for_file /srv/ftp/incoming/$filename; RC=$?
	if [ $name = ipv4 ]; then
                [ $RC -ne 0 ] && return $RC
        fi
	tc_fail_if_bad $RC "not able to send file using vsftpd"
	
	grep -q $my_srchstring /srv/ftp/incoming/$filename 2>$stderr
	tc_pass_or_fail $? "file differs after ftp put/get" || return

}

################################################################################
# main
################################################################################

REQUEST=$1	# special requests from mod_php5 ftp test

tc_setup

[ "$REQUEST" ] && tc_register "$REQUEST" && tc_pass # Keep PAN happy
[ "$REQUEST" = "START_SERVER" ] && exit	# server was started in tc_local_setup
[ "$REQUEST" = "STOP_SERVER" ] && exit	# server will stop in tc_local_cleanup

# Check if supporting utilities are available
tc_exec_or_break  $REQUIRED || exit
tc_root_or_break || exit 

# IPv4 Test
IP_ADDR=$(hostname -i)
set $IP_ADDR
while [ $1 ]; do
        TC_vsftpd ipv4 $1; VAR=$?
        if [ $VAR -ne 0 ]; then
                shift
        else
                break
        fi
done

[ $VAR -ne 0 ] && tc_fail_if_bad $VAR "not able to send file using vsftpd"	

tc_ipv6_info || exit

cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf_save
sed 's/listen=YES/listen=NO/g' /etc/vsftpd/vsftpd.conf_save > /etc/vsftpd/vsftpd.conf
echo "listen_ipv6=YES" >> /etc/vsftpd/vsftpd.conf
tc_service_restart_and_wait vsftpd

# IPv6 Global Address Test
[ "$TC_IPV6_global_ADDRS" ] && TC_vsftpd ipv6-global $TC_IPV6_global_ADDRS

# IPv6 Host Address Test
[ "$TC_IPV6_host_ADDRS" ] && TC_vsftpd ipv6-host $TC_IPV6_host_ADDRS

# IPv6 Link Address Test
[ "$TC_IPV6_link_ADDRS" ] && TC_vsftpd ipv6-link $TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
