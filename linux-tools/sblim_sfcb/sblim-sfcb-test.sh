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
#
# File :    sblim-sfcb-test.sh
#
# Description:  Test CVS
#
# Author:   CSTL: Wang Tao <wangttao@cn.ibm.com>
#
# ToDo: Don't use killall -9 to stop servers. This is temporary until a
#       bug gets fixed to allow server to die gracefully.
#       UPDATE: Done. Bug 32741 now fixed.
#
################################################################################

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/sblim_sfcb
source $LTPBIN/tc_utils.source
SDIR=${LTPBIN%/shared}/sblim_sfcb

service_active=no
rep_dir=/var/lib/sfcb

SFCB_CONF=/etc/sfcb/sfcb.cfg

WBEM_PORT=5988

#
# stop_sfcbd    Wrapper for "tc_service_stop_and_wait sblim-sfcb"
#
function stop_sfcbd()
{
    # This now works after bug 32741.
    tc_service_stop_and_wait sblim-sfcb
    tc_wait_for_inactive_port $WBEM_PORT

    # This is a hack to account for sfcb hang after wbemcat timeout.
    # See bug 42523.
    killall -9 sfcbd &>/dev/null
    tc_wait_for_inactive_port $WBEM_PORT
}

#
# tc_local_setup
#
function tc_local_setup()
{
    tc_root_or_break || exit
    tc_exec_or_break cmp grep ifconfig || exit

    local mem=`cat /proc/meminfo |grep MemTotal | awk '{print $2}'`
    local memMB=$(( mem/1024 ))

    if [ $memMB -lt 127 ]
    then
        tc_conf "Insufficient memory $memMB MB, if you are running this on ppcnf, use sequoia board."
        exit
    fi
# For ppcnf there is no need to check for cmpi_path as this is part of libvirt-cim pkg which is not built for ppcnf.
    tc_get_os_arch                                                                                             
    if [ $TC_OS_ARCH = "ppcnf" ]                                                                               
    then                                                                                                        
    	lib_path=/usr/lib                                                                                   
    else              
    	cmpi_path=`find /usr/lib /usr/lib64 -maxdepth 1 -type d -name cmpi 2>/dev/null`
    	if [ x$cmpi_path = x ];
    	then
		tc_break "Unable to find cmpi directory. Is sblim-sfcb installed properly ?"
		exit
    	fi
    	lib_path=`dirname $cmpi_path`
    fi

    sfcb_path=`find /usr/lib /usr/lib64 -maxdepth 1 -type d -name sfcb 2>/dev/null`
    if [ x$sfcb_path = x ];
    then
	tc_break "Unable to find sfcb directory. Is sblim-sfcb installed properly ?"
	exit
    fi

    # save the current state of sfcbd.
    tc_service_status sblim-sfcb 
       [ $? -eq 0  ] && service_active=yes
    
    # stop all sfcb daemons
    stop_sfcbd
    tc_fail_if_bad $? "Could bot stop sfcbd" || return

    # save files which are touched by the testcase.
    [ -d $rep_dir ] && cp -a $rep_dir $TCTMP/saved_rep
    # Use the stage files provided by base
    #rm -rf $rep_dir/stage &>/dev/null
    #cp -a $SDIR/tests/stage $rep_dir/ 
    #tc_break_if_bad $? "can not copy stage files for test."

    # ipv4 or ipv6
    server=localhost;
    version=""      # version is left empty for IPv4

    tc_ipv6_info
    [ "$TC_IPV6_ADDRS" ] || [ "$IPVER" != "ipv6" ]
    tc_break_if_bad $? "Unable to support requested IPv6 test mode" || exit

    # Use IPv4 if forced or if no IPv6 support
    [ "$TC_IPV6_ADDRS" = "" ] || [ "$IPVER" != "ipv6" ] && {
        # prefer external address over loopback
        local external_host=$(hostname -f)
       [ "$external_host" ] && server=$external_host
    }

    # Use IPv6 if available and not forced to IPv4
    [ "TC_IPV6_ADDRS" ] && [ "$IPVER" != "ipv4" ] && {
        # prefer link over global over host scope
        [ "$TC_IPV6_host_ADDRS" ] && server=$TC_IPV6_host_ADDRS
        [ "$TC_IPV6_global_ADDRS" ] && server=$TC_IPV6_global_ADDRS
        [ "$TC_IPV6_link_ADDRS" ] && server=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
        server=$(tc_ipv6_normalize $server)
        version=ipv6
    }

    # Setup the config file for our use
    cp $SFCB_CONF $TCTMP/sfcb.cfg
    cat > $SFCB_CONF <<-EOF
httpPort:       5988
enableHttp:     true
enableUds:      true
httpProcs:      8
httpsPort:      5989
enableHttps:    false
httpsProcs:     8
maxMsgLen:      10000000
providerDirs: $lib_path $cmpi_path $sfcb_path
provProcs:      32
doBasicAuth:    false
doUdsAuth:      true
basicAuthLib:   sfcBasicPAMAuthentication
useChunking:    true
keepaliveTimeout: 1
keepaliveMaxRequest: 10
sslKeyFilePath: /etc/sfcb/file.pem
sslCertificateFilePath: /etc/sfcb/server.pem
sslClientTrustStore: /etc/sfcb/client.pem
sslClientCertificate: ignore
certificateAuthLib:   sfcCertificateAuthentication
registrationDir: /var/lib/sfcb/registration
enableInterOp:  true
EOF

    tc_info "Using server address $server"
    return 0
}

