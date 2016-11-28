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
## File :        chkconfig.sh
##
## Description:  Test the "chkconfig" package
##
## Author:       Athira Rajeev <atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/chkconfig
source $LTPBIN/tc_utils.source

TEST_DIR=${LTPBIN%/shared}/chkconfig
CHKCONFIG_BINS=/sbin/chkconfig
ALTERNATIVES_BINS=/usr/sbin/alternatives
UPDATE_ALTERNATIVES_BINS=/usr/sbin/update-alternatives
INIT_DIR=/etc/rc.d/init.d
BIN_DIR=/usr/bin
LIB_DIR=/usr/lib
ALT_DIR=/var/lib/alternatives
TEST_SCRIPT1=${LTPBIN%/shared}/chkconfig/chkconfig_test_service1
TEST_SCRIPT2=${LTPBIN%/shared}/chkconfig/chkconfig_test_service2
OVERRIDE_SCRIPT=${LTPBIN%/shared}/chkconfig/chkconfig_test_override


########################################
# support functions
########################################
#
# tc_local_setup
#
function tc_local_setup()
{
  # To check whether you are a root user or not
  tc_root_or_break || exit
  tc_exec_or_break grep cp || exit
  cp $TEST_SCRIPT1 $TEST_SCRIPT2 $INIT_DIR >$stdout 2>$stderr
  tc_fail_if_bad $? "Could not copy dummy chkconfig test services \
  to $INIT_DIR" || return
  chmod +x $INIT_DIR/chkconfig_test_service*
}

