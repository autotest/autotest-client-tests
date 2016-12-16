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
## File :        openslp.sh
##
## Description:  Test openslp tool
##
## Author:      	CSDL  James He <hejianj@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/openslp
source $LTPBIN/tc_utils.source
srcdir="/var/run"
#testdir="openslptest" # testdir we store individual test files in
testdir=${LTPBIN%/shared}/openslp/openslptest
scenariodir=${LTPBIN%/shared}/openslp/scenarios

# unique service names based on IP address
IP=$(hostname --all-ip-addresses)
eval ID=`echo $IP | cut -d " " -f 1`

################################################################################
# environment functions
################################################################################
#
# local setup
#
function tc_local_setup()
{
	tc_exec_or_break slpd grep awk sed || return

	ipaddr=$(hostname -i | cut -d" " -f1)
	[ "$ipaddr" ]
	tc_break_if_bad $? "Could not find ip address of this machine" || return

        NETSTAT=""
        tc_executes netstat && NETSTAT="netstat -tapn"
        tc_is_busybox netstat && NETSTAT="netstat -tan"

        #Enable the tcp/udp ports on which slp service is running
        local Enable=`firewall-cmd --zone=public --add-port=427/tcp`
        Enable=`firewall-cmd --zone=public --add-port=427/udp`

	DIFF=diff
	tc_executes diff || {
		DIFF="true"
		tc_info "Without diff we will depend only on commands' return codes"
	}
	
	mv /etc/slp.conf $TCTMP/slp.conf.bak
	cat <<-EOF >/etc/slp.conf
	net.slp.interfaces = $ipaddr
	EOF
}

#
# local cleanup
#
function tc_local_cleanup()
{
	tc_service_stop_and_wait slpd

        #Disable the tcp/udp ports on which slp service is running after executing the testcase
        local Disable=`firewall-cmd --zone=public --remove-port=427/tcp`
        disable=`firewall-cmd --zone=public --remove-port=427/udp`

	mv $TCTMP/slp.conf.bak /etc/slp.conf
}

function kill_slpd()
{
	[ -f ${srcdir}/slpd.pid ] || {
		killall slpd &>/dev/null & sleep 1
		return 0
	}
	local pid=$(< ${srcdir}/slpd.pid)
	rm ${srcdir}/slpd.pid
	kill $pid
	tc_wait_for_no_pid $pid &>/dev/null
	tc_break_if_bad $? "could not kill slpd at pid $pid" || return

	tc_wait_for_inactive_port 427
	tc_break_if_bad $? "slpd would not give up port 427"
}

################################################################################
# testcase functions
################################################################################

function install_check()
{
	tc_register "Installation Check"
	tc_executes slpd
	tc_pass_or_fail $? "not installed properly" || return

	tc_service_stop_and_wait slpd	
	return 0
}

function slpdereg()
{
	tc_register "SLPDereg"
	[ -f ${testdir}/SLPDereg ]
	tc_break_if_bad "$?" "The test '$testdir/SLPDereg' does not exist." || continue

	tc_service_restart_and_wait slpd || return

	cat <<-EOF >$TCTMP/expected.output
	Registering     = service:registered$ID://${ipaddr}
	Srv. Registered = service:registered$ID://${ipaddr}
	Querying        = service:registered$ID
	Service Found   = service:registered$ID://${ipaddr}
	Deregistering   = service:registered$ID://${ipaddr}
	Deregistered    = service:registered$ID://${ipaddr}
	Registering     = service:registered$ID://${ipaddr}
	Srv. Registered = service:registered$ID://${ipaddr}
	Querying        = service:unregistered$ID
	Deregistering   = service:unregistered$ID://${ipaddr}
	Deregistered    = service:unregistered$ID://${ipaddr}
	Querying        = service:test$ID
	Deregistering   = service:test$ID://${ipaddr}
	Deregistered    = service:test$ID://${ipaddr}
	EOF

	${testdir}/SLPDereg service:registered$ID ${ipaddr} service:registered$ID ${ipaddr} > $stdout 2>$stderr &&
	${testdir}/SLPDereg service:registered$ID ${ipaddr} service:unregistered$ID ${ipaddr} >> $stdout 2>>$stderr &&
	${testdir}/SLPDereg service:test$ID ${ipaddr} >> $stdout 2>>$stderr
	tc_fail_if_bad $? "unexpected response from SLPDereg" || {
		RC=$?
		$NETSTAT
		return $RC
	}

	kill_slpd || return
	$DIFF -bE $TCTMP/expected.output $stdout
	tc_pass_or_fail $? "failed" \
		"=============== Expected to see ================" \
		"$( echo ; cat $TCTMP/expected.output)" \
		"================================================"
}

