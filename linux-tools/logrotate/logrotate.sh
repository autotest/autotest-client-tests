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
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

## Author:	Manoj Iyer
###########################################################################################
## source the utility functions

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break grep cat rm || return

	if [ $TC_OS_ARCH = ppcnf ]; then
		ntpdate pool.ntp.org 1>$stdout 2>$stderr
		tc_break_if_bad $? "ntpdate failed, please update system date before running the test"
		# backup the older /var/lib/logrotate.status file
		mv /var/lib/logrotate.status /var/lib/logrotate.status.org
	fi

	# create config file.
	cat >$TCTMP/tst_logrotate.conf <<-EOF
		#****** Begin Config file *******
		# create new (empty) log files after rotating old ones
		create

		# compress the log files
		compress

		/var/log/tst_logfile$$ {
			rotate 2
			weekly
		}
		#****** End Config file *******
	EOF

	# create a log file in /var/log/
	cat >/var/log/tst_logfile$$ <<-EOF
		#****** Begin Log File ********
		# This is a dummy log file.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		Dummy log file used to test logrotate command.
		#****** End Log File ********
	EOF

	return 0
}

#
# tc_local_cleanup
#
function tc_local_cleanup()
{
	if [ $TC_OS_ARCH = ppcnf ]; then
		mv /var/lib/logrotate.status.org /var/lib/logrotate.status
	fi
	rm -f /var/log/tst_logfile$$*
}

#
# test01	Installation check
#
function test01()
{
	tc_register "Installation check"
	tc_executes logrotate
	tc_pass_or_fail $? "logrotate not installed"
}

#
# test02	See that logrotate creates backup of a logfile.
#		Use force option to be sure.
#		Use verbose option to get output that can be compared.
#		See that current log file is emptied.
#
function test02()
{
	tc_register "First rotation"
	tc_info "starting first rotation"

	# Force the rotation.
	logrotate -fv $TCTMP/tst_logrotate.conf  &>$stdout
	tc_fail_if_bad $? "bad results from logrotate -fv" || return

	# Look for some keywords in the output.
	grep -q "reading config file $TCTMP/tst_logrotate.conf" $stdout
		tc_fail_if_bad $? "missing reading" || return
	grep -q "forced from command line (2 rotations)" $stdout
		tc_fail_if_bad $? "missing forced" || return
	grep -q "compressing log with" $stdout
		tc_fail_if_bad $? "missing compressing" || return

	# current log file should now be zero length
	! [ -s /var/log/tst_logfile$$ ]
	tc_fail_if_bad $? "/var/log/tst_logfile$$ should be zero length" || return

	# Check if compressed log file is created.
	tc_exists /var/log/tst_logfile$$.1.gz
	tc_pass_or_fail $? "compressed backup file not creatred."
}

#
# test03	See that a second rotation creates a second log file with
# 		unique name.
#
function test03()
{
	tc_register "Second rotation"
	tc_info "starting second rotation"

	# add a line to log file
	echo "New data" >> /var/log/tst_logfile$$

	# Force the rotation.
	logrotate -fv $TCTMP/tst_logrotate.conf  &>$stdout
	tc_fail_if_bad $? "bad results from logrotate -fv" || return

	# current log file should now be zero length
	! [ -s /var/log/tst_logfile$$ ]
	tc_fail_if_bad $? "/var/log/tst_logfile$$ should be zero length" || return

	# Check if compressed log file is created.
	tc_exists /var/log/tst_logfile$$.2.gz
	tc_pass_or_fail $? "compressed backup file not creatred."
}

#
# test04	See that a third rotation leaves only two backup files.
#
function test04()
{
	tc_register "Third rotation"
	tc_info "starting third rotation"

	# add a line to log file
	echo "New data" >> /var/log/tst_logfile$$

	# Force the rotation.
	logrotate -fv $TCTMP/tst_logrotate.conf  &>$stdout
	tc_fail_if_bad $? "bad results from logrotate -fv" || return

	# current log file should now be zero length
	! [ -s /var/log/tst_logfile$$ ]
	tc_fail_if_bad $? "/var/log/tst_logfile$$ should be zero length" || return

	# Check if compressed log file is created.
	tc_info "Should NOT find /var/log/tst_logfile$$.3.gz ..."
	! tc_exists /var/log/tst_logfile$$.3.gz
	tc_pass_or_fail $? "Too many backup files"
}

#
# main
#

TST_TOTAL=4
tc_get_os_arch
tc_setup

test01 &&
test02 &&
test03 &&
test04
