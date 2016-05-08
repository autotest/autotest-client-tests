#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
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
################################################################################
#
# File :	samba.sh
#
# Description:	Test samba package
#
# Author:	Robb Romans <robb@austin.ibm.com>
#
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

# global variables
REQUIRED="which awk basename cat chmod expect grep ls mount mv \
	rm umount"
netbios_name=	# set in tc_local_setup

# environment variables
password=f1vtest
group="users"
conf="/etc/samba/smb.conf"

EXPECT=$(which expect)
SMBPASS=$(which smbpasswd)
STARTSMB="tc_service_start_and_wait smb"
STOPSMB="tc_service_stop_and_wait smb"
SMBSTAT="tc_service_status smb"

# keep track of things that might need to be cleaned up in "tc_local_cleanup"
needsstop="no"
needsrestart="no"
needsumount="no"

remmnt=""
localmnt=""

################################################################################
# utility functions
################################################################################

#
# Setup specific to this test
#
function tc_local_setup()
{
	remmnt="$TCTMP/share"
	localmnt="$TCTMP/myshare"

	tc_exec_or_break $REQUIRED || return
	tc_root_or_break || return

	# busybox does not support usrquota mounts
	if ls -la `type -p mount` | grep busybox >/dev/null ; then
		tst_brkm TBROK NULL "Busybox does not support samba mounts"
		return 1
	fi
	# user to share data
	tc_add_user_or_break >/dev/null || return
	# set netbios name = to hostname
#	[ "$HOST" ]
#	tc_break_if_bad $? "env variable HOST is empty" || return
	if [ "$HOST" ] ; then
		netbios_name=$HOST
	else 
		netbios_name=`hostname`
		HOST=`hostname`
	fi
	# remember to restart samba if it was running upon entry
	$SMBSTAT &>/dev/null && needsrestart="yes"
	sleep 1

	[ -f $conf ] && mv $conf $TCTMP # save original
	cat > $conf <<-EOF
		[global]
			workgroup = FIVTEST
			netbios name = $netbios_name
			#encrypt passwords = Yes
			#map to guest = Bad User
			#pam password change = Yes
			#unix password sync = Yes
			#domain master = True
			lanman auth = Yes
			client lanman auth = Yes
			security = user

		[tstshare]
			comment = share for testing
			path = $remmnt
			writeable = yes
			browseable = yes
			guest ok = yes
	EOF

	mkdir -p $remmnt		# create share directory
	echo "hello" > $remmnt/testfile	# create file to look for when mounted
	mkdir -p $localmnt		# create mount point
	chown -R $TC_TEMP_USER:users $remmnt
	
	( tc_service_status nmb &>/dev/null && nmbstart="yes" )|| nmbstart="no"
	( tc_service_status winbind &>/dev/null && winbindstart="yes") || winbindstart="no"
}

#
# Cleanup specific to this program
#
function tc_local_cleanup()
{
	# All these activities are only needed in case of earlier failures

	# get rid of extraneous samba mount
	[ "$needsumount" = "yes" ] && umount $localmnt

	# remove temp user from smbpasswd file
	[ "$TC_TEMP_USER" ] && $SMBPASS -x $TC_TEMP_USER &>/dev/null

	# stop this testcase's instance of samba
	[ "$needsstop" = "yes" ] && $STOPSMB &>/dev/null

	# restore config file if it was saved
	[ -e "$TCTMP/$conf" ] && mv $TCTMP/$conf $conf

	# restart samba if it was running before this testcase started
	[ "$needsrestart" = "yes" ] && $STARTSMB &>/dev/null

	[ "x$nmbstart" = "xyes" ] &&  tc_service_start_and_wait nmb &>/dev/null
	[ "x$windbindstart" = "xyes" ] && tc_start_and_wait winbind &>/dev/null
}

################################################################################
# testcase functions
################################################################################

#
# smbpassword	Set samba password for temp user.
#
function test_smbpassword()
{
	tc_register "smbpasswd"
	cat > $TCTMP/exp2 <<-EOF
		#!$EXPECT -f
		set timeout 5
		proc abort {} { exit 1 }
		set env(USER) root
		set id \$env(USER)
		set host \$env(HOSTNAME)
		spawn $SMBPASS -a $TC_TEMP_USER
		expect {
			timeout abort
			"password:" { send "$password\r" }
		}
		expect {
			timeout abort
			"password:" { send "$password\r" }
		}
		expect eof
	EOF
        chmod +x $TCTMP/exp2 &>/dev/null
        $TCTMP/exp2 >/dev/null 2>$stderr
        tc_pass_or_fail $? "Could not set samba password" "rc=$?"
}

#
# smbstart	Start the samba server with new smb.conf file.
#		Saves curent smb.conf file form later restoration.
#		If samba currently running stop it for later restart.
#
function test_smbstart()
{
	tc_register	"start samba"

	# check host variable
	[ "$HOST" ]
	tc_break_if_bad $? "env variable HOST is empty" || return

	# stop server
	$STOPSMB &>/dev/null # returns 3 on failure, 0 on success
	tc_fail_if_bad $? "Failed to stop samba server!" || return


	needsstop="yes"

	# Start nmb and winbind servers
	tc_service_restart_and_wait nmb &>/dev/null 
	tc_fail_if_bad $? "Failed to start nmb server" || return
	
	tc_service_restart_and_wait winbind &>/dev/null
	tc_fail_if_bad $? "Failed to start winbind server" || return


	# start server
	$STARTSMB &>/dev/null # returns 3 on not running, 0 on running
	tc_fail_if_bad $? "Failed to start samba server!" "rc=$?" || return

        tc_info "wait 10s for the samba server to stabilize"
        sleep 10s

	# check if samba is up
	$SMBSTAT &>/dev/null # returns 3 on not running, 0 on running
	tc_pass_or_fail $? "samba server not running!" "rc=$?"
}

