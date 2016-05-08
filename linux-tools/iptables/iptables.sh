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
## File :    iptables.sh
##
## Description:  Test iptables support
##
## Author:   Helen Pang, hpang@us.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# any utility functions specific to this file can go here
################################################################################

function tc_local_setup()
{
    tc_exec_or_break iptables iptables-save iptables-restore || return
    tc_root_or_break || return

     if [ "$TEST" != "ipv4" -a "$TEST" != "ipv6" ]; then
      tc_warn "Missing or invalid argument."
      tc_info "#################################"
      tc_info "OPTION MUST BE ONE OF THESE:"
      tc_info "ipv4 ipv6"
      tc_info "such as these:"
      tc_info "./iptables.sh ipv4"
      tc_info "./iptables.sh ipv6"
      tc_info "#################################"
       exit 1
     fi
    
    # check whether iptables modules load successfully
    iptables -L >$stdout 2>$stderr
    tc_fail_if_bad $? "Trouble loading modules?" || return

    # save current rules, if any
    iptables-save -c > $TCTMP/iptables-save
    tc_fail_if_bad $? "iptables-save failed to save the current rule-set" \
        || return
    
    # Remove all pre-existing rules
    iptables --flush >$stdout 2>$stderr
    tc_fail_if_bad $? "Trouble flushing iptables rule-set"
}

function tc_local_cleanup()
{
    # retore rules saved at beginning
    [ -s $TCTMP/iptables-save ] && {
        iptables-restore -c < $TCTMP/iptables-save >$stdout 2>$stderr
        tc_fail_if_bad $? "iptables_restore failed to restore rule-set" \
            || return
    }
}

################################################################################
# the testcase functions
################################################################################

#
# test01   (set/check rules: append(-A), delete(-D), list(-L))
#
function test01()
{
        tc_register "use rule to block $ping_cmd ($TEST)"
        # add DROP rule 
        $iptables_cmd -A INPUT -s $ip_address -p $icmp_cmd -j DROP >$stdout 2>$stderr
    tc_fail_if_bad $? \
        " $iptables_cmd -A INPUT -s $ip_address -p $icmp_cmd -j DROP failed" ||
        return

    # be sure DROP rule is set
    $iptables_cmd -L INPUT >$stdout 
    tc_fail_if_bad $? "$iptables_cmd -L INPUT failed" || return
    grep -q DROP $stdout 2>$stderr
    tc_fail_if_bad $? "failed to list DROP" || return

    # check that ping DROPped
    $ping_cmd -c 1 -w 5 $ip_address &>$stdout
    [ $? -ne 0 ]
    tc_fail_if_bad $? "failed to DROP" || return

    # delete DROP rule
    $iptables_cmd -D INPUT -s $ip_address -p $icmp_cmd -j DROP >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -D INPUT -s $ip_address -p $icmp_cmd -j DROP failed" || return

    # be sure DROP rule is deleted
    $iptables_cmd -L INPUT >$stdout 
    tc_fail_if_bad $? "$iptables_cmd -L INPUT failed" || return
    ! grep -q DROP $stdout 2>$stderr
    tc_fail_if_bad $? "failed to delete DROP" || return

    # check that ping now works
    $ping_cmd -c 1 $ip_address >$stdout 2>$stderr
    tc_pass_or_fail $? "failed to delete DROP; $ping_cmd still works!"
                
}

#
# test02   (set/check chain-command: create-chain(-N), and delete-chain(-X))
#
function test02()
{
       
        tc_register "set/check chain ($TEST)"
    tc_exec_or_break touch || return

    # add user defined new chain: -N 
    new="new-chain"
    $iptables_cmd -N $new >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -N $new failed" || return

    # check if $new exist
    $iptables_cmd -L >$stdout
    grep -q $new $stdout 2>$stderr
    tc_fail_if_bad $? "failed to create chain: $new" || return

    # remove user defined new chain: -X
    $iptables_cmd -X $new >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -X $new failed" || return

    # $new should now be gone
    $iptables_cmd -L >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -L failed" || return
    grep -q $new $stdout >> $stderr
    [ $? -ne 0 ]
    tc_pass_or_fail $? "failed to delete new chain"
        
}

