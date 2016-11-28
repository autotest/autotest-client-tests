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
## File	:	sgml-common.sh
##
## Description:  This program tests basic functionality of sgml-common
##
## Author:       Athira Rajeev <atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/sgml_common
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/sgml_common"


################################################################################
# Utility functions
################################################################################

#
# local setup
#        
function tc_local_setup()
{   
    tc_root_or_break || return    
    tc_exec_or_break install-catalog sgmlwhich || return

    tc_exists /etc/sgml/sgml.conf 
    tc_break_if_bad $? "sgml configuration file doesnot exist" || return

    # Check for open catalogs
    catalogs=`find /usr/share/sgml/ -name *catalog`
    tc_break_if_bad $? "No ordinary catalog files installed" 

    [ -e /etc/sgml/catalog ] && \
    cp -r /etc/sgml/catalog /etc/sgml/catalog.org
 
    # Take any two open catalogs
    set $catalogs
    catalog1=$1
    catalog2=$2
}

function tc_local_cleanup()
{
    # To clean up the catalog file 
    # if the delete operations would have failed
    [ -e /etc/sgml/sgml-new.cat ] && \
        rm -rf /etc/sgml/sgml-new.cat
    [ -e /etc/sgml/catalog.org ] && \
        mv /etc/sgml/catalog.org /etc/sgml/catalog
}
 
################################################################################
# Testcase functions
################################################################################

#
# test01        sgmlwhich 
#
function test01()
{
    tc_register     "sgmlwhich"
 
    sgmlwhich >$stdout 2>$stderr  
    tc_fail_if_bad $? "sgmlwhich failed" || return

    # Check if sgmlwhich returns the configuration file
    grep -wq /etc/sgml/sgml.conf $stdout 
    tc_pass_or_fail $? "sgmlwhich failed to display configuration file"
}

#
# test02	install-catalog --add
#
function test02()
{
    tc_register   "install-catalog tests"
   
    # Add a new centralized catalog 
    install-catalog --add /etc/sgml/sgml-new.cat $catalog1 >$stdout 2>$stderr 
    tc_fail_if_bad $? "install-catalog failed to add new catalog entry" || return

    # Check for the new entry in Root catalog
    grep -wq "CATALOG \"/etc/sgml/sgml-new.cat\"" /etc/sgml/catalog 
    tc_fail_if_bad $? "new catalog entry missing in /etc/sgml/catalog" || return

    # Check for the refernce to open catalog
    # in the package catalog file
    grep -wq "CATALOG \"$catalog1\"" /etc/sgml/sgml-new.cat 
    tc_pass_or_fail $? "catalog reference missing in /etc/sgml/sgml-new.cat"  

}

#
# test03     install-catalog --delegate
#
function test03()
{
    tc_register "install-catalog --delegate"

    # Add DELEGATE directive
    install-catalog -d --add /etc/sgml/sgml-new.cat $catalog2 >$stdout 2>$stderr 
    tc_fail_if_bad $? "install-catalog failed to add new catalog entry" || return

    grep -wq "DELEGATE \"$catalog2\"" /etc/sgml/sgml-new.cat 
    tc_pass_or_fail $? "catalog DELEGATE reference missing in /etc/sgml/sgml-new.cat"
}

#
# test04	install-catalog --remove
#
function test04()
{
    tc_register	 "install-catalog --remove"

    # Remove the reference to catalog1
    install-catalog --remove /etc/sgml/sgml-new.cat $catalog1 >$stdout 2>$stderr 
    tc_fail_if_bad $? "install-catalog failed to remove new catalog entry" || return
 
    grep -wq "CATALOG \"$catalog1\"" /etc/sgml/sgml-new.cat
    if [ $? -eq 0 ]; then
	tc_fail "install-catalog --remove failed to remove installed entry" || return 
    fi

    # Remove the refernce to catalog2
    install-catalog -d --remove /etc/sgml/sgml-new.cat $catalog2 >$stdout 2>$stderr 
    tc_fail_if_bad $? "install-catalog failed to remove $catalog2 entry" || return

    [ -e /etc/sgml/sgml-new.cat ]
    if [ $? -eq 0 ]; then
        tc_fail "install-catalog --remove failed to remove installed $catalog2 entry" || return
    fi

    tc_pass
}

# 
################################################################################
# main
################################################################################

TST_TOTAL=4

tc_setup

test01 &&
test02
test03
test04
