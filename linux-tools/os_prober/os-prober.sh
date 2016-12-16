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
### File : os-prober                                                           ##
##
### Description: This testcase tests os-prober package                         ##
##
### Author:      UmerQayam<umeqayam@in.ibm.com>                                ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/os_prober
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%bin}/fivextra/osprober"
REQUIRED="mount grep"

function tc_local_setup()
{
     tc_exec_or_break $REQUIRED || return

     rpm -q os-prober 1>$stdout 2>$stderr
     tc_break_if_bad $? "os-prober is not installed properly..!"


     mkdir -p $TCTMP/OS-PROBER
     touch $TCTMP/OS-PROBER/file.txt >$stdout 2>$stderr
     tc_break_if_bad $? "file creation failed"
}

function test01()
{
    tc_register "Test os-prober"
    os-prober >$stdout 2>$stderr
    tc_pass_or_fail $? "os-prober command failed to execute"

    # copy the content of $stdout to $TCTMP/OS-PROBER/file.txt
    cp $stdout $TCTMP/OS-PROBER/file.txt
   
    tc_register "Test os-prober is mounted or not"
    mount | grep -v "/var/lib/os-prober/mount" >$stdout 2>$stderr
    tc_pass_or_fail $? "Failed: os-prober is mounted"
}

function test02()
{
    tc_register "Test linux-boot-prober"
    partitions=`cut -d ":" -f 1 $TCTMP/OS-PROBER/file.txt`
    for part in $partitions; do
 	linux-boot-prober $part >$stdout 2>$stderr
        tc_pass_or_fail $? "linux-boot-prober command failed"
    done
}

tc_setup
TST_TOTAL=3
test01
test02
