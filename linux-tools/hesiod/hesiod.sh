#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab:
################################################################################
## ##
## (C) Copyright IBM Corp. 2012                                               ##
## ##
## This program is free software;  you can redistribute it and#or modify      ##
## it under the terms of the GNU General Public License as published by       ##
## the Free Software Foundation; either version 2 of the License, or          ##
## (at your option) any later version.                                        ##
## ##
## This program is distributed in the hope that it will be useful, but        ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   ##
## for more details.                                                          ##
## ##
## You should have received a copy of the GNU General Public License          ##
## along with this program;  if not, write to the Free Software               ##
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA    ##
## ##
################################################################################
#
# File :    hesiod.sh
#
# Description:    Tests for hesiod package.
#
# Author:    Gowri Shankar <gowrishankar.m@in.ibm.com>
#
# History:    21 Nov 2012 - Initial version - Gowri Shankar
################################################################################
# source the utility functions
################################################################################
#######cd $(dirname $0)
#LTPBIN="${LTPBIN%/shared}/hesiod"
HESIOD="${LTPBIN%/shared}/hesiod/"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
required="echo getent grep mv nscd"
restore_hesiod_conf="no"
restore_nscd_conf="no"
restore_nscd_daemon="no"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    # check installation and environment
    tc_root_or_break || return
    tc_exec_or_break $required || return

        # backup the installation
        tc_service_status nscd &>/dev/null
        if [ $? -eq 0 ]; then
                tc_service_stop_and_wait nscd &>/dev/null
                restore_nscd_daemon="yes"
        fi

        if [ -e "/etc/nscd.conf" ]; then
                mv /etc/nscd.conf /etc/nscd.conf.org
                restore_nscd_conf="yes"
        fi

        if [ -e "/etc/hesiod.conf" ]; then
                mv /etc/hesiod.conf /etc/hesiod.conf.org
                restore_hesiod_conf="yes"
        fi
}

function tc_local_cleanup()
{
        if [ "$restore_hesiod_conf" = "yes" ]; then
                 yes | mv -f /etc/hesiod.conf.org /etc/hesiod.conf &>/dev/null
        fi

        tc_service_stop_and_wait nscd &>/dev/null
        if [ "$restore_nscd_conf" = "yes" ]; then
               yes | mv -f /etc/nscd.conf.org /etc/nscd.conf &>/dev/null
        fi

        if [ "$restore_nscd_daemon" = "yes" ]; then
                tc_service_start_and_wait nscd &>/dev/null
        fi
        # restoring the original configuration
        tc_service_stop_and_wait named &>/dev/null
        yes | mv -f /etc/named.conf.org /etc/named.conf &>/dev/null;chown root:named /etc/named.conf
        yes | mv -f /etc/resolv.conf.org /etc/resolv.conf &>/dev/null
        yes | mv -f /etc/nsswitch.conf.org /etc/nsswitch.conf &>/dev/null
        rm -rf /var/named/hesiod.data >/dev/null
}

#
# test A
#  check installed library libhesiod.so
#
function test_libhesiod()
{
    tc_register "check libhesiod.so"
        $HESIOD/hestest $HESIOD/hestest.conf 1>$stdout 2>$stderr
        tc_pass_or_fail $? "some of the libhesiod tests fail"
}

#
# test B
#  check NSS integration with hesiod
#
function test_nss_lookup()
{
    tc_register "checking NSS integration"
        # create test configuration for nscd
        # we disable nscd cache to avoid accidental cache look up,
        # though we actually restart nscd in tests.
        echo "enable-cache           passwd  no"  > $TCTMP/nscd.conf
        echo "positive-time-to-live  passwd  600" >> $TCTMP/nscd.conf
        echo "negative-time-to-live  passwd  20"  >> $TCTMP/nscd.conf
        echo "check-files            passwd  no"  >> $TCTMP/nscd.conf
        echo "persistent             passwd  yes" >> $TCTMP/nscd.conf
        echo "check-files            passwd  no"  >> $TCTMP/nscd.conf
        echo "check-files            passwd  no"  >> $TCTMP/nscd.conf
        cp $TCTMP/nscd.conf /etc/nscd.conf
     
        # start nscd to lookup passwd with new configuration
        tc_service_start_and_wait nscd 1>$stdout 2>$stderr
        tc_fail_if_bad $? "nscd fails to start" || return
        getent passwd root 1>$stdout 2>$stderr
        tc_pass_or_fail $? "password lookup failed after nscd start"
}

#
# test C
#  verify the hesiod configuration data
#
function test_hesiod_config()
{
    tc_register "checking hesiod configuration"
        local hes_lookup=""
        local grep_lookup=""
    
       # backup of configuration file
       [ -e /etc/named.conf ] && cp /etc/named.conf /etc/named.conf.org
       [ -e /etc/resolv.conf ] && cp /etc/resolv.conf /etc/resolv.conf.org
       [ -e /etc/nsswitch.conf ] && cp /etc/nsswitch.conf /etc/nsswitch.conf.org
       [ -e /etc/hesiod.conf ] && mv /etc/hesiod.conf /etc/hesiod.conf.org
       [ -e /var/named/hesiod.data ] && rm -f /var/named/hesiod.data >/dev/null

  	# create named.conf for hesiod domain
        echo "zone "ns.your.domain" {" >> /etc/named.conf
        echo "     type master;"       >> /etc/named.conf
        echo "     file \"hesiod.data\";" >> /etc/named.conf
        echo "};"                      >> /etc/named.conf

       # create hesiod data file
       cp $HESIOD/hesiod.data /var/named/hesiod.data
       chown root:named /var/named/hesiod.data
       
      # create test configuration for hesiod
        echo "lhs=.ns"          >  $TCTMP/hesiod.conf
        echo "rhs=.your.domain" >> $TCTMP/hesiod.conf
        echo "classes=HS,IN"    >> $TCTMP/hesiod.conf
        cp $TCTMP/hesiod.conf /etc/hesiod.conf

      # edit the nsswitch file for hesiod configuration
      sed -i '/\(^passwd:\).*/ s//\1     hesiod files/' /etc/nsswitch.conf
     
      # edit the resolve file for local domain
      to_search=`hostname | awk -F. '{print $1}'`;sed -i '/\(^nameserver\).*/ s//\1 127.0.0.1/' /etc/resolv.conf;sed -i "/\(^search\).*/ s//\1 $to_search/" /etc/resolv.conf

      # restart the named.service with all changes
      tc_service_restart_and_wait named &>/dev/null;sleep 10
      tc_break_if_bad $? "failed to start the name service with hesiod configuration" || return
 
      # hesiod test for group
      hesinfo root group 1>$stdout 2>$stderr
      tc_fail_if_bad $? "hesid failed to group lookup" || return
      
      # hesiod test for passwod
      hesinfo root passwd 1>$stdout 2>$stderr
      tc_fail_if_bad $? "hesid fails to password lookup" || return
      hes_lookup=$(cat $stdout)
      grep_lookup=$(grep -m 1 "root" /etc/passwd)
      if [ "$hes_lookup" == "$grep_lookup" ];then
            tc_pass "password lookup using hesiod is passed"
      else
            tc_fail "password lookup using hesiod failed" 
      fi
}

################################################################################
# main
################################################################################
TST_TOTAL=3
tc_setup

test_libhesiod
test_nss_lookup
test_hesiod_config
