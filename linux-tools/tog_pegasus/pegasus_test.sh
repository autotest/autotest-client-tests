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
## File :        pegasus_test.sh
##
## Description:  Test pegasus tool
##
## Author:       CSDL  James He <hejianj@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/tog_pegasus
source $LTPBIN/tc_utils.source

TESTDIR=${LTPBIN%/shared}/tog_pegasus
testdir=/usr/share/Pegasus/test/bin
BINDIR=/usr/sbin

SERVERPEM=0
CLIENTPEM=0
FILEPEM=0

SYSCONF=/etc/sysconfig/tog-pegasus
CIM_PORT=5988
isFileAdded=0
################################################################################
# environment functions
################################################################################

#
# local setup
#
function tc_local_setup()
{
    tc_exec_or_break grep || return

    export PATH=$PATH:$testdir
    export PEGASUS_HOME=/etc/pegasus
    mkdir -p $PEGASUS_HOME

    [ -f $PEGASUS_HOME/server.pem ] || { cp $TESTDIR/server.pem $PEGASUS_HOME && SERVERPEM=1 ; }
    [ -f $PEGASUS_HOME/client.pem ] || { cp $TESTDIR/client.pem $PEGASUS_HOME && CLIENTPEM=1 ; }
    [ -f $PEGASUS_HOME/file.pem ] || { cp $TESTDIR/file.pem $PEGASUS_HOME && FILEPEM=1 ; }

    tc_exist_or_fail /var/lib/Pegasus/repository || return

    local mylib=lib provider p
    tc_get_os_arch
    if [ `getconf LONG_BIT` == "64" ]; 
    then
        mylib=lib64
    else
	mylib=lib
    fi
	cp $testdir/../${mylib}/* /usr/${mylib}/Pegasus/providers/
        cd /usr/${mylib}/Pegasus/providers;
        for provider in *.so.* ; do
            p=${provider%.so.*}
            ln -sf $provider $p.so
        done
        CIMCONFIG="cimconfig"
        CIMAUTH="cimauth"
        CIMPROVIDER="cimprovider"
        OSINFO="osinfo"
        INSTALLED="cimserver cimconfig cimauth cimprovider"

    if [ -f $SYSCONF ];
    then
        cp $SYSCONF $TCTMP/pegaus.sysconfig
    fi
    if [ ! -f /etc/redhat-release ]
    then
        isFileAdded=1
    	touch /etc/redhat-release
	    echo "OS Linux" > /etc/redhat-release
     fi

    echo CIMSERVER_OPTIONS=\"traceLevel=5 traceComponents=all enableSubscriptionsForNonprivilegedUsers=true\"  > $SYSCONF

}

function tc_local_cleanup()
{
    [ $SERVERPEM -eq 1 ] && rm $PEGASUS_HOME/server.pem
    [ $CLIENTPEM -eq 1 ] && rm $PEGASUS_HOME/client.pem
    [ $FILEPEM -eq 1 ] && rm $PEGASUS_HOME/file.pem

    stop_cimserver

    # restore original repository
    cd /var/lib/Pegasus
    [ -d repository.orig ] && { rm -rf repository ; mv repository{.orig,} ; }

    [ -f /etc/pam.d/wbem.orig ] && mv /etc/pam.d/wbem{.orig,}

    if [ -f $TCTMP/pegasus.syconfig ];
    then
        cp $TCTMP/pegasus.syconfig $SYSCONF
    else
        rm -f $SYSCONF
    fi
    if [ $isFileAdded -eq 1 ];
    then
        rm -f /etc/redhat-release
     fi

    [ $pegasus_start ] && tc_service_restart_and_wait tog-pegasus
}

function stop_cimserver()
{
    tc_service_stop_and_wait tog-pegasus 
    tc_wait_for_inactive_port $CIM_PORT
}

function start_cimserver()
{
    tc_service_start_and_wait tog-pegasus
    tc_wait_for_active_port $CIM_PORT
    tc_fail_if_bad $? "Could not start cimserver" || exit
}

function restart_cimserver()
{
    stop_cimserver
    start_cimserver
}

################################################################################
# testcase functions
################################################################################

function installation_check()
{
    tc_register "installation check"
    tc_executes $INSTALLED 
    tc_pass_or_fail $? "pegasus not installed properly" || return
}

function commonfunc()
{
    local SKIP_TESTS="
        TestSnmpHandler
        TestIndicationStressTest
    "

    # set up repository from testrepository
    tc_exist_or_fail /var/lib/Pegasus/testrepository || return
    (
        cd /var/lib/Pegasus
        rm -rf repository.orig
        mv repository{,.orig}
        mv testrepository repository
        chown -R --reference=repository.orig repository
    )
    restart_cimserver

    # run each testcase
    local t fqt
    for fqt in $testdir/Test* ; do
        t=${fqt##*/}
        tc_executes $fqt &>/dev/null || { tc_info "IGNORED cruft $t"; continue ; }
        [ "$SKIP_TESTS" = "${SKIP_TESTS/$t/}" ] || { tc_info "SKIPPED $t"; continue ; }

        tc_register "$t"
        if  [ "$t" = "TestClient" ] ; then
             $CIMAUTH -a -R -u $TC_TEMP_USER -n root/cimv2  >$stdout 2>$stderr
             tc_fail_if_bad $? "$CIMAUTH -a -R -u $TC_TEMP_USER -n root/cimv2 failed" || continue
             $fqt -user $TC_TEMP_USER -password $TC_TEMP_PASSWD --n root/cimv2 >$stdout 2>$stderr
             local RC=$?
             $CIMAUTH -r -R -u $TC_TEMP_USER -n root/cimv2 >$stdout 2>$stderr
             tc_fail_if_bad $? "$CIMAUTH -a -R -u $TC_TEMP_USER -n root/cimv2 failed" || continue
        else
             $fqt >$stdout 2>$stderr
             local RC=$?
        fi
        tc_pass_or_fail "$RC" "$t output unexpected."
    done

    # restore original repository (Also done in tc_local_cleanup in case of early exit.)
    cd /var/lib/Pegasus
    [ -d repository.orig ] && { mv repository testrepository ; rm -rf repository ; mv repository{.orig,} ; }
    restart_cimserver
}

