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
## File :   dmidecode_test.sh
##
## Description: This program tests basic functionality of dmidecode command.
##
## Author:   Xie Jue <xiejue@cn.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/dmidecode
source $LTPBIN/tc_utils.source

#
# test01	Installation check
#
function test01()
{
	tc_register "dmidecode installation check"

	tc_executes dmidecode biosdecode vpddecode ownership
	tc_pass_or_fail $? "dmidecode not properly installed"
}

#
# test02	Test dmidecode commands
#
function test02()
{
	tc_register    "dmidecode displays DMI information"

	dmidecode >$stdout 2>$stderr
	tc_fail_if_bad $? "dmidecode failed to print default settings" || return

        keywords="DMI BIOS Processor Memory"
        for kwd in $keywords ; do
                grep -qi "$kwd" $stdout
                tc_fail_if_bad $? "expected keyword \"$kwd\" not found" || return
        done
        tc_pass_or_fail 0       # PASS if we get this far
}

#
# test03	Test biosdecode commands
#
function test03()
{
	tc_register    "biosdecode displays BIOS information"

	biosdecode >$stdout 2>$stderr
	tc_fail_if_bad $? "failed to print default settings" || return

        keywords="BIOS "
        for kwd in $keywords ; do
                grep -qi "$kwd" $stdout
                tc_fail_if_bad $? "expected keyword \"$kwd\" not found" || return
        done
        tc_pass_or_fail 0       # PASS if we get this far

}


#
# test04	Test vpddecode commands
#
function test04()
{
	tc_register    "vpddecode displays VPD information"

	vpddecode >$stdout 2>$stderr || grep -q "No VPD structure found" $stdout
	tc_fail_if_bad $? "failed to print default settings" || return

        keywords="VPD vpddecode"
        for kwd in $keywords ; do
                grep -qi "$kwd" $stdout
                tc_fail_if_bad $? "expected keyword \"$kwd\" not found" || return
        done
        tc_pass_or_fail 0       # PASS if we get this far
}

# 
# main
# 

TST_TOTAL=4
tc_setup
tc_run_me_only_once
tc_exec_or_break grep || exit
tc_root_or_break || exit

MACH=$(uname -m)
ALLOW="ia64 i.86 x86_64"
OK=no
for a in $ALLOW ; do
        echo $MACH | grep -q "$a" || continue
        OK=yes
        tc_info "Running against machine type $MACH"
        break
done
[ "$OK" = yes ]
tc_break_if_bad $? "Must run on x86 or ia64 architecture" || exit

test01
test02
test03
test04