#
# tc_local_cleanup  
#
function tc_local_cleanup()
{
    # some interesting info in case of failure.
    [ "$?" -ne 0 ] && {
        tc_info "================== ps -ef ======================="
        ps -ef
        tc_info "================== netstat -lpen ================"
        netstat -lpen
        tc_info "================================================="
    }

    # stop our instance
    stop_sfcbd
    tc_wait_for_inactive_port $WBEM_PORT

    # restore saved files.
    [ -d $TCTMP/saved_rep ] && {
        rm -rf $rep_dir &>/dev/null
        cp -a $TCTMP/saved_rep $rep_dir 
    }

    [ -f $TCTMP/sfcb.cfg ] && cp $TCTMP/sfcb.cfg $SFCB_CONF
    # restore the sfcb service.
    [ "$service_active" = "yes" ] && tc_service_start_and_wait sblim-sfcb
}

################################################################################
# the testcase functions
################################################################################

#
# run one service test
#
function run_service_test() {

    local _TESTXML=$1
    local _TEST=${_TESTXML%.xml}
    local _TESTOK=$_TEST.OK
    local _TESTRESULT=$_TEST.result

    ((++TST_TOTAL))
    tc_register "CIM-XML test: ${_TEST##*/}"

    # Remove any old test result file
    rm -f $_TESTRESULT $_TESTRESULT.sorted

    # Send the test CIM-XML to the CIMOM
    $SDIR/wbemcat6 $server $_TESTXML >$_TESTRESULT 2>$stderr
    tc_fail_if_bad $? "Failed to send CIM-XML request." || return

    # Check for ERRORs first.
    # ERRORs have <ERROR\ CODE ... /> tag
    grep "<ERROR" $_TESTRESULT >$stderr
    # The '0' in the next line is purposeful. We have to only verify the stderr
    tc_fail_if_bad 0 "Found ERRORs in the response" || return 42

    # Compare actual vs. expected response XML
    # We check if we are missing some expected messages.
    # If we have additional messages(non-error) we are OK with that.

    local compare="diff -wbEup"
    type diff &>/dev/null || compare="cmp"
    [ -f $_TESTRESULT ] && sort -u $_TESTRESULT > $_TESTRESULT.sorted
    [ -f "$_TESTOK" ] && sort -u $_TESTOK > $_TESTOK.sorted
    $compare $_TESTOK.sorted $_TESTRESULT.sorted >/$TCTMP/miscompare
    grep  "^\-[^-]" $TCTMP/miscompare > $stderr
    # Same as above for ERROR code checking
    tc_pass_or_fail 0 "Missing vital information in response. Missing info in stderr" \
	"See expected in $_TESTOK" \
	"Actual result in $_TESTRESULT" || 
        return 42
}

#
# installation check
#
function test_installation()
{
    tc_register "installation check"

    # core sfcb files must be installed
    tc_exists $rep_dir /usr/sbin/sfcbd /usr/bin/sfcbrepos && rpm -q sblim-sfcb &>/dev/null
    tc_pass_or_fail $? "some core files are not installed. Check that sblim-sfcb rpm is installed"
}

#
# create a repository 
#
function test_createrep()
{
    tc_register "create repository"
    
    # create the repository
    full_schema_mof_path=`rpm -ql cim-schema | grep -e cim_schema.*mof$`
    schema_dir=`dirname ${full_schema_mof_path}`
    tc_info "Using schema ${schema_dir}"
    sfcbrepos -f -c ${schema_dir} >$stdout 2>$stderr
    tc_pass_or_fail $? "failed to create the repository."
}

#
# start sfcb service
#
function test_sfcbd()
{
    tc_register "service startup"

    tc_service_start_and_wait sblim-sfcb
    tc_fail_if_bad $? "failed to start sfcbd."  || return

    tc_wait_for_active_port $WBEM_PORT
    tc_pass_or_fail $? "Port $WBEM_PORT not bound"
}

#
# run wbemcat6 tests against the service 
#
function test_service()
{
    # run the wbemcat scripts
    local testfile
    tc_info "Following XML query tests looks for basic definitions expected"
    tc_info "The actual result may have additional information based on the schema used"

    for testfile in $SDIR/tests/queries/*.xml; do
        run_service_test $testfile # || return
    done
}

################################################################################
# main
################################################################################

tc_setup

TST_TOTAL=3
tc_run_me_only_once

test_installation &&
test_createrep && sleep 1 &&
test_sfcbd && sleep 3 &&
test_service 
