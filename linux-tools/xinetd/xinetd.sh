#!/bin/bash
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
## File :	xinetd.sh
##
## Description:	Test xinetd program
##
## Author:	Robert Paulsen
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/xinetd
source $LTPBIN/tc_utils.source

fiv_client=${LTPBIN%/shared}/xinetd/fiv_client
restart_xinetd="no"
fiv_server_out=""	# filled in by tc_local_setup
port=""			# filled in by tc_local_setup

################################################################################
# local utility functions
################################################################################

function tc_local_setup()
{
	tc_root_or_break || exit
       
	tc_find_port && port=$TC_PORT
	tc_break_if_bad $? "Could not find available port" || return

	# determine ip version
	ip_version=ipv4
	server_name=$(hostname)
	[ "$server_name" ] || server_name=localhost

	tc_ipv6_info && {
		ip_version=ipv6
		[ "$TC_IPV6_host_ADDRS" ] && server_name=$TC_IPV6_host_ADDRS
		[ "$TC_IPV6_link_ADDRS" ] && server_name=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
		[ "$TC_IPV6_global_ADDRS" ] && server_name=$TC_IPV6_global_ADDRS
		server_name=$(tc_ipv6_normalize $server_name)
	}

	# create a dummy service
	fiv_server_out=$TCTMP/fiv_server_out
	cat > $TCTMP/fiv_service.sh <<-EOF
		#!$SHELL
		echo "Hello" > $fiv_server_out
		return 0
	EOF
	chmod +x $TCTMP/fiv_service.sh

	# temporarily add the dummy service to /etc/services
	[ -e /etc/services ] && cp /etc/services $TCTMP/
	cat >> /etc/services <<-EOF
		fiv_service             $port/tcp
	EOF

	# temporarily add the dummy service to /etc/xinetd.conf
	[ -e /etc/xinetd.conf ] && cp /etc/xinetd.conf $TCTMP/

	cat >> /etc/xinetd.conf <<-EOF
		service fiv_service
		{
			socket_type             = stream
			wait                    = no
			user                    = root
			server                  = $TCTMP/fiv_service.sh
			server_args             = -l -a
			log_on_success          += DURATION
			nice                    = 10
			flags			= $ip_version
		}
	EOF

}

function tc_local_cleanup()
{
	# restore originals
	[ -e $TCTMP/services ] && cp $TCTMP/services /etc/services
	[ -e $TCTMP/xinetd.conf ] && cp $TCTMP/xinetd.conf /etc/xinetd.conf

	tc_service_stop_and_wait xinetd
	[ $restart_xinetd = "yes" ] && tc_service_start_and_wait xinetd
}

################################################################################
# the testcase functions
################################################################################

function test01()
{
	tc_register "installation check"

	# Check that xinetd exists
      tc_check_package xinetd
	tc_pass_or_fail $? "xinetd not installed properly"
}

function test02()
{
	tc_register "start xinetd ($ip_version)"

	# if xinetd was already running we will restart after our test
	tc_service_status xinetd && restart_xinetd="yes"

	# verify that xinetd starts OK
	tc_service_restart_and_wait xinetd
	tc_fail_if_bad_rc $? "xinetd did not start" || return
	
	#As locale is not built for cross, restarting xinetd serive reports
	#locale related warning. so during the pass_or_fail check the 
	#non empty stderr making the test fail. So emptying the stderr
	#for ppcnf arch and also only if it contains only locale
	#related warning.
	if [ $TC_OS_ARCH = "ppcnf" ] 
	then
		if [ `grep -cvi locale $stderr` = 0 ]; then
			cat /dev/null > $stderr 
		fi
	fi
	# See that xinetd is listening to our port
	tc_wait_for_active_port $port 10 $ip_version
	tc_pass_or_fail $? "xinetd not listening on port $port"
}

function test03()
{
	tc_register "invoke service via $ip_version"

	# client invokes xinetd server which in turn invokes dummy service
	$fiv_client $server_name $port >$stdout 2>$stderr
	tc_fail_if_bad $? "xinetd failed to respond to client" || return

	tc_wait_for_file_text $fiv_server_out Hello
	tc_pass_or_fail $? "expected to see \"Hello\" in file \"$fiv_server_out\""

	# ipv6 should also accept ipv4
	[ "$ip_version" = "ipv6" ] && {
		((++TST_TOTAL))
		tc_register "invoke service via ipv4"
		$fiv_client localhost $port >$stdout 2>$stderr
		tc_fail_if_bad $? "xinetd failed to respond to client" || return
		tc_wait_for_file_text $fiv_server_out Hello
		tc_pass_or_fail $? "expected to see \"Hello\" in file \"$fiv_server_out\""
	}		
}

function test04()
{
	tc_register "restart xinetd (ipv4)"

	# verify that xinetd starts OK
	tc_service_stop_and_wait xinetd
	tc_wait_for_inactive_port $port
	tc_fail_if_bad $? "could not stop xinetd" || return

	rm /etc/xinetd.conf
	[ -e $TCTMP/xinetd.conf ] && cp $TCTMP/xinetd.conf /etc/xinetd.conf
	cat >> /etc/xinetd.conf <<-EOF
		service fiv_service
		{
			socket_type             = stream
			wait                    = no
			user                    = root
			server                  = $TCTMP/fiv_service.sh
			server_args             = -l -a
			log_on_success          += DURATION
			nice                    = 10
			flags			= ipv4
		}
	EOF

	tc_service_start_and_wait xinetd
	tc_fail_if_bad_rc $? "xinetd did not restart" || return

	#As locale is not built for cross, restarting xinetd serive reports 
	#locale related warning. so during the pass_or_fail check the     
	#non empty stderr making the test fail. So emptying the stderr
	#for ppcnf arch and also only if it contains only locale
	#related warning
	if [ $TC_OS_ARCH = "ppcnf" ]
	then
		if [ `grep -cvi locale $stderr` = 0 ]
		then
			cat /dev/null > $stderr
		fi
	fi
	# See that xinetd is listening to our port
	# Note: Must not specify "ipv4" with tc_wait_for_active_port since
	#	ipv6 systems listen for both ipv4 and ipv6 but specifying
	#	ipv4 means "ipv4 only". "Pure" ipv4 can only be tested on
	#	systems w/o ipv6-enablement. This will be covered above.
	tc_wait_for_active_port $port
	tc_pass_or_fail $? "xinetd not listening on port $port"
}

function test05()
{
	server_name=$(hostname)
	[ "$server_name" ] || server_name=127.0.0.1
	if [ $server_name == "localhost" ]; then 
		server_name="127.0.0.1" 
	fi 

	tc_register "invoke service via $server_name ipv4"

	# client invokes xinetd server which in turn invokes dummy service
	$fiv_client $server_name $port >$stdout 2>$stderr
	tc_fail_if_bad $? "xinetd failed to respond to client" || return

	tc_wait_for_file_text $fiv_server_out Hello
	tc_pass_or_fail $? "expected to see \"Hello\" in file \"$fiv_server_out\""
}

################################################################################
# main
################################################################################

TST_TOTAL=3
tc_get_os_arch
tc_setup			# standard setup

test01 &&
test02 &&
test03

[ "$ip_version" = "ipv4" ] && exit

((TST_TOTAL+=2))
test04 &&
test05
