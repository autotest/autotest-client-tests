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
## File :	telnet.sh
##
## Description:	Test telnet package
##
## Author:	Andrew Pham, apham@austin.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

REQUIRED="telnet in.telnetd chmod grep cat rm expect touch which ps"

IPv6=no
################################################################################
# utility functions
################################################################################

function start_telnet_daemon()
{
	tc_find_port		# sets TC_PORT
	tc_break_if_bad $? "Could not find available port" || return

	# use -debug to start from other than (x)inetd
	if [ $IPver -eq 4 ];then 
		in.telnetd -debug $TC_PORT &
		tc_fail_if_bad $? "Could not start telnet daemon" || return
	else
		in.telnetd -debug6 $TC_PORT &
		tc_fail_if_bad $? "Could not start telnet daemon" || return
	fi

	tc_wait_for_active_port $TC_PORT
	tc_fail_if_bad $? "Telnet daemon not listening on port $TC_PORT"
}

# create a temp user for the telnet
function tc_local_setup()
{
	tc_ipv6_info && IPv6=yes
	tc_add_user_or_break || return
}

function tc_local_cleanup()
{
	rm -f /tmp/my$$testfile* 

	# kill telnetd
	killall in.telnetd &>/dev/null
}

################################################################################
# testcase functions
################################################################################
function TC_telnet1()
{	
	tc_register "telnet"
	local -i IPver=$1
	local TC_HOSTNAME=$2
	start_telnet_daemon -$IPver|| return

	# Create expect scritp
	local expcmd=`which expect`
	cat > $TCTMP/mtelnet <<-EOF
	#!$expcmd -f
	set timeout 3
	set id $TC_TEMP_USER
	set tfile [lindex \$argv 0]
	set tport [lindex \$argv 1]
	proc abort {} { exit 1 }
	spawn /usr/bin/telnet $TC_HOSTNAME \$tport
	expect {
		timeout abort
		"login:" { send "\$id\r" }
	}
	expect {
		timeout abort
		"assword:" { send "$TC_TEMP_PASSWD\r" }
	}
	expect {
		timeout abort
		"\$id@" { send "touch \$tfile\r" }
	}
	expect {
		timeout abort
			"\$id@\$" { send "exit\r" }
		}
	expect eof
	EOF
	chmod +x $TCTMP/mtelnet

	local TFILE="/tmp/my$$testfile"
	$TCTMP/mtelnet $TFILE $TC_PORT >$stdout 2>$stderr

	[ -e $TFILE ]
	tc_pass_or_fail $? "telnet is not working as expected."

}

# telnet -l <username>, so that no username is prompted for telnet
function TC_telnet2()
{	
	tc_register "telnet -a -l"
	local -i IPver=$1
	local TC_HOSTNAME=$2
	start_telnet_daemon -$IPver|| return

	# Create expect scritp
	local expcmd=`which expect`
	cat > $TCTMP/mtelnet2 <<-EOF
	#!$expcmd -f
	set timeout 3
	set id $TC_TEMP_USER
	set tfile [lindex \$argv 0]
	set tport [lindex \$argv 1]
	proc abort {} { exit 1 }
	spawn /usr/bin/telnet -a -l $TC_TEMP_USER $TC_HOSTNAME \$tport
	expect {
		timeout abort
		"assword:" { send "$TC_TEMP_PASSWD\r" }
	}
	expect {
		timeout abort
		"\$id@" { send "touch \$tfile\r" }
	}
	expect {
		timeout abort
			"\$id@" { send "exit\r" }
		}
	expect eof
	EOF
	chmod +x $TCTMP/mtelnet2

	local TFILE="/tmp/my$$testfile2"
	$TCTMP/mtelnet2 $TFILE $TC_PORT >$stdout 2>$stderr

	[ -e $TFILE ]
	tc_pass_or_fail $? "telnet is not working as expected."
	
}

# start telnetd with -h option
function TC_telnet3()
{	
	tc_register "in.telnetd -h"
	local -i IPver=$1
	local TC_HOSTNAME=$2
	start_telnet_daemon -h -$IPver|| return

	# Create an expect script
	local expcmd=`which expect`
	cat > $TCTMP/mtelnet3 <<-EOF
	#!$expcmd -f
	set timeout 3
	set id $TC_TEMP_USER
	set tfile [lindex \$argv 0]
	set tport [lindex \$argv 1]
	
	proc abort {} { exit 1 }
	spawn /usr/bin/telnet $TC_HOSTNAME \$tport
	expect {
		timeout abort
		"login:" { send "\$id\r" }
	}
	expect {
		timeout abort
		"assword:" { send "$TC_TEMP_PASSWD\r" }
	}
	expect {
		timeout abort
		"\$id@" { send "touch \$tfile\r" }
	}

	expect {
		timeout abort
			"\$id@" { send "exit\r" }
		}
	expect eof
	EOF

	chmod +x $TCTMP/mtelnet3 

	local TFILE="/tmp/my$$testfile3"
	$TCTMP/mtelnet3 $TFILE $TC_PORT >$stdout 2>$stderr

	[ -e $TFILE ]
	tc_fail_if_bad $? "file not created after telnet." || return

	grep -q '[Ww]elcome' $stdout 
	[ $? -ne 0 ]
	tc_pass_or_fail $? "Shouldn't see welcome host information"  
}

################################################################################
# main
################################################################################
TST_TOTAL=3
tc_setup

# Check if supporting utilities are available
tc_exec_or_break  $REQUIRED || exit

tc_info "IPv4 localhost tests"
TC_telnet1 4 "localhost" &&
TC_telnet2 4 "localhost" &&
TC_telnet3 4 "localhost"

MY_HOSTNAME=$(hostname)
[ "$MY_HOSTNAME" ] && {
	((TST_TOTAL+=3))
	tc_info "IPv4 $MY_HOSTNAME tests"
	TC_telnet1 4 $MY_HOSTNAME &&
	TC_telnet2 4 $MY_HOSTNAME &&
	TC_telnet3 4 $MY_HOSTNAME 
}


# IPv6 if enabled
[ "$IPv6" = "yes" ] && {
	[ "$TC_IPV6_host_ADDRS" ] && {
		((TST_TOTAL+=3))
		tc_info "IPv6 local addr tests ($TC_IPV6_host_ADDRS)"
		TC_telnet1 6 "$TC_IPV6_host_ADDRS" &&
		TC_telnet2 6 "$TC_IPV6_host_ADDRS" && 
		TC_telnet3 6 "$TC_IPV6_host_ADDRS"
	}
	[ "$TC_IPV6_link_ADDRS" ] && {
		((TST_TOTAL+=3))
		tc_info "IPv6 link addr tests ($TC_IPV6_link_ADDRS)"
		TC_telnet1 6 "$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES" &&
		TC_telnet2 6 "$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES" && 
		TC_telnet3 6 "$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES"
	}
	[ "$TC_IPV6_global_ADDRS" ] && {
		((TST_TOTAL+=3))
		tc_info "IPv6 global addr tests ($TC_IPV6_global_ADDRS)"
		TC_telnet1 6 "$TC_IPV6_global_ADDRS" &&
		TC_telnet2 6 "$TC_IPV6_global_ADDRS" && 
		TC_telnet3 6 "$TC_IPV6_global_ADDRS"  
	}
}
