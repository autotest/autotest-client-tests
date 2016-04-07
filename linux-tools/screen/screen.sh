#!/bin/bash
###########################################################################################
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
############################################################################################
##                                                                            ##
## File :        screen.sh                                                    ##
##                                                                            ##
## Description:  Test for screen                                              ##
##                                                                            ##
## Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
##                                                                            ##
################################################################################
# source the utility functions
#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
SCREEN_TEST_DIR="${LTPBIN%/shared}/screen"
REQUIRED="screen"

function tc_local_setup()
{
    # Check installation
    tc_exec_or_break $REQUIRED 
}

function tc_local_cleanup()
{
   pid=`screen -ls |grep testscreen| awk -F'.' '{print $1}'`
   kill -9 $pid
   pid1=`screen -ls |grep pts| awk -F'.' '{print $1}'`
   kill -9 $pid1
   #Remove the dead screens(cleanup Sockdir)
   screen -wipe > /dev/null
   rm -f $SCREEN_TEST_DIR/screenlog.0 $SCREEN_TEST_DIR/config.txt
}

function run_tests()
{
    pushd $SCREEN_TEST_DIR  &> /dev/null

    cat > config.txt <<EOF
    termcapinfo xterm* ti@:te@
    startup_message off
    vbell off
    autodetach on
    altscreen on
    shelltitle "$ |bash"
    defscrollback 10000
    defutf8 on
    nonblock on

    hardstatus alwayslastline
    hardstatus string '%{= kw}[ %{= kb}%H%{= kw} ][%= %{= kw}%?%-Lw%?%{= kW}%n*%f %t%?%?%{= kw}%?%
    +Lw%?%?%= ][ %{r}%l%{w} ]%{w}[%{r} %d/%m/%y %C %A %{w}]%{w}'

    bind 'q' quit

    # syntax: screen -t label order command
    screen -t test01 0
    screen -t test02 1

EOF

    tc_register "Testing screen"
    export TERM=xterm; expect ./test.exp > $stdout 2>$stderr
    tc_pass_or_fail $? "Failed: Screen test"

    tc_register "Check for screen logging"
    cat screenlog.0 |grep -q "hi"  > $stdout 2>$stderr
    tc_pass_or_fail $? "Failed to turn on output logging"
 
}

tc_setup
run_tests
TST_TOTAL=2
