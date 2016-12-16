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
## File :       utempter_tests.sh
##
## Description: This program tests basic functionality of utemp and utempter
##
## Author:      Manoj Iyer  manjo@mail.utexas.edu
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libutempter
source $LTPBIN/tc_utils.source

TESTDIR=${LTPBIN%/shared}/libutempter
PATH=$PATH:/usr/libexec/utempter/

# environment functions                                                          
################################################################################ 
#                                                                                
# local setup                                                                    
#                                                                                
function tc_local_setup()                                                        
{                                                                                
        tc_get_os_arch                                                          
        if [ $TC_OS_ARCH = "ppcnf" ]; then                                      
            ps -C login                                                              
            if [ $? == 0 ];then                                               
                killall login                                           
            fi                                                                      
        fi                                                                                                                                                   
} 
#
# test01 - Test that utmp will display user accounting information.
#        - execute command utmp and look for keywords.
#
test01()
{
    local RC=0       # return code
    tc_register    "utmp functionality"
    
    tc_info "executing command utmp for user accounting info"
    $TESTDIR/utmp >$stdout 2>&1
    tc_fail_if_bad $? "utmp failed to gather required information" || return

    # create a list of things that must be in the output. 
    for string in  "RUN_LVL" "LOGIN" 
    do
        grep -iq $string $stdout
        tc_fail_if_bad $? "failed to find entry for $string in output" || return
    done
    tc_pass_or_fail 0   # PASS if we get this far
}

#
# test02 - check add and del
# Execute ut_wrapper as follows:
#
# $ ut_wrapper $TCTMP/who.1 $TCTMP/who.2
#
# The ut_wrapper does everything for us.
# The results of who commands are available in
# the files mentioned as inputs
# Name of the "pty" is available in stdout in the following format:
# PTS /dev/pts/n
# SEE ut_wrapper.c for more details
test02()
{
    tc_register "utempter"
    $TESTDIR/ut_wrapper $TCTMP/who.add $TCTMP/who.del > $stdout 2>$stderr
    tc_pass_or_fail $? "ut_wrapper failed" || return

    dev=$(grep "^PTS" $stdout | awk '{print $2}') 
    pts=${dev:5}
    if [ "$pts" == "" ]; then
	tc_break "Failed to read pty device from ut_wrapper"
	return
    fi

    tc_info "Using $pts as the pseudo terminal"
    tc_register "utempter add"
    grep "$pts" $TCTMP/who.add | grep -q $USER
    tc_pass_or_fail $? "Unable to find $pts for $USER in \"who\" output"

    # We should not see the "$pts" in who.del, since it should be deleted
    tc_register "utempter del"
    ! ( grep $USER $TCTMP/who.del | grep -q "$pts" )
    tc_pass_or_fail $? "Failed to remove $pts from utmp"
}

###########################################################################
# main
###########################################################################

TST_TOTAL=2
tc_setup
tc_root_or_break || exit
tc_exec_or_break utempter su grep who || exit

test01
test02 