#
# tc_local_cleanup
#
function tc_local_cleanup()
{
  local rc=0
  for ((i=0; i<7; i++))
  do
      if [ -L /etc/rc$i.d/*chkconfig_test_service1 ]
      then
             tc_info "Stale link left over from chkconfig" \
                     "Possibly chkconfig failed to delete chkconfig_test_service1"
             rc=1
             unlink /etc/rc$i.d/*chkconfig_test_service1
      fi

      if [ -L /etc/rc$i.d/*chkconfig_test_service2 ]
      then
               tc_info "Stale link left over from chkconfig" \
                     "Possibly chkconfig failed to delete chkconfig_test_service2"
               rc=1
               unlink /etc/rc$i.d/*chkconfig_test_service2
      fi
  done

  rm -f $INIT_DIR/chkconfig_test_service*
  rm -f /etc/chkconfig.d/chkconfig_test_service2
  if [ -e /var/lib/alternatives/alternatives_test ]
  then rm -f /var/lib/alternatives/alternatives_test
  fi
  rm -f $LIB_DIR/link_test
  rm -f $BIN_DIR/alternatives_test
  return $rc
}

#######################################
# the subtest functions
#######################################

#
# test01	Installation check
#
function test01()
{
  tc_register "Installation check"
  tc_executes $CHKCONFIG_BINS
  tc_fail_if_bad $? "chkconfig is not properly installed" || exit
  tc_executes $ALTERNATIVES_BINS
  tc_fail_if_bad $? "alternatives is not properly installed" || exit
  tc_executes $UPDATE_ALTERNATIVES_BINS
  tc_fail_if_bad $? "update-alternatives is not properly installed. "\
  "However update-alternatives is just a soft-link to alternatives "\
  || exit
  
  tc_pass
}

#
# test02	"chkconfig --add" adds a new service for management by chkconfig
#
function test02()
{

  tc_register "chkconfig --add"

  # Adding new service "chkconfig_test_service1"

  chkconfig --add chkconfig_test_service1 >$stdout 2>$stderr
  tc_fail_if_bad $? "chkconfig failed to add the service" || return

  # --list option displays information about
  # the service chkconfig knows about

  chkconfig --list chkconfig_test_service1 >$stdout 2>$stderr
  rc=$?
  [ $rc -eq 0 ]&&{
  cmp $stderr $TEST_DIR/stderr_exp && echo -n >$stderr
  }
  tc_pass_or_fail $? "chkconfig failed to list the service after it was added" \
  || return

  # Checks if symbolic link exists in /etc/rc[0-6].d
  # corresponding to the start and kill entries in base initscript

  for i in 3 5
  do
	if [ -L /etc/rc$i.d/S80chkconfig_test_service1 ]
        then
		diff -q /etc/rc$i.d/S80chkconfig_test_service1 \
		$INIT_DIR/chkconfig_test_service1
                tc_fail_if_bad $? "chkconfig add failure for start entry" \
		                   "could not find symbolic link in /etc/rc$i.d"|| return
        else
                tc_fail "chkconfig add failure for start entry" || return
        fi
  done

  for i in 0 1 2 4 6
  do
	if [ -L /etc/rc$i.d/K30chkconfig_test_service1 ]
        then
		diff -q /etc/rc$i.d/K30chkconfig_test_service1 \
		$INIT_DIR/chkconfig_test_service1
                tc_fail_if_bad $? "chkconfig add failure for stop entry" \
		|| return
        else
                tc_fail "chkconfig add failure for stop entry" || return
        fi
  done
  tc_pass

}

#
# test03	on flag starts the service in specified runlevels
#
function test03()
{
  tc_register "Checking to ON the test service"
  chkconfig --level 01246 chkconfig_test_service1 on >$stdout 2>$stderr
  tc_fail_if_bad $? "chkconfig ON failed" || return

  # checks if the service has start entry
  # in runlevels 0 1 2 4 6

  for i in 0 1 2 4 6
  do
       if [ ! -e /etc/rc$i.d/S80chkconfig_test_service1 \
           -o -e /etc/rc$i.d/K30chkconfig_test_service1 ]
       then
             tc_fail "Service is not ON in runlevel $i." || return
       fi
  done

  tc_pass
}

#
# test04        off flag stops the service in specified runlevels
#

function test04()
{
  tc_register "Checking to OFF the test service"

  chkconfig --level 01246 chkconfig_test_service1 off >$stdout 2 >$stderr
  tc_fail_if_bad $? "chkconfig OFF failed" || return

  # checks if the service has stop entry
  # in runlevels 0 1 2 4 6
  for i in 0 1 2 4 6
  do
        if [ ! -e /etc/rc$i.d/K30chkconfig_test_service1 \
             -o -e /etc/rc$i.d/S80chkconfig_test_service1 ]
        then
                 tc_fail "Service is not OFF in runlevel $i." || return
        fi
  done
  tc_pass

}

#
# test05	--override changes the configuration for service
#
function test05()
{
  tc_register "chkconfig --override"
  # Adding new service chkconfig_test_service2

  chkconfig --add chkconfig_test_service2 >$stdout 2>$stderr
  tc_fail_if_bad $? "chkconfig --add failed" || return

  cp $OVERRIDE_SCRIPT /etc/chkconfig.d/chkconfig_test_service2 >$stdout 2>$stderr
  tc_fail_if_bad $? "couldnot copy OVERRIDE_SCRIPT" || return

  chkconfig --list chkconfig_test_service2 >$stdout 2>$stderr
  rc=$?
  [ $rc -eq 0 ]&&{
  cmp $stderr $TEST_DIR/stderr_exp && echo -n >$stderr
  }
  tc_pass_or_fail $? "chkconfig could not list the service after it was added" || return

  # overrides with the configuration
  # in /etc/chkconfig.d/chkconfig_test_service2

  chkconfig --override chkconfig_test_service2 >$stdout 2>$stderr
  tc_fail_if_bad $? "chkconfig --override failed" || return

  # Checks if symbolic link exists in /etc/rc[0-6].d
  # corresponding to the start and kill entries in the override script

  [ -L /etc/rc3.d/S23chkconfig_test_service2 ] && \
  [ -L /etc/rc4.d/S23chkconfig_test_service2 ]
  tc_fail_if_bad $? "link not created as expected for start entry" || return

  for i in 0 1 2 5 6
  do
	if [ ! -L /etc/rc$i.d/K88chkconfig_test_service2 ]
        then
		tc_fail "link not created as expected for kill entry"
                return
        fi
  done

  chkconfig --del chkconfig_test_service2 >$stdout 2>$stderr
  tc_fail_if_bad $? "chkconfig failed to delete chkconfig_test_service2" \
  || return

  tc_pass
}

#
# test06	Service is removed from chkconfig management
#
function test06()
{
  tc_register "chkconfig --del"
  chkconfig --del chkconfig_test_service1 >$stdout 2>$stderr
  tc_fail_if_bad $? "chkconfig delete failure" || return

  ! (chkconfig --list| grep -wq chkconfig_test_service1)
  tc_fail_if_bad $? "chkconfig failed to remove the service" || return

  # checks if any symbolic link still exists
  # in /etc/rc[0-6].d
  for i in 0 1 2 3 4 5 6
  do
	if [ -L /etc/rc$i.d/*chkconfig_test_service1 ]
        then
		tc_fail "link still exists. chkconfig delete failure"
                return
        fi
  done

  tc_pass
}

#
# test07	alternatives command with --install, --set  and --remove
#
function test07()
{
  tc_register "Checking the alternatives --install, --set and --remove"

  cp $TEST_DIR/link_test $LIB_DIR >$stdout 2>$stderr
  tc_fail_if_bad $? "couldnot copy link_test to $LIB_DIR" || return
  chmod +x $LIB_DIR/link_test

  # adds an alternative link "/usr/lib/link_test" to alternatives_test

  alternatives --install $BIN_DIR/alternatives_test alternatives_test \
  $LIB_DIR/link_test 52 >$stdout 2>$stderr
  tc_fail_if_bad $? "chkconfig --install failed" || return

  # checks if the link for alternatives_test exists in $LIB_DIR \
  #                    and in $ALT_DIR

  [ -L $BIN_DIR/alternatives_test ] && [ -e $ALT_DIR/alternatives_test ]
  tc_fail_if_bad $? "expected link for alternatives_test doesnot exists" || return

  $BIN_DIR/alternatives_test | grep link_test >$stdout 2>$stderr
  tc_fail_if_bad $? "running alternative_test doesnt invoke link_test" || return

  alternatives --set alternatives_test $LIB_DIR/link_test >$stdout 2>$stderr
  tc_fail_if_bad $? "Setting of alternatives failed" || return
  grep -wq link_test /etc/alternatives/alternatives_test
  tc_fail_if_bad $? "Could not set alternatives to link_test" || return
  
  #Removes the alternative link "link_test" from alternatives_test

  alternatives --remove alternatives_test $LIB_DIR/link_test >$stdout 2>$stderr
  tc_fail_if_bad $? "chkconfig --remove failed" || return

  # checks if the path for alternative link still exists in $ALT_DIR/alternatives_test
  #  ! (grep -ws $LIB_DIR/link_test $ALT_DIR/alternatives_test)
  
  # --remove should remove the file alternatives_test file from /var/lib/alternatives
  ! (ls $ALT_DIR | grep alternatives_test)
  tc_fail_if_bad $? "Alternatives remove failure"

  tc_pass

}


########################################
#main
########################################

tc_setup

TST_TOTAL=7
test01
test02 || exit
test03 && test04
test05
test06
test07
