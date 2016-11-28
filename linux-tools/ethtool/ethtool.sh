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
# File :	ethtool.sh
#
# Description:	Test ethtool package
#
# Author:	Andrew Pham, apham@austin.ibm.com

################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/ethtool
source $LTPBIN/tc_utils.source

TESTDIR=${LTPBIN%/shared}/ethtool
cd $TESTDIR
REQUIRED="ifconfig grep"
INTERFACE="none"
isppcnf=no
################################################################################
# utility functions
################################################################################

function get_intr()
{
	local cnt=0
	while [ $cnt -lt 3 ]
	do
		if ifconfig eth$cnt >&/dev/null ; then
			INTERFACE=eth$cnt
			break
		fi
	done
	
	[ "$INTERFACE" != "none" -a -n "$INTERFACE" ]
	tc_break_if_bad $? "Unable to get an interface"
}
function querySettings()
{
	local tmpfile=$TCTMP/tmpout
	sleep 5
	ethtool $INTERFACE >$tmpfile
	[ $? -ne 0 ] && return 1
	while read attribute value junk; do
		case $attribute in		
			"Speed:")
				if [ "$1Mb/s" != "$value" ]
				then
					echo "Expetct $1Mb/s" >>$stdout
					echo "Got $value" >>$stdout
					return 1
				fi
				;;
			"Duplex:")
				[ "$value" == "Half" ] && value='half'
				[ "$value" == "Full" ] && value='full'
				if [ "$2" != "$value" ]
				then
					echo "Expetct $2" >>$stdout
					echo "Got $value" >>$stdout
					return 1
				fi
				;;
			"Auto-negotiation:")
				if [ "$3" != "$value" ]
				then
					echo "Expetct $3" >>$stdout
					echo "Got $value" >>$stdout
					return 1
				fi
				;;
			*)
				;;
		esac
	done < $tmpfile
}
function get_attributes()
{
	ethtool $INTERFACE >$stdout 2>$stderr
	tc_break_if_bad $? || return
	while read attribute value junk; do
		[ "$attribute" = "Speed:" ] && SPEED=${value/Mb\/s/} && continue
		[ "$attribute" = "Duplex:" ] && DUPLEX=$value && continue
		[ "$attribute" = "Auto-negotiation:" ] && AUTONEG=$value && continue
	done < $stdout
	[ "$SPEED" -a "$DUPLEX" -a "AUTONEG" ]
	tc_break_if_bad $? "Can't get current attributes for $INTERFACE"
	DUPLEX=${DUPLEX/F/f} # Full -> full
	DUPLEX=${DUPLEX/H/h} # Half -> half
	tc_info "original $INTERFACE attributes: SPEED=$SPEED DUPLEX=$DUPLEX AUTONEG=$AUTONEG"
}

function tc_local_setup()
{
	grep -q ppcnf /proc/version && isppcnf=yes
	get_intr || retutrn
	get_attributes || return
	tc_exec_or_break $REQUIRED || return
}

function tc_local_cleanup()
{
	[ "$SPEED" -a "$DUPLEX" -a "AUTONEG" ] &&
	tc_info "restoring: ethtool -s $INTERFACE speed $SPEED duplex $DUPLEX autoneg $AUTONEG"
	ethtool -s $INTERFACE speed $SPEED duplex $DUPLEX autoneg $AUTONEG >&/dev/null
	querySettings $SPEED $DUPLEX $AUTONEG
}	
################################################################################
# testcase functions
################################################################################

function test01()
{
	tc_register "installation check"
	tc_executes ethtool
	tc_pass_or_fail $? "ethtool not installed"
}

function test02()
{
        tc_register "ethtool"
	

	ethtool $INTERFACE >$stdout 2>$stderr
	tc_fail_if_bad $? "Not available." || return

	grep -q "Supported" $stdout &&
	grep -q "Speed" $stdout &&
	grep -q "Duplex" $stdout &&
	grep -q "Auto-negotiation" $stdout 
	tc_pass_or_fail $? "Unexpected output."
}

function test03()
{
	tc_register "ethtool -i"
	ethtool -i $INTERFACE >$stdout 2>$stderr
	tc_fail_if_bad $? "Not available." || return

	grep -q "driver" $stdout &&
	grep -q "firmware" $stdout
	tc_pass_or_fail $? "Unexpected output." || return
}

function test04()
{
	tc_register "ethtool -d"
	ethtool -d $INTERFACE >$stdout 2>$stderr
	tc_pass_or_fail $? "Not available." || return
}

function test05()
{
	[ "$isppcnf" = "yes" ] && { ((--TST_TOTAL)); return ; }
	tc_register "ethtool -e $INTERFACE"
	ethtool -e $INTERFACE >$stdout 2>$stderr
	tc_fail_if_bad $? "Not available." || return

	[ -s $stdout ]
	tc_pass_or_fail $? "Unexpected output." || return
}

function test06()
{
	[ "$isppcnf" = "yes" ] && { ((--TST_TOTAL)); return ; }
	tc_register "ethtool -t online $INTERFACE"
	ethtool -t $INTERFACE online >$stdout 2>$stderr
	tc_fail_if_bad $? "Not available." || return

	grep -q "PASS" $stdout
	tc_pass_or_fail $? "Unexpected output." || return
}

function test07()
{
	local s_speed
	local s_duplex=half
	local s_auto=off
	ethtool $INTERFACE >$stdout
	if grep 10baseT/Half $stdout >/dev/null
	then
		s_speed=10
	else
		if grep 100baseT/Half $stdout >/dev/null
		then
			s_speed=100
		else
			if grep 1000baseT/Half $stdout >/dev/null
			then
			#	mode="speed 1000 duplex half autoneg off"
				s_speed=1000
			else
				tc_info "This card not support \"10/100/1000 half \
					duplex auto off mode\",this test skiped"
				return 0
			fi
		fi
	fi
	mode="speed $s_speed duplex $s_duplex autoneg $s_auto"

	tc_register "ethtool -s $INTERFACE $mode "
	tc_info "Possible one minute delay ..."
	ethtool -s $INTERFACE $mode >$stdout 2>$stderr
	tc_fail_if_bad $? "Not available." || return

	querySettings $s_speed $s_duplex $s_auto
	tc_pass_or_fail $? "Unexpected output." || return
}

function test08()
{
	tc_register "ethtool -a $INTERFACE "
	ethtool -a $INTERFACE &>$stdout 
	if [ $? -ne 0 ]
	then
		cat $stdout | grep 'Operation not supported' >/dev/null
		tc_pass_or_fail $? "Unexpected output."
		return
	fi
	tc_fail_if_bad $? "Not available." || return

	grep -q "Autonegotiate" $stdout &&
	grep -q "RX" $stdout && grep -q "TX" $stdout 
	tc_pass_or_fail $? "Unexpected output." || return
}
################################################################################
# main
################################################################################
TST_TOTAL=4
tc_setup
tc_get_os_arch
test01 &&
test02 &&
test03 &&
if [ "$TC_OS_ARCH" = "x86_64" ] || [ "$TC_OS_ARCH" = "i686" ] || [ "$TC_OS_ARCH" = "ppcnf" ]; then
	TST_TOTAL=`expr $TST_TOTAL+4`
	test04 &&
	test05 &&
	test06 &&
	test07 
fi
test08