#
# test03    (set/check policy for chains)
#
function test03()
{
        tc_register "set/check policy ($TEST)"

    # set/check policy on INPUT chain 
        $iptables_cmd -P INPUT ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -P INPUT ACCEPT failed" || return
    $iptables_cmd -L INPUT >$stdout
    tc_fail_if_bad $? "$iptables_cmd -L INPUT failed" || return
    grep -q ACCEPT $stdout 2>$stderr
    tc_fail_if_bad $? "failed to set policy on INPUT" || return

    # set/check policy on OUTPUT chain
    $iptables_cmd -P OUTPUT ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -P OUTPUT ACCEPT failed" || return
    $iptables_cmd -L OUTPUT >$stdout
    tc_fail_if_bad $? "$iptables_cmd -L OUTPUT failed" || return
    grep -q ACCEPT $stdout 2>$stderr
    tc_fail_if_bad $? "failed to set policy on OUTPUT" || return

    # set/check policy on FORWARD chain
    $iptables_cmd -P FORWARD ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -P FORWARD ACCEPT failed" || return
    $iptables_cmd -L FORWARD >$stdout
    tc_fail_if_bad $? "$iptables_cmd -L FORWARD failed" || return
    grep -q ACCEPT $stdout 2>$stderr
    tc_pass_or_fail $? "failed to set policy on FORWARD"
        
}   

#
# test04    (set/check match -m  and state --state)
#
function test04()
{
    tc_register "set/check match and state ($TEST)"

    # set -m with its --state options for FORWARD chain
    $iptables_cmd -A FORWARD -m state --state NEW -j ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -A FORWARD -m state --state NEW -j ACCEPT failed" || return

    # check -m and --state
    $iptables_cmd -L FORWARD >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -L FORWARD failed" || return
    grep -q NEW $stdout 2>$stderr
    tc_pass_or_fail $? "failed to set match and state options"
                
}

#
# test05    (set/check flush in filter and mangle tables)
#
function test05
{
    tc_register "set/check flush ($TEST)"
# test05 need not be executed on ppcnf
    tc_get_os_arch                                           
    if [ "$TC_OS_ARCH" == ppcnf ]; then         
       tc_info "set/check flush test is not executed on ppcnf. Refer bug 72848"
       return;                          
    fi     
    # flush the filter table
    $iptables_cmd -F >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -F failed" || return

    # add DROP so we can flush it
    $iptables_cmd -A INPUT -j DROP >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -A INPUT -j DROP failed" || return
    $iptables_cmd -L >$stdout
    tc_fail_if_bad $? "$iptables_cmd -L failed" || return
    grep -q DROP $stdout 2>$stderr
    tc_fail_if_bad $? "failed to set DROP" || return

    # flush the filter table and be sure DROP is gone
    $iptables_cmd -F >$stderr 2>$stdout
    tc_fail_if_bad $? "$iptables_cmd -F failed" || return
    $iptables_cmd -L >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -L failed" || return
    grep -q DROP $stdout 2>$stderr
    [ $? -ne 0 ]
    tc_fail_if_bad $? "failed to flush DROP" || return

    # flush the mangle table
    $iptables_cmd -F -t mangle >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -F -t mangle failed" || return

    # add DROP so we can flush it
    $iptables_cmd -t mangle -A INPUT -j DROP >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -t mangle -A INPUT -j DROP failed" || return
    $iptables_cmd -L -t mangle >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -L -t mangle failed" || return
    grep -q DROP $stdout 2>$stderr
    tc_fail_if_bad $? "failed to set DROP" || return

    # flush the mangle table and be sure DROP is gone
    $iptables_cmd -F -t mangle >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -F -t mangle failed" || return
    $iptables_cmd -L -t mangle >$stdout 2>$stderr
    tc_fail_if_bad $? "$iptables_cmd -L -t mangle failed" || return
    grep -q DROP $stdout 2>$stderr
    [ $? -ne 0 ]
    tc_pass_or_fail $? "failed to flush DROP"
              

}   

##########################################################################################
# main
##########################################################################################

TEST=$1

# standard tc_setup
tc_setup

case "$TEST" in
ipv4 )
((TST_TOTAL=5))
# IPv4 unconditionally
tc_info "BEGIN IPv4 TESTS"
ping_cmd=ping
iptables_cmd=iptables
icmp_cmd=icmp
ip_address=127.0.0.1
test01 
test02 
test03 
test04 
test05 ;;

ipv6 )


# IPv6 if enabled
tc_ipv6_info || exit
[ "$TC_IPV6_host_ADDRS" ] || exit
tc_info "BEGIN IPv6 host scope TESTS"
((TST_TOTAL=5))
ping_cmd=ping6
iptables_cmd=ip6tables
icmp_cmd=icmpv6
ip_address=$TC_IPV6_host_ADDRS
test01 
test02 
test03 
test04 
test05 

[ "$TC_IPV6_global_ADDRS" ] || exit
tc_info "BEGIN IPv6 global scope TESTS"
((TST_TOTAL+=5))
ip_address=$TC_IPV6_global_ADDRS
test01 
test02 
test03 
test04 
test05 ;;

* ) echo "Use one of the given options from the list" ;;
esac
