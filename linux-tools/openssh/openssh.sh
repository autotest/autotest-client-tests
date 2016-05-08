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
## File :	openssh.sh
##
##		Description:  Test basic functionality of scp - secure copy
##			      Test ssh-keygen - authentication key generation
##			      Test OpenSSH SSH client (remote login program)
##
##		Author:		Yu-Pao Lee, yplee@us.ibm.com
###########################################################################################
## source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

# global variables
started_sshd="no"

################################################################################
# utility functions for this testcase
################################################################################

expcmd=`which expect`
host="localhost"
host2=$host	# for [bracketed] ipv6 addr with scp
prompt=':::'
sshd_port=22

function tc_local_cleanup()
{
	if [ "$started_sshd" = "yes" ] ; then
		systemctl stop sshd
		tc_info "Stopped sshd."
	fi
	[ -e $TMPBASE/sshd_config ] && mv $TMPBASE/sshd_config /etc/ssh/
}

function tc_local_setup()
{
	tc_exec_or_break grep expect cat ls su ssh ssh-keygen scp chmod || return
	tc_root_or_break || return 

	if tc_is_busybox diff ; then
		DIFF_OPTS="-w -b"
	else
		DIFF_OPTS="-w -B"
	fi

	tc_add_user_or_break || return
	echo "PS1=$prompt" >> /home/$TC_TEMP_USER/.bashrc
	chown -R $TC_TEMP_USER $TCTMP

	DIFF="diff ${DIFF_OPTS}"
	tc_executes diff || {
		DIFF=true
		tc_info "Without diff, we rely only on commands' return codes"
	}
	[ -e /etc/ssh/sshd_config ] && cp /etc/ssh/sshd_config $TMPBASE
	sed '/AuthorizedKeysFile/ d' <$TMPBASE/sshd_config >/etc/ssh/sshd_config
	systemctl restart sshd  >$stdout 2>$stderr
	tc_fail_if_bad $? "sshd did not start." || return
}

################################################################################
# test functions
################################################################################

#
# installation/startup check
#
function install_check()
{
	tc_register "installation/startup check"
	systemctl status sshd >$stdout 2>$stderr
	if [ $? -ne 0 ]; then
		systemctl start sshd >$stdout 2>$stderr
		tc_fail_if_bad $? "sshd did not start." || return
		tc_info "Started sshd for this testcase"
		tc_wait_for_active_port $sshd_port
		tc_fail_if_bad $? "could not start sshd" || return
		started_sshd="yes"
	fi
	tc_pass_or_fail 0	# pass if we get this far
}

#
# testssh	ssh functionality
#
function testssh()	# ssh to login to a machine
{
	tc_register "ssh to login to a machine ($1)"

	# start fresh each time
	rm -rf /home/$TC_TEMP_USER/.ssh

	# create expect file to create a login session to a machine
	cat > $TCTMP/expcmd <<-EOF
		#!$expcmd -f
		set timeout 60
		proc abort1 {} { exit 1 }
		proc abort2 {} { exit 2 }
		proc abort3 {} { exit 3 }
		proc abort4 {} { exit 4 }
		proc abort5 {} { exit 5 }
		spawn su - $TC_TEMP_USER
		expect {
			timeout abort1
			"$prompt" { send "ssh $TC_TEMP_USER@$host\r" }
		}
		expect {
			timeout abort2
			"(yes/no)?" { send "yes\r" }
		}
		expect {
			timeout abort3
			"assword:" { send "$TC_TEMP_PASSWD\r" }
		}
		sleep 2
		expect {
			timeout abort4
			"$prompt" { send "exit\r" }
		}
		sleep 2
		expect {
			timeout abort5
			"$prompt" { send "exit\r" }
		}
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/expcmd
	
	$TCTMP/expcmd >$stdout 2>$stderr
	tc_pass_or_fail $? "ssh failed." 
}

#
# testscp	scp functionality"
#
function testscp()	# scp - secure copy a file
{
	tc_register "scp - secure copy a file ($1)"

	# start fresh each time
	rm -rf /home/$TC_TEMP_USER/.ssh
	
	# create expect file to issue scp command
	rm -rf /home/$TC_TEMP_USER/tmp_dir1 &>/dev/null
	mkdir -p /home/$TC_TEMP_USER/tmp_dir1
	touch /home/$TC_TEMP_USER/aaa
	chown -R $TC_TEMP_USER  /home/$TC_TEMP_USER
	cat > $TCTMP/expcmd <<-EOF
		#!$expcmd -f
		set timeout 60
		proc abort1 {} { exit 1 }
		proc abort2 {} { exit 2 }
		proc abort3 {} { exit 3 }
		proc abort4 {} { exit 4 }
		proc abort5 {} { exit 5 }
		spawn su - $TC_TEMP_USER
		expect {
			timeout abort1
			"$prompt" { send "scp aaa $TC_TEMP_USER@$host2:./tmp_dir1\r"}
		}
		expect {
			timeout abort2
			"(yes/no)?" { send "yes\r" }
		}
		expect {
			timeout abort3
			"assword:" { send "$TC_TEMP_PASSWD\r" }
		}
		expect {
			timeout abort4
			"$prompt" { send "ls ./tmp_dir1/ > $TCTMP/file1\r" }
		}
		expect {
			timeout abort5
			"$prompt" { send "exit\r" }
		}
		expect eof
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/expcmd
	
	$TCTMP/expcmd >$stdout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return
	
	# create the expected output
	cat > $TCTMP/file2 <<-EOF
		aaa
	EOF
	
	$DIFF $TCTMP/file1 $TCTMP/file2 >$stdout 2>$stderr
	tc_pass_or_fail $? "scp failed." "expected to see aaa"
}