function slpreg()
{
	tc_register "SLPReg"
	[ -f ${testdir}/SLPReg ]
	tc_break_if_bad "$?" "The test '$testdir/SLPReg' does not exist." || return
	
	tc_service_restart_and_wait slpd || return

	cat <<-EOF >$TCTMP/expected.output
	Registering     = service:valid$ID://${ipaddr}
	Querying        = service:valid$ID
	Service Found   = service:valid$ID://${ipaddr}
	Registering     = service:valid$ID://${ipaddr}
	Querying        = service:invalid$ID
	EOF

	${testdir}/SLPReg service:valid$ID ${ipaddr} service:valid$ID >  $stdout 2> $stderr &&
	${testdir}/SLPReg service:valid$ID ${ipaddr} service:invalid$ID >> $stdout 2>> $stdout
	tc_fail_if_bad $? "unexpected response from SLPReg" || return

	kill_slpd || return
	$DIFF -bE $TCTMP/expected.output $stdout
	tc_pass_or_fail $? "failed" \
		"=============== Expected to see ================" \
		"$( echo ; cat $TCTMP/expected.output)" \
		"================================================"
}

function slpfindattr()
{
	tc_register "SLPFindAttrs"
	[ -f ${testdir}/SLPFindAttrs ]
	tc_break_if_bad "$?" "The test '$testdir/SLPFindAttrs' does not exist." || return

	rm -f $TCTMP/slp.test.reg
	cat <<-EOF >$TCTMP/slp.test.reg
	service:test$ID://${ipaddr},en,65535 
	foo=value1,value2
	description=Test Service 1
	goo=value3,value4
	EOF

	tc_service_stop_and_wait slpd || return
	slpd -r $TCTMP/slp.test.reg || return

	cat <<-EOF >$TCTMP/expected.output
	Querying                      = service:test$ID
	Service URL                   = service:test$ID://${ipaddr}
	Querying Attributes           = foo
	Service Attributes            = (foo=value1,value2)
	Querying                      = service:test$ID
	Service URL                   = service:test$ID://${ipaddr}
	Querying Attributes           = goo
	Service Attributes            = (goo=value3,value4)
	Querying                      = service:test$ID
	Service URL                   = service:test$ID://${ipaddr}
	Querying Attributes           = description
	Service Attributes            = (description=Test Service 1)
	Registering                   = service:test$ID://${ipaddr}
	Querying                      = service:test$ID
	Service URL                   = service:test$ID://${ipaddr}
	Querying Attributes           = foo
	Service Attributes            = (foo=value1,value2)
	Registering                   = service:test$ID://${ipaddr}
	Querying                      = service:test$ID
	Service URL                   = service:test$ID://${ipaddr}
	Querying Attributes           = goo
	EOF

	${testdir}/SLPFindAttrs service:test$ID ${ipaddr} foo > $stdout 2>$stderr &&
	${testdir}/SLPFindAttrs service:test$ID ${ipaddr} goo >> $stdout 2>>$stderr &&
	${testdir}/SLPFindAttrs service:test$ID ${ipaddr} description >> $stdout 2>>$stderr &&
	${testdir}/SLPFindAttrs service:test$ID ${ipaddr} "(foo=value1,value2)" foo >> $stdout 2>>$stderr &&
	${testdir}/SLPFindAttrs service:test$ID ${ipaddr} "(foo=value1,value2)" goo >> $stdout 2>>$stderr
	tc_fail_if_bad $? "unexpected response from SLPFindAttrs" || return

	kill_slpd || return
	$DIFF -bE $TCTMP/expected.output $stdout
	tc_pass_or_fail $? "failed" \
		"=============== Expected to see ================" \
		"$( echo ; cat $TCTMP/expected.output)" \
		"================================================"
}

