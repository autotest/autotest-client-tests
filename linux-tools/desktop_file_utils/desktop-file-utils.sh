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
### File :        desktop-file-utils.sh                                        ##
##
### Description:  .desktop files are used to describe an application for       ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
MICRO_TEST_DIR="${LTPBIN%/shared}/desktop_file_utils"
REQUIRED="desktop-file-install desktop-file-validate update-desktop-database"


function tc_local_setup()
{

    # Check installation
    tc_exec_or_break $REQUIRED || return
    cp $MICRO_TEST_DIR/example.desktop $MICRO_TEST_DIR/example.desktop.orig 
}

function tc_local_cleanup()
{
    # Cleanup the file installed
    rm -f /usr/share/applications/example.desktop
    mv $MICRO_TEST_DIR/example.desktop.orig $MICRO_TEST_DIR/example.desktop  
}

function file_install()
{
    tc_register "Installing a desktop file to application dir"
    pushd $MICRO_TEST_DIR
    if [ -f example.desktop ]
    then
    #install file in /usr/share/applications
        desktop-file-install --delete-original -m 711 example.desktop >$stdout 2>$stderr
        tc_pass_or_fail $? "Failed to install the desktop file"
    else
        tc_break "example.desktop file doesnt exist"
    fi
    popd
}

function file_validate()
{
    tc_register "Validating desktop file"

    #Validating desktop file
    desktop-file-validate /usr/share/applications/example.desktop >$stdout 2>$stderr
    tc_pass_or_fail $? "Failed to validate the desktop file"
}

function update_desktop()
{
    tc_register "update desktop database if there are any MIME definitions in .desktop files"

    update-desktop-database >$stdout 2>$stderr
    tc_pass_or_fail $? "Unable to update the desktop database"
}

##########################################################################################################
#  main
##########################################################################################################
TST_TOTAL=3
tc_setup
file_install && file_validate
update_desktop
