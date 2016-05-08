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
## File :        pciutils.sh
##
## Description:  Test pciutils package
##
## Author:       Andrew Pham, apham@austin.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TST_TOTAL=9
REQUIRED="lspci setpci wc"
################################################################################
        
################################################################################
# testcase functions
################################################################################
function test1()
{
        tc_register "lspci -t"
        lspci -t >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response" || return

        [ -s $stdout ]
        tc_pass_or_fail $? "No output."

	grep -q -- '-\[0000:00]-' $stdout && {
		tc_info "no pci hardware so skipping rest of tests"
		TST_TOTAL=1
		exit 0
	}
}

function test2()            
{
        tc_register "lspci -vv"
        lspci -vv >$stdout 2>$stderr
        tc_pass_or_fail $? "Unexpected output."
}

function test3()            
{
        tc_register "lspci -x"
        lspci -x >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response" || return

        grep -q "00:" $stdout &&
        grep -q "10:" $stdout &&
        grep -q "20:" $stdout &&
        grep -q "30:" $stdout 
        tc_pass_or_fail $? "Expected to see 00, 10,20, and 30 in stdout."
}

function test4()            
{
        tc_register "lspci -m"
        lspci -m >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response" || return

        [ -s $stdout ]
        tc_pass_or_fail $? "No output."
}

function test5()            
{
        tc_register "lspci -b"
        lspci -b >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response" || return

        [ -s $stdout ]
        tc_pass_or_fail $? "No output."
}

function test6()            
{
        tc_register "lspci -n"
        lspci -n >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response" || return

        [ -s $stdout ]
        tc_pass_or_fail $? "No output."
}

function test7()            
{
        tc_register "setpci -d"
        setpci -d *:* latency_timer device_id vendor_id >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response" || return

        [ -s $stdout ]
        tc_pass_or_fail $? "No output."
}

function test8()            
{
        tc_register "setpci -s"
        setpci -s *:*.* latency_timer device_id vendor_id >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response" || return

        [ -s $stdout ]
        tc_pass_or_fail $? "No output."
}

function test9()            
{
        tc_register "setpci latency_timer=xx"
        declare -i local i=0

        local Vid
        local Did

        ##########################################################
        # find device id and vendor id which have latency_timer
        ##########################################################
        setpci -d *:* vendor_id device_id latency_timer >$stdout 2>$stderr
        while read tmp
        do
                (( i==0 )) && Vid=$tmp
                (( i==1 )) && Did=$tmp
                (( i==2 )) && {
                        LT=$tmp
                        [ $LT -ne 0  ] && break # found one
                        i=0
                        Vid=""
                        Did=""
                        continue
                }
                (( ++i ))
        done < $stdout
        [ "$Vid" -a "$Did" ]
        tc_break_if_bad $? "Could not find Vid:Did with non-zero latency timer" || return
        tc_info "using Vid:Did of $Vid:$Did and modifying original LT of $LT"

        local old=$(setpci -d $Vid:$Did latency_timer)
         set $old; old=$1        # in case more than one was returned
        local new
        (( new=$old*2 ))
        local cmd="setpci -d $Vid:$Did latency_timer=$new"
        tc_info "issuing $cmd"
        $cmd >$stdout 2>$stderr
        RC=$?
        grep -q "out of range" $stderr && {
                : > $stderr
                tc_info "Got \"out of range error\" but that's OK too"
                tc_pass_or_fail 0	# PASS
                return
        }

        tc_fail_if_bad $RC "Failed to set latency_timer" || return

        setpci -d $Vid:$Did latency_timer >$stdout 2>$stderr
        setpci -d $Vid:$Did latency_timer=$old >&/dev/null
        grep -qv "$old" $stdout
        tc_pass_or_fail $? "Unexpected output." || return
}

################################################################################
# main
################################################################################
tc_setup

# Check if supporting utilities are available
tc_exec_or_break  $REQUIRED || exit

test1 &&
test2 &&
test3 &&
test4 &&
test5 &&
test6 &&
test7 &&
test8 &&
test9
