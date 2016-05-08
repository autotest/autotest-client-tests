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
## File :	dnsmasq.sh
##
## Description:	Tests for dnsmasq package.
##
## Author:	Gowri Shankar <gowrishankar.m@in.ibm.com>
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN="${PWD%%/testcases/*}/testcases/bin"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
installed="dnsmasq"
required="dhclient ifconfig ip dig grep tftp"
dnsmasq_restart=""
dnsmasq_pid=""
test_url="kjdev1.au.example.com"
firewalld_restart=1
network_file=/etc/sysconfig/network

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# check installation and environment
	tc_root_or_break || return
	tc_exec_or_break $installed || return
	tc_exec_or_break $required || return
	test_url=$(grep kjdev1.au.example.com /etc/hosts | awk '{print $1}')
	
	#Bring down firewalld
	tc_service_status firewalld
	if [ $? -eq 0 ]; then
		tc_service_stop_and_wait firewalld
		firewalld_restart=0
	fi
	#Adding default net dev
	tc_get_iface
	echo "GATEWAYDEV=$TC_IFACE" >> $network_file
		
	# setup virtual ethernet pairs for the tests
	# dnsmi is an interface under test for dhcp client tests
	# dnsmp is peer interface where dnsmasq listens
	ip link add name dnsmi type veth peer name dnsmp &>/dev/null
	tc_conf_if_bad $? "unable to create virtual peer interfaces" || return

	ifconfig dnsmi up &>/dev/null
	tc_conf_if_bad $? "unable to bring up test interface" || return
	ifconfig dnsmp 10.2.2.1 netmask 255.255.255.0 broadcast \
		255.255.255.0 up &>/dev/null
	tc_conf_if_bad $? "unable to assign ip on peer interface" || return

	# create lease and pid files
	touch $TCTMP/dnsmasq.leases $TCTMP/dnsmasq.pid

	# save current test environment
	[ -f "/etc/ethers" ]  && cp /etc/ethers $TCTMP/
	dnsmasq_pid=$(service dnsmasq status | egrep -ro "pid\s*\w*" | awk '{print $2}')
	[ -d "/proc/$dnsmasq_pid" ] && dnsmasq_restart=$(ps -o "%a" --no-headers $dnsmasq_pid)
	service dnsmasq stop &>/dev/null
	dnsmasq_pid=""
	tc_get_os_arch
	if [ $TC_OS_ARCH = "s390x" ]; then
		test_url=$(grep lnx.boe.example.com /etc/hosts | awk '{print $1}')
	fi

}

function tc_local_cleanup()
{
	# delete test interfaces
	ip link show dnsmi &>/dev/null && ip link del dnsmi
	ip link show dnsmp &>/dev/null && ip link del dnsmp

	# restart dnsmasq if required.
	[ -z "$dnsmasq_pid" ] || kill $dnsmasq_pid
	[ -z "$dnsmasq_restart" ] || $dnsmasq_restart

	# restore test environment
	[ -f "$TCTMP/ethers" ] && cp $TCTMP/ethers /etc
	
	# Start firewalld if required
	[ -z "$firewalld_restart" ] && tc_service_start_and_wait firewalld
}

#
# test 1
#  check if dnsmasq caches locally
#  dnsmasq is started with out DHCP/TFTP support. Query time for a
#  DNS entry is measured which should be less than 10s in an ideal case.
#
function test_dns_cache()
{
	tc_register "dnsmasq"
	tc_info "checking if dnsmasq is functional"
	local query_time=""

	# Kill any dnsmasq process is running at the port 53
	test_pid=`lsof -i :53 | cut -f2 -d " " | grep [0-9] | uniq`
	if [ $test_pid ]; then
		kill -9 $test_pid
	fi	

	# start dnsmasq to cache DNS only.
	dnsmasq --no-dhcp-interface=dnsmp --pid-file=$TCTMP/dnsmasq.pid 1>$stdout 2>$stderr
	tc_fail_if_bad $? "dnsmasq failed to start as DNS cache" || return
	dnsmasq_pid=$(cat $TCTMP/dnsmasq.pid)

	# "dig" once to update cache entry
	dig @10.2.2.1 $test_url 1>$stdout 2>$stderr
	grep -q "ANSWER: [1-9]" $stdout
	tc_fail_if_bad $? "dnsmasq failed to lookup a DNS entry" || return
	query_time=$(awk '/Query time/ {print $4}' $stdout)
	tc_info "with out cache entry, KBIC server query took $query_time ms"

	# now local DNS cache is updated. Check query time for less than 10ms
	# in an ideal scenario.
	dig @10.2.2.1 $test_url 1>$stdout 2>$stderr
	query_time=$(awk '/Query time/ {print $4}' $stdout)
	tc_info "with cache entry, KBIC server query took $query_time ms"
	[ $query_time -le 10 ]
	tc_pass_or_fail $? "DNS cache is improperly working! ..."

	# cleanup anything setup by this test.
	kill $dnsmasq_pid && dnsmasq_pid=""
}

