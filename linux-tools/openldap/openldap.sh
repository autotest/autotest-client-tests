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
## File :        openldap2.sh
##
## Description:  Test openldap2 packages
##
## Author:       Hong Bo Peng <penghb@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

export TEST_DIR=${LTPBIN%/shared}/openldap/openldap-tests

# Tests not supported on bdb backend
BDB_NO_SUPPORT="test040-subtree-rename"

# Tests not supported on hdb backend
HDB_NO_SUPPORT=

# The following tests are not supported as they use overlays/memberof features not
# enabled in  builds
#NO_SUPPORT="test031-component-filter test050-syncrepl-multimaster test052-memberof test058-syncrepl-asymmetric"
NO_SUPPORT="test041-aci test050-syncrepl-multimaster test058-syncrepl-asymmetric test031-component-filter test052-memberof test061-syncreplication-initiation test064-constraint test063-delta-multimaster test059-slave-config test022-ppolicy"
META_TESTS="test035-meta test036-meta-concurrency"
 
declare -a TESTS

COMMANDS="ldapsearch ldapcompare ldapmodify ldapmodrdn ldappasswd ldapwhoami /usr/sbin/slapd"

ldap_server="/usr/lib/openldap/slapd"
export OPENLDAP_ROOT=/usr/lib/openldap
IPV6=""
ldapport=389
ipv6_server_host=""
ldap_init_server="/etc/init.d/slapd"
ipv6_localhost="localhost6"
################################################################################
# utilities
################################################################################
function tc_local_setup()
{
        tc_exist_or_break $TEST_DIR/scripts || exit
        tc_ipv6_info && {
                IPV6="yes"
                # prefer link over global over host scope
                [ "$TC_IPV6_host_ADDRS" ] && ipv6_server_host=$TC_IPV6_host_ADDRS
                [ "$TC_IPV6_global_ADDRS" ] && ipv6_server_host=$TC_IPV6_global_ADDRS
                [ "$TC_IPV6_link_ADDRS" ] && ipv6_server_host=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
                ipv6_server_host=$(tc_ipv6_normalize $ipv6_server_host)
        }

        openldap_tests=$(ls $TEST_DIR/scripts/ | grep "^test")

#       Remove the tests not supported.
        for r in $NO_SUPPORT; do
                tc_info "$r is not supported"
                openldap_tests=${openldap_tests/$r}
        done

#       Now remove the tests dependent on meta backends
        for r in $META_TESTS; do
                openldap_tests=${openldap_tests/$r}
        done

        find /usr/lib/openldap/modules/  /usr/lib64/openldap/modules -name back_meta\* &>/dev/null
        if [ $? -eq 0 ];
        then
                tc_info "openldap supports meta backend support"
                META_SUPPORT=yes
        else
                tc_info "openldap doesn't support meta backend support"
                META_SUPPORT=no
        fi
}

function tc_local_cleanup()
{
	tc_service_stop_and_wait slapd
        [ "$IPV6" = "yes" ] && [ -e $TEST_DIR/scripts/defines.sh ] &&
                sed -i 's/LOCALHOST=localhost6/LOCALHOST=localhost/' $TEST_DIR/scripts/defines.sh
        killall slapd &>/dev/null
}
function usage()
{
        tc_info "usage $0 [bdb] [hdb] [meta]"
        tc_info "       example: $0 bdb"
}

