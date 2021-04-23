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
#### File : policycoreutils.sh                                                  ##
##
#### Description: This testcase tests the policycoreutils package               ##
##
#### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################
### source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

function tc_local_setup()
{
      tc_check_package policycoreutils
  tc_fail_if_bad $? "policycoreutils not installed properly"
}

function run_test()
{
grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
if [ $? -ne 0 ];then  # Start of OS check

  tc_register "loadpolicy"
  load_policy >$stdout 2>$stderr
  tc_pass_or_fail $? "loadpolicy failed"

  tc_register "secon"
  secon --parent >$stdout 2>$stderr
  tc_pass_or_fail $? "secon failed"

  tc_register "setsebool"
  bool_name=`getsebool -a | sed -n 1p | awk '{print $1}'`
  bool_status=`getsebool -a | sed -n 1p | awk '{print $3}'`
  if [ "$bool_status" == "off" ] 
     then
       setsebool $bool_name=1 >$stdout 2>$stderr
       tc_fail_if_bad $? "Turning on bool value failed"
       setsebool $bool_name=0 >$stdout 2>$stderr
       tc_pass_or_fail $? "Turning off bool value failed"
     else
       setsebool $bool_name=0 >$stdout 2>$stderr
       tc_fail_if_bad $? "Turning off bool value failed"
       setsebool $bool_name=1 >$stdout 2>$stderr
       tc_pass_or_fail $? "Turning on bool value failed"
  fi

fi

  tc_register "restorecond"
  restorecond -f /etc/selinux/restorecond.conf >$stdout 2>$stderr
  tc_pass_or_fail $? "restorecond failed"

  tc_register "semodule -l"
  semodule -l >$stdout 2>$stderr
  tc_pass_or_fail $? "Semodule -l failed" 

  tc_register "semodule: list"
  test_module=`semodule -l | sed -n 1p | awk '{print $1}'`
  tc_pass_or_fail $? "listing of modules failed"
  
  tc_register "semodule:disable"
  semodule -d $test_module >$stdout 2>$stderr
  tc_fail_if_bad $? "Disable failed"
  semodule -l | grep $test_module | awk '{print $3}' >$stdout 2>$stderr
  grep -q Disabled $stdout
  tc_pass_or_fail $? "Module not disabled"

  tc_register "semodule: enable"
  semodule -e $test_module >$stdout 2>$stderr
  tc_fail_if_bad $? "Enable failed"
  semodule -l | grep $test_module >$stdout 2>$stderr
  grep -qv Disabled $stdout
  tc_pass_or_fail $? "Module not enabled"
 
  tc_register "sestatus"
  sestatus >$stdout 2>$stderr
  tc_pass_or_fail $? "sestatus failed"

}

grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
if [ $? -ne 0 ];then  # Start of OS check
	TST_TOTAL=9
else
	TST_TOTAL=6
fi
tc_setup
run_test