# these test cases are part of pegasus $CIMCONFIG test
function cimconftest()
{
    tc_register "$CIMCONFIG test"
    tc_service_status tog-pegasus && pegasus_start=1 \
        && stop_cimserver

    $CIMCONFIG -s enableHttpConnection=true  -p 1>>$stdout 2>>$stderr

    start_cimserver
    tc_fail_if_bad $? "cim server did not start properly after $CIMCONFIG" || return

    #Set the current values:
    $CIMCONFIG -s traceLevel=1 -c  1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceLevel=2 -c  1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceLevel=3 -c  1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceLevel=4 -c  1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceComponents=ALL -c   1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceComponents=Config -c   1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceComponents=Config,XmlParser -c   1>>$stdout 2>>$stderr

    #Testing all get options:
    $CIMCONFIG -g traceLevel 1>>$stdout 2>>$stderr
    $CIMCONFIG -g traceComponents 1>>$stdout 2>>$stderr

    #Get the current values:
    $CIMCONFIG -g  traceLevel -c 1>>$stdout 2>>$stderr
    $CIMCONFIG -g  traceComponents -c 1>>$stdout 2>>$stderr

    #Get the planned values:
    $CIMCONFIG -g traceLevel -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -g traceComponents -p 1>>$stdout 2>>$stderr

    #Display properties:
    $CIMCONFIG -l -c 1>>$stdout 2>>$stderr

    #Set the planned values
    $CIMCONFIG -s traceLevel=1 -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceLevel=2 -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceLevel=3 -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceLevel=4 -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceComponents=ALL -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceComponents=Config -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceComponents=Config,XmlParser -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -s traceComponents= -p 1>>$stdout 2>>$stderr

    #Display properties:
    $CIMCONFIG -l -p 1>>$stdout 2>>$stderr

    #Unset the current values:
    $CIMCONFIG -u traceLevel -c 1>>$stdout 2>>$stderr
    $CIMCONFIG -u traceComponents -c 1>>$stdout 2>>$stderr

    #Display properties:
    $CIMCONFIG -l -c 1>>$stdout 2>>$stderr

    #Unset the planned values:
    $CIMCONFIG -u traceLevel -p 1>>$stdout 2>>$stderr
    $CIMCONFIG -u traceComponents -p 1>>$stdout 2>>$stderr

    #Display properties:
    $CIMCONFIG -l -p 1>>$stdout 2>>$stderr
    tc_pass_or_fail "$?" "$CIMCONFIG ouput unexpected"
}