#
# test 2
#  test dnsmasq for DHCP support (minimal verifications).
#  dnsmasq (as DHCP server) listens on dnsmp interface (10.2.2.1)
#  dhclient is run on test interface dnsmi to get DHCP ip.
#
function test_dhcp()
{
	tc_register "dnsmasq(DHCP)"
	tc_info "testing dnsmasq as DHCP server"
	local mac=""
	local ip=""

	# start dnsmasq as DHCP server
	dnsmasq --interface dnsmp --bind-interfaces --pid-file=$TCTMP/dnsmasq.pid \
		--dhcp-leasefile=$TCTMP/dnsmasq.leases --dhcp-range 10.2.2.2,10.2.2.254,2h \
		--log-facility=$TCTMP/dnsmasq.log 1>$stdout 2>$stderr
	tc_fail_if_bad $? "dnsmasq failed to start as DHCP server" || return
	dnsmasq_pid=$(cat $TCTMP/dnsmasq.pid)

	# get DHCP address on test interface
	dhclient dnsmi 1>$stdout 2>$stderr
	tc_fail_if_bad $? "dhclient is unable to receive DHCP ip" || \
		{
			dhclient -r
			kill $dnsmasq_pid
			dnsmasq_pid=""
			return 1
		}
	mac=$(ip link show dnsmi | awk '/link/ {print $2}')
	ip=$(awk "/$mac/"'{print $3}' $TCTMP/dnsmasq.leases)
	tc_info "received dynamic ip $ip"
	egrep -rq "dnsmasq-dhcp.*: DHCPACK\(dnsmp\) $ip $mac" $TCTMP/dnsmasq.log
	tc_pass_or_fail $? "dhcp ip is not assigned successfully"

	# cleanup anything setup by this test.
	dhclient -r
	truncate -s 0 $TCTMP/dnsmasq.log
	truncate -s 0 $TCTMP/dnsmasq.leases
	kill $dnsmasq_pid && dnsmasq_pid=""
}

#
# test 3
#  test dnsmasq for DHCP support (using /etc/ethers).
#  dnsmasq (as DHCP server) listens on dnsmp interface (10.2.2.1)
#  dhclient is run on test interface dnsmi to get DHCP ip.
#  check for static ip allocation.
#
function test_dhcp_by_ethers()
{
	tc_register "dnsmasq(DHCP using /etc/ethers)"
	tc_info "testing dnsmasq as DHCP server"
	local mac=""
	local ip=""
	local dns=""
	local dhcp_opt_6=""

	# add entry for dnsmi in /etc/ethers
	mac=$(ip link show dnsmi | awk '/link/ {print $2}')
	echo "$mac 10.2.2.10" > /etc/ethers

	# add additional DNS entry to verify DHCP option 6
	dhcp_opt_6="10.2.2.1"
	dns=$(dig +time=1 +tries=1 | egrep -o "\(.*\)" | egrep -o "\w.\w.\w.\w")
	if [ -z "$dns" ]; then
		if [ $TC_OS_ARCH = "s390x" ]; then
			dns=$(grep dns.boe.example.com /etc/hosts | awk '{print $1}')
		else
			dns=$(grep dns.au.example.com /etc/hosts | awk '{print $1}')
		fi
			tc_info "no DNS server is configured! using ${dns} for testing."
			cp /etc/resolv.conf /etc/resolv.conf.org
			echo "${dns}" >>/etc/resolv.conf
	fi
	dhcp_opt_6="${dhcp_opt_6},${dns}"

	# start dnsmasq as DHCP server
	dnsmasq --interface dnsmp --bind-interfaces --pid-file=$TCTMP/dnsmasq.pid \
		--dhcp-leasefile=$TCTMP/dnsmasq.leases --dhcp-range 10.2.2.2,10.2.2.254,2h \
		--dhcp-option=6,$dhcp_opt_6 \
		--read-ethers --log-facility=$TCTMP/dnsmasq.log 1>$stdout 2>$stderr
	tc_fail_if_bad $? "dnsmasq failed to start as DHCP server" || return
	dnsmasq_pid=$(cat $TCTMP/dnsmasq.pid)

	# get DHCP address on test interface
	dhclient dnsmi 1>$stdout 2>$stderr
	tc_fail_if_bad $? "dhclient is unable to receive DHCP ip" || \
		{
			dhclient -r
			kill $dnsmasq_pid
			dnsmasq_pid=""
			return 1
		}
	ip=$(awk "/$mac/"'{print $3}' $TCTMP/dnsmasq.leases)
	tc_info "received dynamic ip $ip"
	[ "$ip" = "10.2.2.10" ]
	tc_pass_or_fail $? "expected dhcp ip is 10.2.2.10"

	# check if additional DNS lookup works
	tc_register "check DHCP option 6 (for DNS)"
	sleep 5
	dig @10.2.2.1 $test_url 1>$stdout 2>$stderr
	grep -q "ANSWER: [1-9]" $stdout
	tc_pass_or_fail $? "dnsmasq failed dhcp-option 6 (DNS)"

	# cleanup anything setup by this test.
	dhclient -r
	truncate -s 0 $TCTMP/dnsmasq.log
	truncate -s 0 $TCTMP/dnsmasq.leases
	kill $dnsmasq_pid && dnsmasq_pid=""
	if [ -f /etc/resolv.conf.org ]; then
		mv /etc/resolv.conf.org /etc/resolv.conf
	fi
}

