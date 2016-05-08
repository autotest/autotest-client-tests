#!/bin/sh
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
## File :        ebtables.sh
##
## Description:  This program tests basic functionality of ebtables package
##
## Author:       Anitha MallojiRao
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
################################################################################
#utility functions specific to this file
################################################################################
Required=ebtables ebtables-restore ebtables-save
ip_address=127.0.0.1
mac_address=00:11:22:33:44:55

function tc_local_setup()
{
    tc_exec_or_break $Required || return
    tc_root_or_break || return
}

function tc_local_cleanup()
{
    # restore rules saved at beginning
    [ -s $TCTMP/ebtables-save ] && {
       ebtables-restore  < $TCTMP/ebtables-save >$stdout 2>$stderr
       tc_break_if_bad $? "ebtables_restore failed to restore rule-set" 
    }
}
################################################################################
# the testcase functions
################################################################################

# test00

function test00()
{
    tc_register "Load ebtables rules & save the current rules"
    # loading ebtables rules
    ebtables -L >$stdout 2>$stderr
    tc_fail_if_bad $? "loading ebtables rules: failed" || return

    # save current rules, if any with current values of all packet and byte counters
    ebtables-save >$stdout 2>$stderr
    tc_pass_or_fail $? "ebtables-save failed to save the current rule-set" \
         || return

    cp $stdout $TCTMP/ebtables-save

    #Flush all the rules before the testing begins
    ebtables -F > /dev/null
 }

# test01   (set/check rules: append(-A), delete(-D), list(-L))

function test01()
{
    tc_register "set/check rules"
    # add DROP rule
    ebtables -A INPUT -p IPV4 --ip-src $ip_address -s ! $mac_address -j DROP  >$stdout 2>$stderr
    tc_fail_if_bad $? \
    "ebtables -A INPUT -p IPV4 --ip-src $ip_address -s ! $mac_address -j DROP failed" || return
    # make sure DROP rule is set
    ebtables -L INPUT | grep -q DROP >$stdout 2>$stderr
    tc_fail_if_bad $? "Failed to list Drop rule as it is not set!" || return

    # delete DROP rule
    ebtables -D INPUT -p IPV4 --ip-src $ip_address -s ! $mac_address -j DROP | grep -q DROP >$stdout 2>$stderr
    [ $? -ne 0 ]
    tc_pass_or_fail $? "Drop rule is not removed"
}

# test02   (set/check chain-command: create-chain(-N), and delete-chain(-X))

function test02()
{

    tc_register "set/check chain"
       
    #Flush all the rules before the testing begins
    ebtables -F > /dev/null

    # add user defined new chain: -N
    chain_name="new-chain"
    ebtables -N $chain_name >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -N $chain_name failed" || return

    # check if new-chain exist
    ebtables -L $chain_name >$stdout 2>$stderr
    tc_fail_if_bad $? "failed to list new-chain: $chain_name" 

    # remove user defined new chain: -X
    ebtables -X $chain_name >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -X $chain_name failed" || return

    # new-chain should now be gone
    ebtables -L |grep $chain_name >$stdout 2>$stderr
    [ $? -ne 0 ]
    tc_pass_or_fail $? "$chain_name is still listed! Please make sure it is removed"

}


#test03    (set/check policy for chains)

function test03()
{

    tc_register "set/check policy"

    #Flush all the rules before the testing begins
    ebtables -F > /dev/null

    # set/check policy on INPUT chain
    ebtables -P INPUT ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -P INPUT ACCEPT failed" || return
    ebtables -L INPUT | grep -q ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -L INPUT | grep -q ACCEPT failed" 

    # set/check policy on OUTPUT chain
    ebtables -P OUTPUT ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -P OUTPUT ACCEPT failed" || return
    ebtables -L OUTPUT | grep -q ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "failed to set policy on OUTPUT"

    # set/check policy on FORWARDain_chain
    ebtables -P FORWARD ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -P FORWARD ACCEPT failed" || return
    ebtables -L FORWARD | grep -q ACCEPT >$stdout 2>$stderr
    tc_pass_or_fail $? "ebtables -L FORWARD | grep -q ACCEPT failed" 

}

#test04 (set/check flush in filter and nat table)

function test04()
{
    tc_register "set/check flush filter table"

    # flush the filter table
    ebtables -F >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -F failed" || return

    # add DROP so we can flush it
    ebtables -A INPUT -j DROP >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -A INPUT -j DROP failed" || return
    ebtables -L | grep -q DROP >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -L | grep -q DROP failed" 
      
    # flush the filter table and be sure DROP is gone
    ebtables -D INPUT -j DROP >$stderr 2>$stdout
    tc_fail_if_bad $? "ebtables -D INPUT -j DROP failed" || return
    ebtables -L | grep -q DROP >$stdout 2>$stderr
    [ $? -ne 0 ]
    tc_fail_if_bad $? "ebtables -L | grep -q DROP"

    #flush the nat table
    ebtables -t nat -F >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -t nat -F failed" || return

    # use arpreply so we can flush it
    ebtables -t nat -A PREROUTING -p arp --arp-opcode Request -j arpreply \
    --arpreply-mac $mac_address --arpreply-target ACCEPT >$stdout 2>$stderr
    tc_fail_if_bad $? "arp request failed to populate the arp-cache" || return
    ebtables -t nat -L | grep -q arpreply >$stdout 2>$stderr
    tc_fail_if_bad $? "Failed to list arpreply" 

    # flush the nat table and be sure DROP is gone
    ebtables -t nat -F >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -t nat -F failed" || return
    ebtables -t nat -L | grep -q arpreply >$stdout 2>$stderr
    [ $? -ne 0 ]
    tc_pass_or_fail $? "arpreply is still listed! Please make sure it is removed"
}

#test05 (Atomically load or update a nat table)

function test05()
{
    tc_register "load or update a nat table"

    #Flush all the rules before the testing begins
    ebtables -F > /dev/null

    #First put the kernel's table into the file nat_table
    ebtables --atomic-file $TCTMP/nat_table -t nat --atomic-save >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables --atomic-file nat_table -t nat --atomic-save failed" || return

    #zero the counters of the rules in the file
    ebtables -t nat --atomic-file $TCTMP/nat_table -Z >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -t nat --atomic-file nat_table -Z failed" || return

    #build up the complete table in the file EBTABLES_ATOMIC_FILE
    export EBTABLES_ATOMIC_FILE=$TCTMP/nat_table

    #Now initialize the file with the default table
    ebtables -t nat --atomic-init >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -t nat --atomic-init failed" || return

    #We can add our own rules to the table
    ebtables -t nat -A PREROUTING -j DROP >$stdout 2>$stderr
    tc_fail_if_bad $? "ebtables -t nat -A PREROUTING -j DROP failed" || return

    #Check if the rules are set in the table
    ebtables -t nat -L --Lc --Ln >$stdout 2>$stderr
    tc_fail_if_bad  $? "ebtables -t nat -L --Lc --Ln failed" || return

    ebtables -t nat --atomic-commit >$stdout 2>$stderr
    tc_pass_or_fail $? " ebtables -t nat --atomic-commit failed"

}

##########################################################################################
# main
##########################################################################################

# standard tc_setup
tc_setup
TST_TOTAL=6
test00 || exit  # installation check

test01
test02
test03
test04
test05
