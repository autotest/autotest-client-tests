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
# File :	samba-winbind.sh
#
# Description:	Test samba-winbind package
#
# Author:	GONG Jie <gongjie@cn.ibm.com>
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
workgroup="BUILTIN"

STARTWINBIND="tc_service_start_and_wait winbind"
STOPWINBIND="tc_service_stop_and_wait winbind"
WINBINDSTAT="tc_service_status winbind"

# keep track of things that might need to be cleaned up in "tc_local_cleanup"
needsstop="no"
needsrestart="no"
needsumount="no"

################################################################################
# utility functions
################################################################################

#
# Setup specific to this test
#
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return
	tc_root_or_break || return

	if [ "$HOST" ]
	then
		netbios_name=$HOST
	else 
		netbios_name=`hostname`
		HOST=`hostname`
	fi
	# remember to restart winbind if it was running upon entry
	$WINBINDSTAT &>/dev/null && needsrestart="yes"
	sleep 1
}

#
# Cleanup specific to this program
#
function tc_local_cleanup()
{
	# All these activities are only needed in case of earlier failures

#	# get rid of extraneous samba mount
#	[ "$needsumount" = "yes" ] && umount $localmnt

#	# remove temp user from smbpasswd file
#	[ "$TC_TEMP_USER" ] && $SMBPASS -x $TC_TEMP_USER &>/dev/null

	# stop this testcase's instance of winbind
	[ "$needsstop" = "yes" ] && $STOPWINBIND &>/dev/null

	# restore config file if it was saved
	[ -e "$savedconf" ] && mv $savedconf $conf

	# restart winbind if it was running before this testcase started
	[ "$needsrestart" = "yes" ] && $STARTWINBIND &>/dev/null
}

################################################################################
# testcase functions
################################################################################

#
# winbindstart	Start the winbind server with new smb.conf file.
#		Saves curent smb.conf file form later restoration.
#		If winbind currently running stop it for later restart.
#
function test_winbindstart()
{
	tc_register	"start winbind"

	# check host variable
	[ "$HOST" ]
	tc_break_if_bad $? "env variable HOST is empty" || return

	# stop server
	$STOPWINBIND &>/dev/null # returns 3 on failure, 0 on success
	tc_fail_if_bad $? "Failed to stop winbind server!" || return

	# save old config
	[ -e $conf ] && mv $conf $savedconf

	# write new config
	cat > $conf <<-EOF
		[global]
			workgroup = $workgroup
			netbios name = $netbios_name
			encrypt passwords = Yes
			map to guest = Bad User
			pam password change = Yes
			unix password sync = Yes
			security = user
			domain logons = True
			domain master = True
			idmap uid = 10000-20000
			idmap gid = 10000-20000
	EOF
	needsstop="yes"

	# start server
	$STARTWINBIND &>/dev/null # returns 3 on not running, 0 on running
	tc_fail_if_bad $? "Failed to start winbind server!" "rc=$?" || return

	# check if winbind is up
	$WINBINDSTAT &>/dev/null # returns 3 on not running, 0 on running
	tc_pass_or_fail $? "winbind server not running!" "rc=$?"
}

#
# winbindstop	Stop the winbind server
#
function test_winbindstop()
{
	tc_register	"stop winbind"

        $STOPWINBIND >$stdout 2>$stderr
        tc_pass_or_fail $? "Failed to stop winbind!" || return
	needsstop="no"
}

#
# wbinfo_ping	Wbinfo ping
#
function test_wbinfo_ping()
{
	tc_register	"wbinfo ping"
	local n=10
	while !  wbinfo --ping >$stdout 2>$stderr ; do
		((--n)) || break
		sleep 1
	done
	wbinfo --ping >$stdout 2>$stderr
	tc_pass_or_fail $? "could not ping winbindd!" || return
}

function test_wbinfo_domain_info()
{
	tc_register	"wbinfo domain info"
	wbinfo -D $workgroup >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to get domain information!" "rc=$?" || return
	grep '^Name' $stdout | grep $workgroup >/dev/null 2>$stderr
	tc_pass_or_fail $? "Domain information incorrect!" || return
}

################################################################################
# MAIN
################################################################################

TST_TOTAL=4
tc_setup

savedconf="$TCTMP/smbconforig"

test_winbindstart && \
test_wbinfo_ping && \
test_wbinfo_domain_info && \
test_winbindstop