#
# test 4
#  test dnsmasq for DHCP support (using dhcp-host option).
#  dnsmasq (as DHCP server) listens on dnsmp interface (10.2.2.1)
#  dhclient is run on test interface dnsmi to get DHCP ip.
#  check for static ip allocation.
#
function test_dhcp_by_config()
{
	tc_register "dnsmasq(DHCP using --dhcp-host)"
	tc_info "testing dnsmasq as DHCP server"
	local mac=""
	local ip=""

	# start dnsmasq as DHCP server using --dhcp-host
	mac=$(ip link show dnsmi | awk '/link/ {print $2}')
	dnsmasq --interface dnsmp --bind-interfaces --pid-file=$TCTMP/dnsmasq.pid \
		--dhcp-leasefile=$TCTMP/dnsmasq.leases --dhcp-range 10.2.2.2,10.2.2.254,2h \
		--dhcp-host=$mac,10.2.2.20 \
		--log-facility=$TCTMP/dnsmasq.log 1>$stdout 2>$stderr
	tc_fail_if_bad $? "dnsmasq failed to start as DHCP server" || return
	dnsmasq_pid=$(cat $TCTMP/dnsmasq.pid)

	# get DHCP address on test interface
	dhclient dnsmi 1>$stdout 2>$stderr
	tc_fail_if_bad $? "dhclient is unable to receive DHCP ip" || \
		{
			dhclient -r
			kill $dnsmasq_pid
			dnsmasq_pid=""
			return 1
		}
	ip=$(awk "/$mac/"'{print $3}' $TCTMP/dnsmasq.leases)
	tc_info "received dynamic ip $ip"
	[ "$ip" = "10.2.2.20" ]
	tc_pass_or_fail $? "expected dhcp ip is 10.2.2.20"

	# cleanup anything setup by this test.
	dhclient -r
	truncate -s 0 $TCTMP/dnsmasq.log
	truncate -s 0 $TCTMP/dnsmasq.leases
	kill $dnsmasq_pid && dnsmasq_pid=""
}

#
# test 5
#  test dnsmasq for TFTP support.
#  dnsmasq (as TFTP server) is tested for file transfer using tftp client.
#
function test_tftp()
{
	tc_register "dnsmasq(TFTP)"
	tc_info "testing dnsmasq as TFTP server"
	local md5_snd=""
	local md5_rcv=""

	# start dnsmasq as TFTP server
	echo "interface=dnsmp"   > $TCTMP/dnsmasq.conf
	echo "enable-tftp"      >> $TCTMP/dnsmasq.conf
	echo "tftp-root=$TCTMP" >> $TCTMP/dnsmasq.conf

	dnsmasq --pid-file=$TCTMP/dnsmasq.pid --enable-tftp --tftp-root=$TCTMP \
		--log-facility=$TCTMP/dnsmasq.log 1>$stdout 2>$stderr
	tc_fail_if_bad $? "dnsmasq failed to start as TFTP server" || return
	dnsmasq_pid=$(cat $TCTMP/dnsmasq.pid)

	# transfer a file (eg: echo binary) and check if it is really transfered
	mkdir $TCTMP/tftptest
	cp `which echo` $TCTMP/
	pushd $TCTMP/tftptest &>/dev/null
	tftp 10.2.2.1 &>/dev/null <<EOF
	binary
	get echo
	quit
EOF
	md5_snd=$(md5sum ../echo | awk '{print $1}')
	md5_rcv=$(md5sum  ./echo | awk '{print $1}')
	popd &>/dev/null
	[ "$md5_snd" = "$md5_rcv" ]
	tc_pass_or_fail $? "tftp file transfer failed"

	# cleanup anything setup by this test.
	kill $dnsmasq_pid && dnsmasq_pid=""
}

################################################################################
# main
################################################################################
TST_TOTAL=6
tc_setup

test_dns_cache
test_dhcp
test_dhcp_by_ethers
test_dhcp_by_config
test_tftp
