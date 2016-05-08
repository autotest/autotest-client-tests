#!/bin/sh
############################################################################################
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
## File :        sudo_test.sh
##
## Description:  Test sudo command
##
## Author:      	CSDL  James He <hejianj@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TSTCMD=""	# will hold command to test sudotestadmin and sudotestuser
RMCMD=""	# will hold command to remove module loaded by $TSTCMD

TESTDIR=${LTPBIN%/shared}/sudo
cd $TESTDIR
CONTENT1="user1's temporary file content"
CONTENT2="user2's temporary file content"

################################################################################
# environment functions
################################################################################

#
# local setup
#
function tc_local_setup()
{
	tc_exec_or_break echo cat grep cp || exit
	tc_root_or_break || exit

	# add sudo test users
        tc_add_user_or_break sudotestadmin || exit
        tc_add_user_or_break sudotestuser || exit

	# figure out if a module is available for testing sudotestadmin and sudotestuser
	tc_executes modprobe rmmod &&
	modprobe dummy && {
		RMCMD="$(which rmmod) dummy"
		$RMCMD
		TSTCMD="$(which modprobe) dummy"
		return 0
	}
	tc_executes insmod rmmod && [ -f /opt/fiv/fiv_module/fiv_module.ko ] &&
	insmod /opt/fiv/fiv_module/fiv_module.ko && {
		RMCMD="$(which rmmod) fiv_module"
		$RMCMD
		TSTCMD="$(which insmod) /opt/fiv/fiv_module/fiv_module.ko"
		return 0
	}
	# use hwclock if no module available
	tc_exec_or_break hwclock || return
	TSTCMD="$(which hwclock) --directisa"
}

#
# local cleanup
#
function tc_local_cleanup
{
	[ "$RMCMD" ] && $RMCMD &>/dev/null
	[ -e $TCTMP/sudoers ] && mv $TCTMP/sudoers /etc/sudoers
	[ -e /sbin/sudotest ] && rm -f /sbin/sudotest
}

################################################################################
# testcase functions
################################################################################

function installation_check()
{
	tc_register "installation check"
	tc_executes sudo &&
	tc_exists /etc/sudoers
	tc_pass_or_fail $? "Not installed properly" || return

	# this preserves permissions on original and our test version
	mv /etc/sudoers $TCTMP/sudoers
	cp -ax $TCTMP/sudoers /etc/sudoers
        cat > /etc/sudoers <<-EOF
	User_Alias      SYSTEM_ADMIN = sudotestadmin
	User_Alias      SYSTEM_USER = sudotestuser
	Cmnd_Alias      SU = /bin/su
	Cmnd_Alias      TSTR = $TSTCMD
	Cmnd_Alias      URCP = /bin/cp
	Cmnd_Alias      SUCK = /sbin/sudotest
	Defaults        syslog=auth,log_year,logfile=/var/log/sudo.log
	root    	ALL=(ALL) ALL
	SYSTEM_ADMIN    ALL = NOPASSWD:ALL
	SYSTEM_USER     ALL = NOPASSWD:TSTR,URCP
	SYSTEM_USER     ALL = SUCK,!SU
	EOF

	chmod /etc/sudoers --reference=$TCTMP/sudoers
        cp -f ./sudotest /sbin/
	tc_break_if_bad $? "failed to copy sudotest file " || exit
}

function sudotest01
{
	[ "$TSTCMD" ] || {
		tc_info "skipped sudotestadmin test because no module avbailable to load"
		((--TST_TOTAL))
		return 0
	}
	tc_register	"sudotestadmin $TSTCMD"
	[ "$RMCMD" ] && $RMCMD &>/dev/null

	su - sudotestadmin -c "sudo $TSTCMD" >$stdout 2>$stderr
	tc_pass_or_fail $? "sudotestadmin can not run $TSTCMD as root!"
}

function sudotest02
{
	[ "$TSTCMD" ] || {
		tc_info "skipped sudotestuser test because no module avbailable to load"
		((--TST_TOTAL))
		return 0
	}
	tc_register	"sudotestuser $TSTCMD"
	[ "$RMCMD" ] && $RMCMD &>/dev/null

	su - sudotestuser -c "sudo $TSTCMD" >$stdout 2>$stderr
	tc_pass_or_fail $? "sudotestuser can not run $TSTCMD as root!"
}

function sudotest03
{
	COMMAND="sudo /sbin/sudotest"
	tc_register	"sudotestadmin $COMMAND"
	su - sudotestadmin -c "$COMMAND" >$stdout 2>$stderr
	tc_pass_or_fail $? "sudotestadmin can not run sudotest as root!"
}

function sudotest04
{
	COMMAND="sudo -S /sbin/sudotest"
	tc_register	"sudotestuser $COMMAND"
	su - sudotestuser -c "echo password | $COMMAND" >$stdout 2>&1
	tc_pass_or_fail $? "sudotestuser can not run sudotest as root!"
	
}

function sudotest05
{
	COMMAND="sudo -S /bin/su"
	tc_register	"sudotestuser $COMMAND"
	su - sudotestuser -c "echo password | $COMMAND"  >$stdout 2>&1
	tc_pass_or_fail !$? "sudotestuser can run su as root!"
	
}

function sudotest06
{
	COMMAND="cp -f"
	tc_register	"sudotestadmin $COMMAND"
        echo -n "$CONTENT1" > /home/sudotestadmin/tmpfile
        chown sudotestadmin /home/sudotestadmin/tmpfile
	sudo -u sudotestadmin $COMMAND /home/sudotestadmin/tmpfile /home/sudotestadmin/bakfile >$stdout 2>$stderr
	[ -e /home/sudotestadmin/bakfile ]
        tc_pass_or_fail $? "can not copy sudotestadmin's file from /home/sudotestadmin/tmpfile to /home/sudotestadmin/bakfile"
	
}

function sudotest07
{
	COMMAND="cp -f"
	tc_register	"sudotestuser $COMMAND"
        echo -n "$CONTENT2" > /home/sudotestuser/tmpfile
        chown sudotestuser /home/sudotestuser/tmpfile
	sudo -u sudotestuser $COMMAND /home/sudotestuser/tmpfile /home/sudotestuser/bakfile >$stdout 2>$stderr
	[ -e /home/sudotestuser/bakfile ]
        tc_pass_or_fail $? "can not copy sudotestuser's file from /home/sudotestuser/tmpfile to /home/sudotestuser/bakfile"
	
}

################################################################################
# MAIN
################################################################################
TST_TOTAL=8
tc_setup
installation_check &&
sudotest01 
sudotest02 
sudotest03 &&
sudotest04 &&
sudotest05 &&
sudotest06 &&
sudotest07                                                                                                                                                           
