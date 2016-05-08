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
## File :	cifs-utils.sh
##
## Description:	Test cifs-utils package
##
## Author:	Gopal Kalita <gokalita@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

# global variables
REQUIRED="which expect grep mount umount"

# environment variables
password=f1vtest
conf="/etc/samba/smb.conf"

EXPECT=$(which expect)
SMBPASS=$(which smbpasswd)

remmnt=""
localmnt=""
needsrestart="no"

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

        # remember to restart samba in tc_local_cleanup if it was running upon entry
        tc_service_status smb && needsrestart="yes"
        sleep 4

	[ -f $conf ] && mv $conf $TCTMP # save original
	cat > $conf <<-EOF
		[global]
			workgroup = FIVTEST
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
	
}

#
# Local Cleanup
#
function tc_local_cleanup()
{
	# All these activities are only needed in case of earlier failures

	# get rid of extraneous samba mount
	umount $localmnt

	# remove temp user from smbpasswd file
	[ "$TC_TEMP_USER" ] && $SMBPASS -x $TC_TEMP_USER &>/dev/null

	# stop this testcase's instance of samba
	tc_service_stop_and_wait smb

	# restore config file if it was saved
	[ -e "$TCTMP/$conf" ] && mv $TCTMP/$conf $conf

        # restart samba if it was running before this testcase started
        [ "$needsrestart" = "yes" ] && tc_service_start_and_wait smb

}


#
# smbpassword	Set samba password for temp user.
#
function smbpassword()
{
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
        tc_break_if_bad $? "Could not set samba password" "rc=$?"
}


################################################################################
# testcase functions
################################################################################

# this test checks basic options of ro, rw, exec and noexec

function runtest()
{	
	# start server
	tc_service_restart_and_wait smb 

        tc_info "wait a few seconds for the samba server to stabilize."
        sleep 4s

	tc_service_status smb 
	tc_fail_if_bad $? "samba server not started" || return

	#### mount.cifs with ro option ####
	tc_register "mount.cifs with ro option"
	mount.cifs -o ro,username=$TC_TEMP_USER,passwd=$password //$host/tstshare $localmnt >$stdout 2>$stderr
	tc_fail_if_bad $? "mount.cifs with ro failed"
        
	[ -f $localmnt/testfile ]
	tc_fail_if_bad $? "Expected file in share does not exist!"
	
	mount | grep -iq "tstshare.*myshare.*type cifs" && ! cp /bin/pwd $localmnt &>/dev/null
	tc_pass_or_fail $? "mount did not list the cifs partition"
	
	umount $localmnt
	tc_fail_if_bad $? "unmount failed"


	#### mount.cifs with rw option ####
	tc_register "mount.cifs with rw option"
	mount.cifs -o rw,username=$TC_TEMP_USER,passwd=$password //$host/tstshare $localmnt >$stdout 2>$stderr
	tc_fail_if_bad $? "mount.cifs rw failed"

	[ -f $localmnt/testfile ]
	tc_fail_if_bad $? "Expected file in share does not exist!"

	mount | grep -iq "tstshare.*myshare.*type cifs" && cp /bin/pwd $localmnt
	tc_pass_or_fail $? "mount did not list the cifs partition"

	umount $localmnt
	tc_fail_if_bad $? "unmount failed"


	#### mount.cifs with noexec option #####
	tc_register "mount.cifs with noexec option"
	mount.cifs -o rw,noexec,username=$TC_TEMP_USER,passwd=$password //$host/tstshare $localmnt >$stdout 2>$stderr
	tc_fail_if_bad $? "mount.cifs rw,noexec failed"

	[ -f $localmnt/testfile ]
	tc_fail_if_bad $? "Expected file in share does not exist!"

	mount | grep -iq "tstshare.*myshare.*type cifs" && cp /bin/pwd $localmnt && ! $localmnt/pwd &>/dev/null
	tc_pass_or_fail $? "mount did not list the cifs partition"

	umount $localmnt
	tc_fail_if_bad $? "unmount failed"


	#### mount.cifs with exec option ####
	tc_register "mount.cifs with exec option"
	mount.cifs -o rw,exec,username=$TC_TEMP_USER,passwd=$password //$host/tstshare $localmnt >$stdout 2>$stderr
	tc_fail_if_bad $? "mount.cifs rw, exec failed"

	[ -f $localmnt/testfile ]
	tc_fail_if_bad $? "Expected file in share does not exist!"

	mount | grep -iq "tstshare.*myshare.*type cifs" && cp /bin/pwd $localmnt && $localmnt/pwd &>/dev/null
	tc_pass_or_fail $? "mount did not list the cifs partition"

	umount $localmnt
	tc_fail_if_bad $? "unmount failed"

}


################################################################################
# MAIN
################################################################################

TST_TOTAL=4
tc_setup

smbpassword && \
host=localhost runtest