function slpopen()
{
	tc_register "SLPOpen"
	[ -f ${testdir}/SLPOpen ]
	tc_break_if_bad "$?" "The test '$testdir/SLPOpen' does not exist." || return
	
	tc_service_restart_and_wait slpd || return

	${testdir}/SLPOpen > $stdout 2>$stderr
	tc_fail_if_bad $? "Unexped response from SLPOpen" || return

	kill_slpd || return
	tc_pass_or_fail 0	# PASS if we get this far: no expected output to compare
}

function slpfindsrvs()
{
	tc_register "SLPFindSrvs"
	[ -f ${testdir}/SLPFindSrvs ]
	tc_break_if_bad "$?" "The test '$testdir/SLPFindSrvs' does not exist." || return

	rm -f $TCTMP/slp.test.reg
	cat <<-EOF >$TCTMP/slp.test.reg
	service:test$ID://${ipaddr},en,65535 
	description=Testing Serivce 2
	EOF

	tc_service_stop_and_wait slpd || return
	slpd -r $TCTMP/slp.test.reg || return

	${testdir}/SLPFindSrvs service:test$ID >  $stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from SLPFindAttrs" || return

	kill_slpd || return
	grep -q "Service URL *= service:test$ID://${ipaddr}" $stdout
	tc_pass_or_fail $? "failed" \
		"=============== Expected to see ================" \
		"$( echo ; cat $TCTMP/expected.output)" \
		"================================================"
}

