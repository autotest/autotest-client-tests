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
##                                                                                        ##
############################################################################################
#
# File :	audit.sh
#
# Description:	Tests for audit package.
#
# Author:	Gowri Shankar <gowrishankar.m@in.ibm.com>
#
################################################################################
# source the utility functions
################################################################################
#cd $(dirname $0)
#LTPBIN="${PWD%%/testcases/*}/testcases/bin"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
auditdconf="/etc/audit/auditd.conf"
auditd="auditd.service"
installed="auditd auditctl ausearch aureport autrace audispd"
required="cat awk egrep sed"
auditd_running="no"
pro_cmd="/proc/cmdline"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return
        tc_check_kconfig CONFIG_AUDIT;kconfig=$?
        [ $kconfig -ne 0 ] && tc_conf "CONFIG_AUDIT  kernel configuration not enabled" && exit
        # check if audit condtion set for s390x machine
        grep -qi "audit" $pro_cmd
        if [ $? -eq 0 ]; then 
        AUDIT_ENABLE=$(sed 's/.*audit_enable=\([0-9]*\).*/\1/' $pro_cmd)
        AUDIT_VALUE=$(sed 's/.*audit=\([0-9]*\).*/\1/' $pro_cmd)
        AUDIT_DEBUG=$(sed 's/.*audit_debug=\([0-9]*\).*/\1/' $pro_cmd)
        if [[ ("$AUDIT_ENABLE" -eq "0") && ("$AUDIT_VALUE" -eq "0") && ("$AUDIT_DEBUG" -eq "0") ]]; then
        tc_conf "Audit Services are disable at kernal please check the audit status" || exit 
        fi
        fi

	# back up installed configuration
	mv -f $auditdconf $TCTMP/auditd.conf.installed

	# create test config for audit daemon
	tc_info "create test specific audit config"
	sed "s#^log_file.*#log_file = $TCTMP/audit.log#" \
		< $TCTMP/auditd.conf.installed \
		> $auditdconf
	tc_break_if_bad $? "creating test config failed" || return

	# shutdown audit daemon, if running
	if systemctl status $auditd &>/dev/null; then
		auditd_running="yes"
		tc_info "stopping currently running auditd"
		service auditd stop &>/dev/null	
                sleep 20
	fi

	# start audit daemon with test config
	service auditd restart &>/dev/null
	tc_break_if_bad $? "failed to start auditd with test config"

	# make sure that, test key is not existing before all tests.
	sleep 10
	ausearch -k test-key 2>$stderr 1>$stdout
	if [ "$stderr" = "<no matches>" ]; then
		tc_break "auditd is not started with test config"
		return
	fi
}

function tc_local_cleanup()
{
	# stop our instance of audit daemon
	service auditd stop &>/dev/null
        sleep 20

	# restore installed configuration
	mv -f $TCTMP/auditd.conf.installed $auditdconf

	# restart audit daemon with original config, if needed
	if [ "$auditd_running" = "yes" ]; then
		tc_service_start_and_wait auditd
		tc_break_if_bad $? "failed to restart auditd after test"
	fi
}

#
# test 1
#  check if audit daemon is started with test configuration
#
function test_basics()
{
	tc_register "check audit daemon PID"
	local pid_from_tool=`auditctl -s |grep pid  | sed 's/[^0-9]*//g'`
	local pid_from_ps=$(ps --no-heading -o pid -C auditd)

	if [ $pid_from_tool != $pid_from_ps ]; then
		tc_fail "audit daemon found to be different. skipping all tests!"
		return
	fi

	# the test passes if it reaches here
	tc_pass
}

#
# test 2
#  add a watch on particular test-file with arbitrary filter key test-key
#  that generates records for "reads, writes, executes, appends" on test-file.
function test_file_audit()
{
	tc_register "testing audit on file objects"

	# remove the current audit rules
	auditctl -D &>/dev/null

	# to add new audit rule
	auditctl -w $TCTMP/test-file -k test-key -p rwxa 2>$stderr 1>$stdout
	tc_fail_if_bad $? "adding file audit rule failed" || return

	# check if rule is added
	auditctl -l|egrep 'test-key' 2>$stderr 1>$stdout
	tc_fail_if_bad $? "added rule not found" || return

	# trigger an audit event
	touch $TCTMP/test-file
	sleep 10

	# check if the event is captured.
	ausearch -k test-key -x touch 2>$stderr 1>$stdout
	tc_pass_or_fail $? "file update is not captured"
}

#
# test 3
#  add a watch on particular system call with arbitrary filter key test-key
#  on a particular process id.
function test_syscall_audit()
{
	tc_register "testing audit on a syscall"

	# remove the current audit rules
	auditctl -D &>/dev/null

	# to add new audit rule
	if [ "$TC_OS_ARCH" = "x86_64" -o "$TC_OS_ARCH" = "ppc64" -o "$TC_OS_ARCH" = "s390x" -o "$TC_OS_ARCH" = "ppc64le" ]; then

	auditctl -a exit,always -F arch=b64 -F ppid=$$ -S utimensat -k test-key 2>$stderr 1>$stdout
	else
	auditctl -a exit,always -F arch=b32 -S utimensat -F ppid=$$ -k test-key 2>$stderr 1>$stdout 
	fi

	tc_fail_if_bad $? "adding syscall audit rule failed" || return

	# check if rule is added
	auditctl -l|egrep 'test-key' 2>$stderr 1>$stdout
	tc_fail_if_bad $? "added rule not found" || return

	# trigger an audit event
	touch $TCTMP/test-file

	# check if the event is captured.
	ausearch -k test-key -x touch 2>$stderr 1>$stdout
	tc_pass_or_fail $? "file update is not captured"
}

#
# test 4
#  test autrace with "touch" command as argument.
#  delete all rules before running the program, else the command fails.
#  run autrace with "touch test-file" as arguments and check the output
#  for ausearch command to run
function test_audit_trace()
{
	tc_register "testing autrace with touch command"

	# remove the current audit rules
	auditctl -D &>/dev/null
	ausearch -k test-key -x touch

	# run autrace on touch command
	autrace $(which touch) $TCTMP/test-file 2>$stderr 1>$stdout
	tc_fail_if_bad $? "audit trace failed to run" || return

	# check if the event is captured.
	ausearch -k test-key -x touch 2>$stderr 1>$stdout
	tc_fail_if_bad $? "file update is not captured" || return

	# extract ausearch from $stdout and run it.
	if [[ $stdout =~ \'(.*)\' ]]; then
		$(${BASH_REMATCH[1]} &>/dev/null)
		tc_fail_if_bad $? "ausearch found in output failed" || return
	fi

	# the test passes if it reaches here
	tc_pass
}

#
# test 5
#  test aulastlog for root
function test_audit_logging()
{
	tc_register "testing aulastlog for root user"
	aulastlog -u root 2>$stderr 1>$stdout
	tc_pass_or_fail $? "aulastlog is broken"
}

################################################################################
# main
################################################################################
TST_TOTAL=5
tc_setup
tc_get_os_arch

test_basics && {
	test_file_audit
	test_syscall_audit
	test_audit_trace
	test_audit_logging
}