#
# smbmount	Mount a shared directory
#
function test_smbmount()
{
	tc_register	"samba mount"


	# mount share
	needsumount="yes"
	mount -t cifs -o username=$TC_TEMP_USER,passwd=$password \
		//localhost/tstshare $localmnt &>$stderr
	tc_fail_if_bad $? "Failed to mount $localmnt" "rc=$?" || return

	# test share
	[ -f $localmnt/testfile ]
	tc_pass_or_fail $? "Expected file in share does not exist!"
}

#
# smbclient	Test smbclient command
#
function test_smbclient()
{
	tc_register	"smbclient"

	smbclient //$netbios_name/ $password -U $TC_TEMP_USER -L $netbios_name \
	> $TCTMP/output 2>/dev/null
	grep "tstshare *Disk *share for testing" < $TCTMP/output >/dev/null
	tc_fail_if_bad $? "unexpected results from \"smbclient -L $netbios_name\"" \
		"expected to see \"tstshare Disk share for testing\"" \
		"in"$'\n'"`tail -20 $TCTMP/output`" || return

	echo "get testfile $TCTMP/testfile" | \
		smbclient //$netbios_name/tstshare $password -U $TC_TEMP_USER &>/dev/null
	tc_fail_if_bad $? "smbclient get failed" "rc=$?" || return

	[ -s $TCTMP/testfile ]
	tc_fail_if_bad $? "Did not get testfile" || return

	local file_contents="`cat $TCTMP/testfile`"
	[ "$file_contents" = "hello" ]
	tc_pass_or_fail $? "testfile had wrong contents" \
		"expected: \"hello\"" \
		"actual: \"$file_contents\""
}

#
# smbumount	Unmount the shared directory
#
function test_smbumount()
{
	tc_register "samba umount"

	# unmount share
	umount $localmnt &>$stderr
	tc_pass_or_fail $? "Failed to unmount local share!" || return
	needsumount="no"
}

#
# smbstop	Stop the samba server
#
function test_smbstop()
{
	tc_register	"stop samba"

	local result="`$STOPSMB 2>&1`"
	tc_pass_or_fail $? "Failed to stop samba!" "results="$'\n'"$result" || return
	needsstop="no"

}

#
# deluser	Delete the samb user
#
function test_deluser()
{
	tc_register	"delete samb user"

	smbpasswd -x $TC_TEMP_USER > $TCTMP/output 2>$stderr
	tc_pass_or_fail $? "could not delete user $TC_TEMP_USER from smbpasswd file" \
		"rc=$?" "command output:"$'\n'"`cat $TCTMP/output`"
}


# rende: add a new test for cifs-mount subpackage
# SLES10 based mount.cifs doesn't implement "-n" and "-o remount"
# this test checks basic options of ro, rw, and noexec
function test_cifs-mount()
{
	tc_register	"$1"

	# start server
	tc_service_restart_and_wait nmb&>/dev/null 
	tc_service_restart_and_wait winbind &>/dev/null 

        tc_info "wait a few seconds for the samba server to stabilize."
        sleep 4s

	tc_service_status smb &>/dev/null 
	tc_fail_if_bad $? "samba server not started" || return

	mount -t cifs -o ro,username=$TC_TEMP_USER,passwd=$password //$host/tstshare $localmnt &>$stderr &&
		mount | grep -iq "tstshare.*myshare.*type cifs" && ! cp /bin/pwd $localmnt &>/dev/null
	tc_fail_if_bad $? "mount.cifs ro failed" || return
	umount $localmnt
	tc_info "mount.cifs TC1 OK"

	mount -t cifs -o rw,username=$TC_TEMP_USER,passwd=$password //$host/tstshare $localmnt &>$stderr &&
		mount | grep -iq "tstshare.*myshare.*type cifs" && cp /bin/pwd $localmnt && rm $localmnt/pwd
	tc_fail_if_bad $? "mount.cifs rw failed" || return
	umount $localmnt
	tc_info "mount.cifs TC2 OK"

	mount -t cifs -o rw,noexec,username=$TC_TEMP_USER,passwd=$password //$host/tstshare $localmnt &>$stderr &&
		mount | grep -iq "tstshare.*myshare.*type cifs" && cp /bin/pwd $localmnt && ! $localmnt/pwd &>/dev/null
	tc_fail_if_bad $? "mount.cifs rw,noexec failed" || return
	umount $localmnt
	tc_info "mount.cifs TC3 OK"

	tc_pass_or_fail 0 

}


################################################################################
# MAIN
################################################################################

TST_TOTAL=1
tc_setup


if [ "$1" == "cifs-mount" ] ; then
	test_smbpassword && \
	host=localhost test_cifs-mount cifs-ipv4 &&
	host=ipv6-localhost test_cifs-mount cifs-ipv6
else
	test_smbpassword && \
	test_smbstart && \
	test_smbmount && \
	test_smbclient && \
	test_smbumount && \
	test_smbstop && \
	test_deluser
fi
