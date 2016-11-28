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
## File :		tftp_sh.sh
##
## Description:	Test the functionality of tftp and tftpd.
##
## Author:		CSDL
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/tftp
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/tftp
cd $TESTDIR
REQUIRED="tftp in.tftpd expect"

################################################################################
#  test functions
################################################################################
_OrigINetd=""
_OrigXINetd=""
_FTPSRV=""
localtest=1
ipv6test=0

usage()
{
	local tab=$'\t'
	cat <<-EOF

		usage:
		$tab$0 [-r host] [-h]	

		$tab$0	-r : Set the remote tftp server. If not set, will use localhost.
		$tab$0	-h : Print this help text.	
			
		If you use remote tftp server, you should have correctly prepared test data and started the tftp server as deceibed in 00_Descriptions.txt .

	EOF
	exit 1
}

parse_args()
{
	while getopts r:h opt ; do
		case "$opt" in
			r)	_FTPSRV=$OPTARG
				localtest=0
				;;
			h)	
				usage
				;;
			*)	usage	# exits
				;;
		esac
	done
}


save__OrigINetd()
{
	if [ -e /etc/init.d/inetd ]; then
		/etc/init.d/inetd status | grep running > /dev/null
		if [ $? -eq 0 ] ; then
			_OrigINetd="/etc/init.d/inetd"
			/etc/init.d/inetd stop >/dev/null 2>&1
		fi
	fi
	
	if [ -e /etc/init.d/xinetd ]; then
		/etc/init.d/xinetd status | grep running > /dev/null
		if [ $? -eq 0 ] ; then
			_OrigXINetd="/etc/init.d/xinetd"
			/etc/init.d/xinetd stop >/dev/null 2>&1
		fi
	fi		
}

tc_local_setup()
{	
	# Check if supporting utilities are available
	tc_exec_or_break  $REQUIRED || return

	if [ $localtest -eq 1 ] ; then
	
		_FTPSRV="localhost"
		cp -r tftp-data $TCTMP/
		save__OrigINetd
		
		pid=`ps aux | grep in.tftpd | grep -v grep | awk '{print $2}'`
		if [ "$pid" != "" ] ; then
			echo kill -9 $pid
			kill -9 $pid
		fi
		
		in.tftpd -c -l -p -s $TCTMP/tftp-data -u root 
		sleep 1
		killit=0
		killit=`ps aux | grep in.tftpd | grep -v grep | awk '{print $2}'`
		
		if [ "x$killit" == "x" ] ; then
			tc_info "tftpd server start error!"
			exit 1
		fi
		
		TST_TOTAL=4
	else
		TST_TOTAL=2 
	fi
	
	# Test the ipv6 support for tftp

	expect tftp_test.exp $_FTPSRV quit dummy dummy -6  &> /dev/null
	if [ $? == 0 ]; then
		ipv6test=1
		tc_info "IPv6 Support detected"
		TST_TOTAL=$((TST_TOTAL*2))
	fi

	touch $TCTMP/error.txt
}


tc_local_cleanup()
{
	if [ $localtest -eq 1 ] ; then
		
		if [ "x$killit" != "x" ] ; then
			kill $killit &>/dev/null
		fi
		
		tc_info "Restore inetd/xinetd"	
		
		if [ ! "$_OrigINetd" = "" ] ; then
			$_OrigINetd start >/dev/null 2>&1
		fi
	
		if [ ! "$_OrigXINetd" = "" ] ; then
			$_OrigXINetd start >/dev/null 2>&1
		fi
	fi
}

test_get_text()
{
	tc_register	"tftp$PROTO ascii get"
	expect tftp_test.exp $_FTPSRV get test.txt ascii "$PROTO"  &> /dev/null
	tc_pass_or_fail $?  "`cat $TCTMP/error.txt`"
}

test_get_binary()
{
	tc_register	"tftp$PROTO binary get"
	expect tftp_test.exp $_FTPSRV get test.bin binary "$PROTO" &> /dev/null 
	tc_pass_or_fail $?  "`cat $TCTMP/error.txt`"	
}

test_put_text()
{
	cp -f $TCTMP/tftp-data/test.txt $TCTMP/test1.txt
	tc_register	"tftp$PROTO ascii put"
	expect tftp_test.exp $_FTPSRV  put test1.txt ascii "$PROTO" &>/dev/null
	tc_pass_or_fail $?  "`cat $TCTMP/error.txt`"	
}

test_put_binary()
{
	cp -f $TCTMP/tftp-data/test.bin $TCTMP/test1.bin
	tc_register	"tftp$PROTO binary put"
	expect tftp_test.exp $_FTPSRV put test1.bin binary "$PROTO" &> /dev/null 
	tc_pass_or_fail $?  "`cat $TCTMP/error.txt`"	
}



run_tests()
{
	test_get_text
	test_get_binary	

	if [ $localtest -eq 1 ] ; then
		test_put_text
		test_put_binary
	fi
}
	
################################################################################
#  main
################################################################################

parse_args $*

export TCTMP
tc_setup

tc_root_or_break || exit
tc_exec_or_break  awk expect ps grep || exit


# Run the IPv6 tests if the support is enabled
if [ $ipv6test != 0 ]; then
	PROTO="-6"
	run_tests
	PROTO="-4"
fi

# Run the IPv4 Tests
run_tests
