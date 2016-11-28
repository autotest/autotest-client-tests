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
## File :	bind9-utils.sh
##
## Description:  base testcase used to make sure package bind9-utils correct
##
## Author:	CSDL
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/bind_utils
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

REQUIRED="expect ping"
INSTALLED="dig host nslookup nsupdate"

DOMAINNAMES=""      # set by tc_setup
SERVERADDR=""       # set by tc_setup
DOMAINHOSTS=""      # set by test01(dig)
DIGTYPES="A SOA"

EXPECT=`which expect`
HOST=`which host`
NSLOOPUP=`which nslookup`
NSUPDATE=`which nsupdate`

#
#	tc_local_setup		tc_setup specific to this set of testcases
#
function tc_local_setup()
{
	# check configuration and utilities
	tc_exec_or_break $REQUIRED || return
	tc_exist_or_break /etc/resolv.conf || return

	local SERVERADDRS
	# read domain names and dns server from configuration /etc/resolv.conf
	while read RESOLV
	do
		[ "$RESOLV" == "" ] && continue
		set $RESOLV
		[ "$1" == "search"     ] && { shift ; DOMAINNAMES="$DOMAINNAMES $@" ; }
		[ "$1" == "domain"     ] && { shift ; DOMAINNAMES="$DOMAINNAMES $@" ; }
		[ "$1" == "nameserver" ] && { shift ; SERVERADDRS="$SERVERADDRS $1" ; }
	done </etc/resolv.conf

	[ "$DOMAINNAMES" != ""  ]
	tc_break_if_bad $? "no domain name found in /etc/resolv.conf" || return
	[ "$SERVERADDRS" != ""  ]
	tc_break_if_bad $? "no name servers found in /etc/resolv.conf" || return

	local found="no"
	for SERVERADDR in $SERVERADDRS
	do
		nslookup $SERVERADDR > /dev/null && { found="yes" ; break ; }
	done
	[ "$found" = "yes" ]
	tc_break_if_bad $? "could not access a name server"
}

################################################################################
# the testcase functions
################################################################################

#
#	Installation Check
#
function test01()
{
	tc_register "installation check"
	tc_executes $INSTALLED
	tc_pass_or_fail $? "bind9-utils not properly installed"
}


#
#	test02	test dig function
#
function test02()
{
	DOMAINHOSTS=""
	for DOMAINNAME in $DOMAINNAMES
	do
	for DIGTYPE in $DIGTYPES
	do
		let TST_TOTAL+=1
		tc_register "dig $DOMAINNAME $DIGTYPE"
		dig @$SERVERADDR $DOMAINNAME $DIGTYPE >$stdout 2>$stderr
		tc_pass_or_fail $? "dig domain $DOMAINNAME failed" || continue

		local -i hostnum=0
		local -i records=0
		while read -a DIGINFO
		do
			[ "${DIGINFO[2]}" == "IN" ] && [ "${DIGINFO[3]}" == "A"     ] && \
			{
				let hostnum+=1 ; let records+=1 ;
				[ $hostnum -lt 3 ] && DOMAINHOSTS="${DOMAINHOSTS} ${DIGINFO[0]}"
			}
			[ "${DIGINFO[2]}" == "IN" ] && [ "${DIGINFO[3]}" == "CNAME" ] && \
				let records+=1
			[ "${DIGINFO[2]}" == "IN" ] && [ "${DIGINFO[3]}" == "MX"    ] && \
				let records+=1
			[ "${DIGINFO[2]}" == "IN" ] && [ "${DIGINFO[3]}" == "NS"    ] && \
				let records+=1
			[ "${DIGINFO[2]}" == "IN" ] && [ "${DIGINFO[3]}" == "SOA"   ] && \
				let records+=1
		done <$stdout
		[ $records == 0 ] && tc_warn "no RRs find in domain $DOMAINNAME with type $DIGTYPE"

	done
	done
}

#
#	test03	test host function
#
function test03()
{
	for HOSTNAME in $DOMAINHOSTS
	do
		let TST_TOTAL+=1
		tc_register "host $HOSTNAME"
		$HOST $HOSTNAME > $stdout 2>$stderr
		tc_fail_if_bad $? "host $HOSTNAME failed" || continue

		read -a HOSTINFO < $stdout
		[ "${HOSTINFO[2]}" != "has" ] || "${HOSTINFO[3]}" != "address" ]
		tc_pass_or_fail $? "host $HOSTNAME information error"
	done
}

#
#	test04	test nslookup function
#
function test04()
{
	tc_executes expect || return	# skip this test if no expect command
	for HOSTNAME in $DOMAINHOSTS
	do
		let TST_TOTAL+=1
		tc_register "nslookup $HOSTNAME"
		cat > $TCTMP/nslookup.exp <<-EOF
			#! $EXPECT
			set timeout 15
			spawn nslookup -sil
			expect {
				-re ".*>" {}
				timeout { send "exit \r"; exit 255 }
			}
			
			send "server $SERVERADDR \r"
			expect {
				-re ".*Default server:.*Address:.*>" {}
				timeout { send "exit \r"; exit 1 }
			}
			
			send "$HOSTNAME \r"
			expect {
				-re ".*Name:.*Address:.*>" {}
				timeout { send "exit \r"; exit 2 }
			}
			
			send "exit \r"
			exit 0
		EOF

		$EXPECT -f $TCTMP/nslookup.exp >$stdout 2>$stderr
		tc_pass_or_fail $? "nslookup $HOSTNAME failed"
	done
}


################################################################################
# main
################################################################################

tc_setup
TST_TOTAL=1

test01 || exit
test02
test03
test04

tc_info "nsupdate test need operation rights and configurations, skiped"