#
# scp - to secure copy a file using keyfiles
# Must first run testkeygen
#
function testscpkey()
{
	tc_register "scp using keyfiles ($1)"
	
	# issue scp. It should require no password for scp
	touch /home/$TC_TEMP_USER/bbb
	rm -rf /home/$TC_TEMP_USER/tmp_dir2 &>/dev/null
	mkdir -p /home/$TC_TEMP_USER/tmp_dir2
	mv /home/$TC_TEMP_USER/.ssh/id_dsa.pub /home/$TC_TEMP_USER/.ssh/authorized_keys2
	chown -R $TC_TEMP_USER  /home/$TC_TEMP_USER
	cat > $TCTMP/expcmd <<-EOF
		#!$expcmd -f
		set timeout 60
		proc abort5 {} { exit 5 }
		proc abort6 {} { exit 6 }
		proc abort7 {} { exit 7 }
		proc abort8 {} { exit 8 }
		proc abort9 {} { exit 9 }
		spawn su - $TC_TEMP_USER
		expect {
			timeout abort5
			"$prompt" {
				send "scp ~/bbb $TC_TEMP_USER@$host2:tmp_dir2/\r"
			}	
		}
		expect {
			timeout abort6
			"(yes/no)?" { send "yes\r" }
		}
		expect {
			timeout	abort7
			"$prompt" { send "ls ~/tmp_dir2/ > $TCTMP/fileA\r"}
			"assword:" abort8
		}
		expect {
			timeout abort9
			"$prompt" { send "exit\r" }
		}
		expect eof
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/expcmd
	
	$TCTMP/expcmd >$stdout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return

	# create the expected output
	cat > $TCTMP/fileB <<-EOF
	bbb
	EOF
	
	$DIFF $TCTMP/fileA $TCTMP/fileB >$stdout 2>$stderr
	tc_pass_or_fail $? "scp failed." "expected to see bbb"
}


#
# testkeygen	ssh-keygen functionality
#
function testkeygen()	# ssh-keygen to generate keys
{
	tc_register "ssh-keygen -t dsa to generate keys used with DSA authentication"

	# start fresh each time
	rm -rf /home/$TC_TEMP_USER/.ssh/

	# create expect file to issue ssh-keygen to generate dsa keys 
	cat > $TCTMP/expcmd <<-EOF
		#!$expcmd -f
		set timeout 240
		proc abort1 {} { exit 1 }
		proc abort2 {} { exit 2 }
		proc abort3 {} { exit 3 }
		proc abort4 {} { exit 4 }
		proc abort5 {} { exit 5 }
		spawn su - $TC_TEMP_USER
		expect {
			timeout abort1	
			"$prompt" { send "ssh-keygen -b 1024  -t dsa\r" }
		}
		expect {
			timeout abort2
			"Enter file" { send "\r" }
		}
		expect {
			timeout abort3
			"passphrase" { send "\r" }
		}
		expect {
			timeout abort4
			"same passphrase" { send "\r" }
		}
		expect {
			timeout abort5
			"$prompt" { send "exit\r" }
		}
		expect eof
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/expcmd

	tc_info "running \"ssh-keygen -b 1024 -t dsa\". This takes a few seconds ..."
	
	SECONDS=0
	$TCTMP/expcmd >$stdout 2>$stderr
	tc_fail_if_bad $? "expect file failed." || return
	tc_info "$SECONDS seconds to generate key"
	
	ls /home/$TC_TEMP_USER/.ssh/ > $TCTMP/keysfile1

	# create the expected output
	cat > $TCTMP/keysfile2 <<-EOF
		id_dsa
		id_dsa.pub
	EOF
	
	$DIFF $TCTMP/keysfile1 $TCTMP/keysfile2 >$stdout 2>$stderr
	tc_pass_or_fail $? "ssh-keygen failed." "expected to see id_dsa and id_dsa.pub"
}

################################################################################
# main
################################################################################

TST_TOTAL=5

tc_setup			# standard setup

install_check
testssh ipv4 &&
testscp ipv4 &&
testkeygen && testscpkey ipv4	# testscpkey depends on testkeygen

tc_ipv6_info || exit
[ "$TC_IPV6_host_ADDRS" ] || exit
tc_info "=========== begin ipv6 host scope ============"
((TST_TOTAL+=4))
host="$TC_IPV6_host_ADDRS"
tc_info "Using $host"
host2="\\[$host\\]"
testssh ipv6-host &&
testscp ipv6-host &&
testkeygen &&		# must redo since above two tests delete key files.
testscpkey ipv6-host

[ "$TC_IPV6_global_ADDRS" ] || exit
tc_info "=========== begin ipv6 global scope ============"
((TST_TOTAL+=4))
host=$TC_IPV6_global_ADDRS
tc_info "Using $host"
host2="\\[$host\\]"
testssh ipv6-global &&
testscp ipv6-global &&
testkeygen &&		# must redo since above two tests delete key files.
testscpkey ipv6-global