function cimprovtest()
{
    tc_register "$CIMPROVIDER test"

    restart_cimserver
    tc_fail_if_bad $? "cim server did not start properly after $CIMCONFIG" || return

    $CIMPROVIDER -l -s >$stdout 2>$stderr
    tc_fail_if_bad $? "First $CIMPROVIDER -l -s FAILED" || return
    grep -q "OperatingSystemModule *OK" <$stdout
    tc_fail_if_bad $? "First $CIMPROVIDER -l -s did not say OK" || return

    $CIMPROVIDER -d -m OperatingSystemModule >$stdout 2>$stderr
    tc_fail_if_bad $? "$CIMPROVIDER -d -m OperatingSystemModule FAILED" || return

    $CIMPROVIDER -l -s >$stdout 2>$stderr
    tc_fail_if_bad $? "Second $CIMPROVIDER -l -s FAILED" || return
    grep -q "OperatingSystemModule *Stopped" <$stdout
    tc_fail_if_bad $? "Second $CIMPROVIDER -l -s did not say Stopped" || return

    $CIMPROVIDER -e -m OperatingSystemModule >$stdout 2>$stderr
    tc_fail_if_bad $? "$CIMPROVIDER -e -m OperatingSystemModule FAILED" || return

    $CIMPROVIDER -l -s >$stdout 2>$stderr
    grep -q "OperatingSystemModule *OK" <$stdout
    tc_pass_or_fail $? "Third $CIMPROVIDER -l -s did not say OK"
}

function osinfo_unix()
{
    local my_uname=$(uname -r)

    tc_register "$OSINFO with connectLocal via Unix socket"

    #### adding temp user to pegasus group ####
	usermod -a -G pegasus $TC_TEMP_USER

    # grant repository access to TC_TEMP_USER
    $CIMAUTH -a -R -u $TC_TEMP_USER -n root/cimv2 &>/dev/null
    tc_fail_if_bad $? "$CIMAUTH -a -R -u $TC_TEMP_USER -n root/cimv2 FAILED" || return
    
    $OSINFO -u $TC_TEMP_USER -w $TC_TEMP_PASSWD >$stdout 2>$stderr
    tc_fail_if_bad "$?" "$OSINFO failed" || return

    grep -q "$my_uname" $stdout
    tc_fail_if_bad $? "Expected to see $my_uname in stdout"

    $CIMAUTH -r -R -u $TC_TEMP_USER -n root/cimv2 &>/dev/null
    tc_pass_or_fail $? "$CIMAUTH -r -R -u $TC_TEMP_USER -n root/cimv2 FAILED"
}

function osinfo_http()
{
    local my_uname=$(uname -r)

    tc_register "$OSINFO with HTTP"

    # grant repository access to TC_TEMP_USER
    $CIMAUTH -a -R -u $TC_TEMP_USER -n root/cimv2 &>/dev/null
    tc_fail_if_bad $? "$CIMAUTH -a -R -u $TC_TEMP_USER -n root/cimv2 FAILED" || return

    $OSINFO -h $(hostname) -u $TC_TEMP_USER -w $TC_TEMP_PASSWD >$stdout 2>$stderr
    tc_fail_if_bad "$?" "$OSINFO failed" || return

    grep -q "$my_uname" $stdout
    tc_fail_if_bad $? "Expected to see $my_uname in stdout"

    $CIMAUTH -r -R -u $TC_TEMP_USER -n root/cimv2 &>/dev/null
    tc_pass_or_fail $? "$CIMAUTH -r -R -u $TC_TEMP_USER -n root/cimv2 FAILED"
}

function osinfo_tc()
{
    # fix pam file
    mv /etc/pam.d/wbem{,.orig}
    cat > /etc/pam.d/wbem <<EOF
#%PAM-1.0
auth        required      pam_env.so
auth        sufficient    pam_unix_auth.so likeauth nullok
#auth        required      pam_deny.so
auth        include       common-auth

account     required      pam_unix_acct.so

password    required      pam_cracklib.so retry=3 type=
password    sufficient    pam_unix_passwd.so nullok use_authtok md5 shadow
password    required      pam_deny.so

session     required      pam_limits.so
session     required      pam_unix_session.so
EOF

    tc_add_user_or_break || return

    osinfo_unix

    osinfo_http

    mv /etc/pam.d/wbem{.orig,}
}


################################################################################
# MAIN
################################################################################

tc_setup
installation_check || exit
cimconftest
cimprovtest
osinfo_tc
commonfunc
