#!/bin/bash
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
#                                                                            
# File :        gconf.sh              
#
# Description:	This script tests basic fundtionality of gconftool
#
# Author:  Poornima.Nayak <mpnayak@linux.vnet.ibm.com>
#
###########################################################################################

# source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/GConf2
TESTDIR=${LTPBIN%/shared}/GConf2/
REQUIRED="gconftool-2 gconf-merge-tree grep cat"
source $LTPBIN/tc_utils.source
created_config=0

MSG_DIR=/var/spool/mail

################################################################################
# local utility function
################################################################################

#
# tc_local_setup
#
function tc_local_setup()
{
    tc_root_or_break || return
    tc_exec_or_break $REQUIRED || return
    
    #backup schema which is going to be modified    
    cp /etc/gconf/schemas/desktop_default_applications.schemas $TCTMP/

    #Create .config directory if it doesnt exist already.
    if [ ! -d ~/.config ]; then
        mkdir ~/.config
        created_config=1
    fi
}
#
# Local cleanup
#
tc_local_cleanup()
{
    #Copy back original file
    cp $TCTMP/desktop_default_applications.schemas \
         /etc/gconf/schemas/desktop_default_applications.schemas 
    #Unset set values
    gconftool-2 --unset /apps/panel/global/tooltips_enabled
   
    #Remove created .config directory
    if [ $created_config -eq 1 ]; then
        rm -rf ~/.config
    fi
}
#
# Test Gonftool get functionality
#
test01()
{
    tc_register "Test gconftool get functionality"
    gconftool-2 --get  /system/http_proxy/port | grep -q 8080
    tc_pass_or_fail $? "gconftool get functionality failed"
}
#
# Verify set functionality of gconftool-2
#
test02()
{
    tc_register "Test gconftool set functionality"
    gconftool-2 -s /apps/panel/global/tooltips_enabled -t bool false
    tc_fail_if_bad $? "Failed to set gconf setting"

    gconftool-2 --get /apps/panel/global/tooltips_enabled
    tc_pass_or_fail $? "gconftool set functionality failed" 
}
#
# Verify gconftool displays values of all keys in the gnome desktop
#
test03()
{
    tc_register "Test gconftool displays values of all keys in gnome desktop"
    gconftool-2 -R /desktop/gnome | grep -q firefox
    tc_pass_or_fail $? "gconftool display functionality failed"
}
#
# Verify gconf-merge-tree
#
test04()
{
    tc_register "Test gconf merge tree functionality"
    echo $TCTMP
    mkdir $TCTMP/test
    mkdir $TCTMP/test/sub1
    mkdir $TCTMP/test/sub2
    cp $TESTDIR%gconf.xml $TCTMP/test/
    cp $TESTDIR%gconf.xml $TCTMP/test/sub1/
    cp $TESTDIR%gconf.xml $TCTMP/test/sub2/
    gconf-merge-tree $TCTMP/test
    tc_fail_if_bad $? "Failed gconf-merge-tree command"
    find $TCTMP/test -name %gconf-tree.xml | grep -q %gconf-tree.xml
    tc_fail_if_bad $? "Failed to create %gconf-tree.xml"
    grep -q "sub1" $TCTMP/test/%gconf-tree.xml
    tc_fail_if_bad $? "Failed to merge sub1 directory"
    grep -q "sub2" $TCTMP/test/%gconf-tree.xml
    tc_pass_or_fail $? "Failed to merge gconf files in sub2"
}
#
# Verify gconftool interface with schema files
#
test05()
{
    tc_register "Test gconftools install schema functionality"
    # Take a schema file from system under test
    gconftool-2 --install-schema-file=$TCTMP/desktop_default_applications.schemas | 
        grep -q "Installed schema" 
    tc_pass_or_fail $? "Failed gconftool install schema"
}
#
# Main
#
TST_TOTAL=5
tc_setup

test01
test02
test03
test04
test05
