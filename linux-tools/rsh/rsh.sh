#!/bin/bash
############################################################################################
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
# File :	rsh.sh	
#
# Description:	test remote shell "rsh" 
#
# Author:	Helen Pang, hpang@us.ibm.com
#
################################################################################
# source the standard utility functions
###############################################################################

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

REQUIRED="grep sed expect"
IPV6=""
ip4addr="" 

RSH_SERVER=""
RSH_USER=""
RSH_PASSWD=""

tmprlogin="/tmp/rlogin.out"


# ignore SIGTTIN, so that background /usr/bin/rcp won't read from stdin
trap "" SIGTTIN SIGTTOU

#
# Identify IPv4 address
#
function tc_ipv4_info()
{
        #ip4addrs=(`grep IPADDR /etc/sysconfig/network/ifcfg-eth* | grep -v REMOTE | cut -d "=" -f2 | sed '{s/"//g}' | sed "{s/'//g}"`)
        #ip4addrs=(`ifconfig | grep inet | grep -v inet6| grep -v 127.0.0.1 | cut -d: -f2 | awk '{ print $1}'`)
        ip4addr=`hostname -i`
	
	[ "$ip4addr" ]
}


#
# setup unique to this testcase
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exec_or_break $REQUIRED || return

	tc_service_restart_and_wait rsh.socket &> /dev/null
	tc_service_restart_and_wait rlogin.socket &> /dev/null
	tc_service_restart_and_wait rexec.socket &> /dev/null

	RSH_SERVER=$(hostname)

	tc_add_user_or_break || exit
	[ $TC_TEMP_USER ] && RSH_USER=$TC_TEMP_USER
	[ $TC_TEMP_PASSWD ] && RSH_PASSWD=$TC_TEMP_PASSWD

	tc_ipv4_info
	tc_break_if_bad $? "Failed to determine IPv4 address" || return

#	See 46549 and 46813
#	tc_ipv6_info && IPV6=yes
	
	# enable passwd-less rsh
	[ -e /root/.rhosts ] && cp /root/.rhosts $TCTMP
	[ -e /etc/hosts ] && cp /etc/hosts $TCTMP
	echo $(hostname)  >> /root/.rhosts
	echo "$ip4addr 	$(hostname)" >> /etc/hosts
	[ $TC_IPV6_global_ADDRS ] && echo "$TC_IPV6_global_ADDRS 	$(hostname)" >> /etc/hosts 
	[ $TC_IPV6_link_ADDRS ] && echo "$TC_IPV6_link_ADDRS 	$(hostname)" >> /etc/hosts 
	[ $TC_IPV6_host_ADDRS ] && echo "$TC_IPV6_host_ADDRS 	$(hostname)" >> /etc/hosts 

	type nscd &>/dev/null && nscd -i hosts

	cat > $TCTMP/test.sh <<-EOF
		#!/bin/bash
		cp /etc/passwd /tmp
		diff -u /etc/passwd /tmp/passwd && echo "OK"
		rm -f /tmp/passwd
	EOF
	chmod a+x $TCTMP/test.sh
	cp /etc/securetty /etc/securetty.bck
}

function tc_local_cleanup()
{
	mv /etc/securetty.bck /etc/securetty
	return 0
}

################################################################################
# the testcase functions
################################################################################

#
# test00	installation check
#
function test00()
{
	tc_register "rsh installation check"
	tc_executes rsh rexec rcp rlogin
	tc_pass_or_fail $? "rsh client package not installed properly"
}

function test_rcp()
{
	tc_register "test rcp"
	
	echo rsh >> /etc/securetty	
	rcp $TCTMP/test.sh ${RSH_SERVER}:/tmp/test.sh >$stdout 2>$stderr
	tc_fail_if_bad $? "rcp failed" || return
	rcp ${RSH_SERVER}:/tmp/test.sh $TCTMP/test.sh.back >$stdout 2>$stderr

	diff -u $TCTMP/test.sh $TCTMP/test.sh.back
	tc_pass_or_fail $? "unexpected result"
}

function test_rsh()
{
	tc_register "test rsh"

	echo rsh >> /etc/securetty
	/usr/bin/rsh ${RSH_SERVER} /tmp/test.sh >$stdout 2>$stderr
	tc_fail_if_bad $? "rsh failed" || return

	grep -q "OK" $stdout
	tc_pass_or_fail $? "unexpected result"
}

function test_rexec()
{
	tc_register "test rexec"
	
	rexec -l ${RSH_USER} -p ${RSH_PASSWD} ${RSH_SERVER} /tmp/test.sh >$stdout 2>$stderr
	tc_fail_if_bad $? "rexec failed" || return

	grep -q "OK" $stdout
	tc_pass_or_fail $? "unexpected result"
}

function test_rlogin()
{
	tc_register     "rlogin"
	export TERM=vt100
	local command="rlogin -l $RSH_USER $RSH_SERVER"
	local expcmd=`which expect`
	cat > $TCTMP/expect_rlogin.scr <<-EOF
		#!$expcmd -f
		set timeout 10
		log_file -a $tmprlogin 
		proc abort { message } {
		        send_user "\n $message \n"
		        exit 1
		}
		spawn $command
		expect {
		        "assword: "             { sleep 1; send "$RSH_PASSWD\r" }
		        default                 { abort "rlogin failed. Did not ask for password." }
		}
		expect {
		        "$RSH_USER"             { send "exit 0\r" }
		        default                 { abort "rlogin failed." }
		}
		expect eof
	EOF
	chmod +x $TCTMP/expect_rlogin.scr
	$TCTMP/expect_rlogin.scr >$stdout 2>$stderr
	tc_pass_or_fail $? "rlogin failed"
}


################################################################################
# main
################################################################################

TST_TOTAL=5

tc_setup

test00
test_rcp
test_rsh
test_rexec
test_rlogin

if [ "$IPV6" = "yes" ]	# this is disabled in tc_local_setup
then
        TST_TOTAL+=4

	tc_info "Testing with IPv6 Now." 

	[ "$TC_IPV6_host_ADDRS" ] && RSH_SERVER=$TC_IPV6_host_ADDRS
	[ "$TC_IPV6_global_ADDRS" ] && RSH_SERVER=$TC_IPV6_global_ADDRS
	[ "$TC_IPV6_link_ADDRS" ] && RSH_SERVER=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
	RSH_SERVER=$(tc_ipv6_normalize $RSH_SERVER)

	#Clean up old files 
	[ -e "$TCTMP/test.sh.back" ] && rm -f "$TCTMP/test.sh.back" 
	[ -e /tmp/test.sh ] && rm -f /tmp/test.sh 

	test_rcp
	test_rsh
	test_rexec
	test_rlogin
fi
 