function parseargs()
{
        if [ $# = 0 ] ; then
                TESTS=(TC_bdb  TC_hdb "TC_meta bdb" "TC_meta hdb")
        else
                while [ -n "$1" ] ; do
                        case "$1" in
                                hdb)
                                        TESTS[${#TESTS[*]}]=TC_hdb
                                        ;;
                                bdb)
                                        TESTS[${#TESTS[*]}]=TC_bdb
                                        ;;
                                meta)
                                        TESTS[${#TESTS[*]}]="TC_meta bdb"
                                        TESTS[${#TESTS[*]}]="TC_meta hdb"
                                        ;;
                                *)      usage
                                        tc_break_if_bad 1 "Unknown argument $1" || exit
                                        ;;
                        esac
                        shift
                done
        fi
}

function runtests()
{
        for t in "${TESTS[@]}" ; do
                :>$stdout
                :>$stderr
                $t
        done
}

################################################################################
# testcase functions
################################################################################

function base_tests()
{
        #
        # test1
        #
        tc_register "installation check"
        tc_executes $COMMANDS || return
        tc_pass_or_fail $? "openldap2 not properly installed"

        #
        # test2
        #
        tc_register "stopldap"
        #$ldap_init_server stop 2>$stderr 1>$stdout
	tc_service_stop_and_wait slapd
        tc_fail_if_bad $? "couldn't stop slapd" || return
        tc_wait_for_inactive_port 389   # be sure previous use of port is freed up
        tc_pass_or_fail $? "could not stop previous instance of slapd" || return
    sleep 2     # give it a chance to really shut down (potential fix for bug 45333)

        #
        # test3
        #
        tc_register "startldap"
#        $ldap_init_server start &>$stdout       # missing SLP goes to stderr but it is OK
	tc_service_start_and_wait slapd
        tc_fail_if_bad $? "Unable to start the ldap server" || return
        tc_wait_for_active_port 389
        tc_pass_or_fail $? "slapd not listening" || return

        #
        # test4
        #
        tc_register "ldapsearch"
        ldapsearch -x -b '' -s base '(objectclass=*)' namingContexts 1>$stdout 2>$stderr
        tc_pass_or_fail $? "ldapsearch failed" || return

        #
        # test5
        #
        [ $IPV6 = "yes" ] && {
                tc_register "ldapsearch (ipv6)"
                ldapsearch -x -h $ipv6_localhost -p $ldapport -b '' -s base '(objectclass=*)' namingContexts 1>$stdout 2>$stderr

                tc_pass_or_fail $? "ldapsearch failed" || return

                tc_register "ldapwhoami (ipv6)"

                ldapwhoami -x -h $ipv6_localhost -p $ldapport  1>$stdout 2>$stderr
                tc_pass_or_fail $? "ldapwhoami failed" || return

        }

        #
        # test6
        #
        tc_register "stopldap (again)"
#        $ldap_init_server stop 2>$stderr 1>$stdout
	tc_service_stop_and_wait slapd
        tc_fail_if_bad $? "couldn't stop slapd" || return
        tc_wait_for_inactive_port 389   # be sure previous use of port is freed up
        tc_pass_or_fail $? "could not stop slapd" || return
	sleep 5     # give it a chance to really shut down (potential fix for bug 45333)
}

# Strip of leading 0's
function strip_num()
{
        local n
        while true; do n=${num#0}; [ "$n" == "$num" ] && break; num=$n; done
}


function TC_hdb()
{
        local hdbm_support=$openldap_tests
        local db=hdb

        for r in $HDB_NO_SUPPORT ; do
                tc_info "$r is not supported on hdb"
                hdbm_support=${hdbm_support/$r}
        done

        hdbm_ipv4=""
        hdbm_ipv6=""

        for r in $hdbm_support; do
                num=${r:4:3}
                strip_num
                if [ $((num % 4)) -eq 0 ];
                then
                        hdbm_ipv4="$hdbm_ipv4 $r"
                elif [ $((num % 4)) -eq 1 ];
                then
                        hdbm_ipv6="$hdbm_ipv6 $r"
                fi
        done

        set $hdbm_ipv4
        ((TST_TOTAL+=$#))

        tc_info "Added $# tests for hdb suite of tests"

        for CMD in $hdbm_ipv4; do
                CMD=$TEST_DIR/scripts/$CMD
                #tc_exec_or_break $CMD "missing test command" || continue
                # get the filename
                CMD=`expr $CMD : '.*/\(.*\)' '|' $CMD`
                tc_register "$db: $CMD"
                $TEST_DIR/run -b $db $CMD >$stdout 2>&1
                tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                grep -q "Test succeeded" $stdout
                tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                tc_wait_for_inactive_port 389
                tc_pass_or_fail $? "Couldn't shut down slapd" || return
        done

        [ $IPV6 = "yes" ] && {

                sed -i 's/LOCALHOST=localhost/LOCALHOST=localhost6/' $TEST_DIR/scripts/defines.sh

                set $hdbm_ipv6
                ((TST_TOTAL+=$#))
                tc_info "Added $# tests for hdbm suite of tests"
                for CMD in $hdbm_ipv6; do
                        CMD=$TEST_DIR/scripts/$CMD
                        #tc_exec_or_break $CMD "missing test command" || continue
                        # get the filename
                        CMD=`expr $CMD : '.*/\(.*\)' '|' $CMD`
                        tc_register "$db: $CMD (ipv6)"
                        $TEST_DIR/run -b $db $CMD >$stdout 2>&1
                        tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                        grep -q "Test succeeded" $stdout
                        tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                        tc_wait_for_inactive_port 389
                        tc_pass_or_fail $? "Couldn't shut down slapd" || return
                done
                sed -i 's/LOCALHOST=localhost6/LOCALHOST=localhost/' $TEST_DIR/scripts/defines.sh
        }

}

function TC_bdb()
{
        local db=bdb
        local bdb_support=$openldap_tests

        for r in $BDB_NO_SUPPORT ; do
                tc_info "$r is not supported on bdb"
                bdb_support=${bdb_support/$r}
        done

        local bdb_ipv4=""
        local bdb_ipv6=""

        local i=0;
        local j=0;

        for r in $bdb_support; do
                num=${r:4:3}
                strip_num
                if [ $((num % 4)) -eq 2 ];
                then
                        bdb_ipv4="$bdb_ipv4 $r"
                        ((i++))
                fi
                if [ $((num % 4)) -eq 3 ];
                then
                        bdb_ipv6="$bdb_ipv6 $r"
                        ((j++))
                fi
        done
        set $bdb_ipv4
        ((TST_TOTAL+=$#))
        tc_info "Added $# tests for bdb suite of tests"
        for CMD in $bdb_ipv4; do
                CMD=$TEST_DIR/scripts/$CMD
                #tc_exec_or_break $CMD "missing test command" || continue
                # get the filename
                CMD=`expr $CMD : '.*/\(.*\)' '|' $CMD`
                tc_register "$db: $CMD"
                $TEST_DIR/run -b $db $CMD >$stdout 2>&1
                tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                grep -q "Test succeeded" $stdout
                tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                tc_wait_for_inactive_port 389
                tc_pass_or_fail $? "Couldn't shut down slapd" || return
        done

        ipv6_server_host="localhost6"
        [ $IPV6 = "yes" ] && {
                sed -i 's/LOCALHOST=localhost/LOCALHOST=localhost6/' $TEST_DIR/scripts/defines.sh

                set $bdb_ipv6
                ((TST_TOTAL+=$#))
                tc_info "Added $# tests for bdb(ipv6) suite of tests"
                for CMD in $bdb_ipv6; do
                        CMD=$TEST_DIR/scripts/$CMD
                        #tc_exec_or_break $CMD "missing test command" || continue
                        # get the filename
                        CMD=`expr $CMD : '.*/\(.*\)' '|' $CMD`
                        tc_register "$db: $CMD (ipv6)"
                        $TEST_DIR/run -b $db $CMD >$stdout 2>&1
                        tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                        grep -q "Test succeeded" $stdout
                        tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                        tc_wait_for_inactive_port 389
                        tc_pass_or_fail $? "Couldn't shut down slapd" || return
                done
                sed -i 's/LOCALHOST=localhost6/LOCALHOST=localhost/' $TEST_DIR/scripts/defines.sh
        }

}

function TC_meta()
{

        if [ "x$META_SUPPORT" != "xyes" ];
        then
        # No meta backend support
                return
        fi

        local db=$1
        local meta_tests=$META_TESTS

        set $meta_tests
        ((TST_TOTAL+=$#))
        tc_info "Added $# test(s) for meta $db suite of tests "
        for CMD in $meta_tests; do
                CMD=$TEST_DIR/scripts/$CMD
                [ -x $CMD ]
                #tc_break_if_bad $? "$CMD not found or unexutebale" || continue
                # get the filename
                CMD=`expr $CMD : '.*/\(.*\)' '|' $CMD`
                tc_register "$db: $CMD"
                $TEST_DIR/run -b $db $CMD >$stdout 2>&1
                tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                grep -q "Test succeeded" $stdout
                tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                tc_wait_for_inactive_port 389
                tc_pass_or_fail $? "Couldn't shut down slapd" || return
        done

        [ $IPV6 = "yes" ] && {
                sed -i 's/LOCALHOST=localhost/LOCALHOST=localhost6/' $TEST_DIR/scripts/defines.sh

                set $meta_tests
                ((TST_TOTAL+=$#))
                tc_info "Added $# test(s) for meta $db(ipv6) suite of tests "
                for CMD in $meta_tests; do
                        CMD=$TEST_DIR/scripts/$CMD
                        [ -x $CMD ]
                        #tc_break_if_bad $? "$CMD not found or unexutebale" || continue
                        # get the filename
                        CMD=`expr $CMD : '.*/\(.*\)' '|' $CMD`
                        tc_register "$db: $CMD (ipv6)"
                        $TEST_DIR/run -b $db $CMD >$stdout 2>&1
                        tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                        grep -q "Test succeeded" $stdout
                        tc_fail_if_bad $? "Failed in $db testing: $CMD." || continue

                        tc_wait_for_inactive_port 389
                        tc_pass_or_fail $? "Couldn't shut down slapd" || return
                done
                sed -i 's/LOCALHOST=localhost6/LOCALHOST=localhost/' $TEST_DIR/scripts/defines.sh
        }
}

################################################################################
# main
################################################################################
TST_TOTAL=5
tc_setup 7200   # give it two hours.

# Test openldap2, openldap2-client and openldap2-back-*
parseargs "$@"  # exits on error
base_tests
runtests
