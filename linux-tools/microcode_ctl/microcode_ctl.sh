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
### File :        microcode_ctl.sh                                             ##
##
### Description:  Updates the microcode on Intel x86/x86-64 CPU's              ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
MICRO_TEST_DIR="${LTPBIN%/shared}/microcode_ctl"
REQUIRED="intel-microcode2ucode"

function tc_local_setup()
{

    # Check installation
    tc_exec_or_break $REQUIRED || return

    # Check if MICROCODE config is enabled
    tc_check_kconfig CONFIG_MICROCODE_OLD_INTERFACE
    tc_break_if_bad_rc $? "Failed to find the configuration for Micorcode!"

    #Take the backup of dmesg and cleanup
    #so that any old calltraces does not interfere with the test
    dmesg > $TCTMP/dmesg.old
    dmesg -c &>/dev/null

}

function tc_local_cleanup()
{
    #appending the new messages to the old data and writing it back
    cat /var/log/dmesg  >> $TCTMP/dmesg.old
    cp $TCTMP/dmesg.old /var/log/dmesg
}


function run_updatedfile()
{

  tc_register "Uploading microcode from the fix file provided by intel"
  [ -f $MICRO_TEST_DIR/microcode-20090330.dat ] &&  intel-microcode2ucode $MICRO_TEST_DIR/microcode-20090330.dat >$stdout 2>$stderr
  tc_pass_or_fail $? "Failed to upload microcode" || return
  
  dmesg | (! grep -i calltrace)  &>/dev/null
  tc_fail_if_bad $? "Found: Calltrace due to loading of default microcode"

}

############################################################################################
#  main
############################################################################################
TST_TOTAL=1

tc_get_os_arch
if [ "$TC_OS_ARCH" = "i686" -o "$TC_OS_ARCH" = "x86_64" ]
then

    # standard tc_setup
    tc_setup
        run_updatedfile
else
   echo "Microcode is not supported on $TC_OS_ARCH architecture"
fi
