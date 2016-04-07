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
## File :        locate.sh
##
## Description:  Test the updatedb and locate commands
##
## Author:       Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

updatedb_cron=/etc/cron.daily/mlocate
locate=/usr/bin/locate
updatedb=/usr/bin/updatedb
config=/etc/updatedb.conf
LOCATE_DB=/var/lib/mlocate/mlocate.db
locate_this=""                  # set by tc_local_setup
REQUIRES="pkill ps grep"

################################################################################
# utility functions specific to this script
################################################################################
function tc_local_setup()
{
	tc_exec_or_break $REQUIRES || return
        tc_root_or_break || return
        tc_add_user_or_break || return
        locate_this=$TC_TEMP_HOME/locate_this_$$      # file to locate
        touch $locate_this

	# temporarily stop cron process
	tc_service_stop_and_wait crond
	cron_stopped="yes"
	return 0
}

function tc_local_cleanup()
{
        [ "$cron_stopped" = "yes" ] && tc_service_start_and_wait crond
}

#
# kill any existing updatedb process
#
function kill_updatedb()
{
        n=60	# Wait up to 10 minutes
        while ps -ef | grep [u]pdatedb ; do
		pkill -f $updatedb_cron
		pkill -f $updatedb
		tc_info "waiting for $updatedb to finish ($n)"
                sleep 10
                ((--n))
        done
        ((n>0)) && rm -f $LOCATE_DB	# remove old database
}
# be sure updatedb created the database
#
function wait_for_updatedb()
{
        n=10
        while ! [ -f "$LOCATE_DB" ] ; do
                tc_info "waiting for file $LOCATE_DB ($n)"
                sleep 1
                ((--n)) || break
        done
        ((n>0))
}

################################################################################
# the testcase functions
################################################################################

#
# test01        check that locate is installed
#
function test01()
{
        tc_register     "installation check"
        tc_executes $updatedb_cron $locate $updatedb && tc_exists $config
        tc_fail_if_bad $? "locate not installed properly" || return
}

#
# test02        run updatedb via direct invocation of cron script
#
function test02()
{
        tc_register     "updatedb"

        kill_updatedb
        tc_break_if_bad $? "existing $updatedb process did not end" || return

        tc_info "invoking \"$updatedb_cron\" ... "
        $updatedb_cron >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response from $updatedb_cron" || return

        tc_wait_for_file $LOCATE_DB
        tc_pass_or_fail $? "$updatedb did not create $LOCATE_DB file"
}

#
# test03        locate a file
#
function test03()
{
        tc_register     "locate a file"

        local locate_me=${locate_this##*/}
        $locate $locate_me >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response from \"$locate $locate_me\"" ||
                return

        grep -q "$locate_me" $stdout 2>$stderr
        tc_pass_or_fail $? "file \"$locate_me\" not located"
}

################################################################################
# main
################################################################################

TST_TOTAL=3

tc_setup

test01 &&
test02 &&
test03
