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
## File :	iptraf.sh
##
## Description:	test of iptraf package
##
## Author:	James He <hejianj@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/iptraf_ng
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/iptraf_ng
IPADDR=$(ifconfig lo | head -n2 | tail -n1 | awk '{print $2}' | cut -f2 -d:)

# global variables
LOGFILE=$TCTMP/iptraf-ng$$.log
################################################################################
# utility functions
################################################################################


################################################################################
# testcase functions
################################################################################

#
# test01 : installation check
#
function test01()
{
	tc_register "installation check"
	tc_executes iptraf-ng 
	tc_pass_or_fail $? "iptraf-ng not properly installed"
}

#
# test02 : test iptraf-ng -i 
#
function test02()
{
	tc_register	"iptraf-ng -i"	

	tc_executes ping
	tc_conf_if_bad $? "ping command needed by the test" || return

	rm -f $LOGFILE &>/dev/null
	iptraf-ng -i lo -t 1 -B -L $LOGFILE >$stdout 2>$stderr
	tc_fail_if_bad $? "iptraf-ng -i failed"
	ping -w 10 -c 10 $IPADDR >/dev/null
	sleep 65
	cp $LOGFILE $stdout
	grep -q "$IPADDR" $stdout
	tc_pass_or_fail $? "Did not see $IPADDR in log file (now in stdout)"
}

#
# test03 : test iptraf-ng -z
#
function test03()
{
	tc_register	"iptraf-ng -z"

	tc_executes ping
	tc_conf_if_bad $? "ping command needed by the test" || return

	rm -f $LOGFILE &>/dev/null
	iptraf-ng -f -z lo -t 1 -B -L $LOGFILE >$stdout 2>$stderr
	tc_fail_if_bad $? "iptraf-ng -z failed"
	ping -w 10 -c 10 $IPADDR >/dev/null
	sleep 65
	cp $LOGFILE $stdout
	grep -q "Interface:.* lo.* MTU:.*[1-9][0-9]*" $stdout
	tc_pass_or_fail $? "Did not see \Interface: lo  MTU: nnnnn\" in log file (now in stdout)"
}

#
# test04 : test iptraf-ng -d
#
function test04()
{
	tc_register	"iptraf -d"

	tc_executes ping
	tc_conf_if_bad $? "ping command needed by the test" || return

	rm -f $LOGFILE &>/dev/null
	iptraf-ng -d lo -t 1 -B -L $LOGFILE >$stdout 2>$stderr
	tc_fail_if_bad $? "iptraf-ng -d failed"
	ping -w 10 -c 10 $IPADDR >/dev/null
	sleep 65
	cp $LOGFILE $stdout
	grep -q "interface lo" $stdout
	tc_pass_or_fail $? "Did not see \"Interface lo\" in log file (now in stdout)"
}

################################################################################
# MAIN
################################################################################

[ "$1" == "--help" ] && test_usage

TST_TOTAL=4

export TERM="xterm"

tc_setup

test01 || exit
test02
test03
test04