function slpescape()
{
	tc_register "SLPEscape"
	[ -f ${testdir}/SLPEscape ]
	tc_break_if_bad "$?" "The test '$testdir/SLPEscape' does not exist." || return

	rm -f $TCTMP/slp.test.reg
	cat <<-EOF >$TCTMP/slp.test.reg
	service:test$ID://$ipaddr,en,65535 
	foo=value1,value2
	description=Test Service 1
	goo=value3,value4
	EOF

	cat <<-EOF >$TCTMP/expected.output
	Input Tag = asdf(asdf
	Escaped Tag = asdf\28asdf
	Input Tag = (asdf
	Escaped Tag = \28asdf
	Input Tag = asdf\\
	Escaped Tag = asdf\5C
	Input Tag = (),\!<=>~
	Escaped Tag = \28\29\2C\5C\21\3C\3D\3E\7E
	EOF

	${testdir}/SLPEscape asdf\(asdf > $stdout 2>$stderr &&
	${testdir}/SLPEscape \(asdf >> $stdout 2>>$stderr &&
	${testdir}/SLPEscape asdf\\ >> $stdout 2>>$stderr &&
	${testdir}/SLPEscape \(\),\\!\<=\>\~ >> $stdout 2>>$stderr
	tc_fail_if_bad $? "unexpected response from SLPEscape" || return
					
	$DIFF -bE $TCTMP/expected.output $stdout
	tc_pass_or_fail $? "failed" \
		"=============== Expected to see ================" \
		"$( echo ; cat $TCTMP/expected.output)" \
		"================================================"
}


function slpunescape()
{
	tc_register "SLPUnescape"
	[ -f ${testdir}/SLPUnescape ]
	tc_break_if_bad "$?" "The test '$testdir/SLPUnescape' does not exist." || return

	cat <<-EOF >$TCTMP/expected.output
	Input Tag = asdfasdf
	Output Tag = asdfasdf
	Input Tag = \28abc
	Output Tag = (abc
	Input Tag = abc\7E
	Output Tag = abc~
	Input Tag = \28\29\2C\5C\21\3C\3D\3E\7E
	Output Tag = (),\!<=>~
	EOF

	${testdir}/SLPUnescape asdfasdf >  $stdout 2>$stderr &&
	${testdir}/SLPUnescape \\28abc >>  $stdout 2>>$stderr &&
	${testdir}/SLPUnescape abc\\7E >>  $stdout 2>>$stderr &&
	${testdir}/SLPUnescape \\28\\29\\2C\\5C\\21\\3C\\3D\\3E\\7E >> $stdout 2>>$stderr
	tc_fail_if_bad $? "unexpected response from SLPUnescape" || return

	$DIFF -bE $TCTMP/expected.output $stdout
	tc_pass_or_fail $? "failed" \
		"=============== Expected to see ================" \
		"$( echo ; cat $TCTMP/expected.output)" \
		"================================================"
}

function slpparsesrvurl()
{
	tc_register "SLPParseSrvURL"
	[ -f ${testdir}/SLPParseSrvURL ]
	tc_break_if_bad "$?" "The test '$testdir/SLPParseSrvURL' does not exist." || return

	rm -f $TCTMP/slp.test.reg
	cat <<-EOF >$TCTMP/slp.test.reg
	service:test$ID://$ipaddr,en,65535 
	foo=value1,value2
	description=Test Service 1
	goo=value3,value4
	EOF


	tc_service_restart_and_wait slpd || return

	cat <<-EOF >$TCTMP/expected.output
	Service Type = service:test$ID
	Host Identification = $ipaddr
	Port Number = 0
	Family = IP
	URL Remainder = 
	Service Type = service:test1$ID:test2$ID
	Host Identification = $ipaddr
	Port Number = 80
	Family = IP
	URL Remainder = 
	Service Type = service:test$ID
	Host Identification = $ipaddr
	Port Number = 80
	Family = IP
	URL Remainder = foo/goo
	Service Type = service:test$ID
	Host Identification = $ipaddr
	Port Number = 0
	Family = IP
	URL Remainder = foo/goo
	EOF
	
	${testdir}/SLPParseSrvURL service:test$ID://$ipaddr >  $stdout 2>$stderr &&
	${testdir}/SLPParseSrvURL service:test1$ID:test2$ID://$ipaddr:80 >>  $stdout 2>>$stderr &&
	${testdir}/SLPParseSrvURL service:test$ID://$ipaddr:80/foo/goo >>  $stdout 2>>$stderr &&
	${testdir}/SLPParseSrvURL service:test$ID://$ipaddr/foo/goo >>  $stdout 2>>$stderr
	tc_fail_if_bad $? "unexpected response from SLPUnescape" || return

	kill_slpd || return
	$DIFF -bE $TCTMP/expected.output $stdout
	tc_pass_or_fail $? "failed" \
		"=============== Expected to see ================" \
		"$( echo ; cat $TCTMP/expected.output)" \
		"================================================"
}

function slpfindsrvtypes()
{
	tc_register "SLPFindSrvTypes"
	[ -f ${testdir}/SLPFindSrvTypes ]
	tc_break_if_bad "$?" "The test '$testdir/SLPFindSrvTypes' does not exist." || return

	rm -f $TCTMP/slp.test.reg
	cat <<-EOF >$TCTMP/slp.test.reg
	##This is a testing service
	service:test1$ID://${ipaddr},en,65535
	description=Testing Service 1
	
	##This is the other testing service
	service:test2$ID://${ipaddr},en,65535
	description=Testing Service 2
	
	##This is the testing service using another naming authority
	service:test$ID.OPENSLP://${ipaddr},en,65535
	description=Testing Service with OPENSLP naming authority
	EOF

	tc_service_stop_and_wait slpd || return
	slpd -r $TCTMP/slp.test.reg || return

	${testdir}/SLPFindSrvTypes "*" > $stdout 2>$stderr &&
	${testdir}/SLPFindSrvTypes "" >> $stdout 2>>$stderr &&
	${testdir}/SLPFindSrvTypes "JUNK" >> $stdout 2>>$stderr &&
	${testdir}/SLPFindSrvTypes "OPENSLP" >> $stdout 2>>$stderr
	tc_fail_if_bad $? "unexpected response from SLPFindSrvTypes" || return

	kill_slpd || return
	cat $stdout | grep -q "service:test1$ID" &&
	cat $stdout | grep -q "service:test2$ID" &&
	cat $stdout | grep -q "service:test$ID.OPENSLP" 
	tc_pass_or_fail $? "SLPFindSrvTypes failed"
}

################################################################################
# MAIN
################################################################################
TST_TOTAL=10
tc_setup

install_check || exit
slpdereg
slpreg
slpfindattr
slpopen
slpfindsrvs
slpescape
slpunescape
slpparsesrvurl
slpfindsrvtypes
