#!/bin/bash
############################################################################################
## copyright 2003, 2016 IBM Corp                                                          ##
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
## File : polkit                                                              		  ##
##                                                                            		  ##
## Description: This testcase tests polkit package                            		  ##
##                                                                            		  ##
## Author:      Athira Rajeev <atrajeev@in.ibm.com>                           		  ##
##                                                                            		  ##
###########################################################################################
######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/polkit
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/polkit/test"
REQUIRED="pkaction pkcheck pkexec mount"

pushd $TESTDIR >& /dev/null
TESTS=`ls -I lt-* tests-polkit/`
TST_TOTAL=`echo $TESTS | wc -w`
TST_TOTAL=`expr $TST_TOTAL + 4`
popd >& /dev/null

function tc_local_setup()
{
    tc_exec_or_break $REQUIRED
    # Expect script for pkexec to
    # execute a script as another user
    cat >> $TCTMP/login.sh <<-EOF
#!/usr/bin/expect -f
set timeout 5
proc abort {} { exit 1 }
set USER1 [lindex \$argv 0]
set password [lindex \$argv 1]
set passwdpkexec [lindex \$argv 2]
spawn ssh \$USER1@localhost
expect "Are you sure you want to continue connecting (yes/no)?" { send "yes\r" }
# Look for passwod prompt
expect "*?assword:*"
# Send password aka $password
send -- "\$password\r"
expect "*?~*"
send -- "pkexec --user \$USER1 mount\r"
# Look for passwod prompt
expect "*?assword:*"
# Send password aka $password
send -- "\$passwdpkexec\r"
expect eof
EOF

    chmod +x $TCTMP/login.sh

    # Create example policy file
    cat >> $TCTMP/org.freedesktop.example.policy <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/software/polkit/policyconfig-1.dtd">
<policyconfig>

  <action id="org.archlinux.pkexec.mount">
    <message>Authentication is required to run the mount Program</message>
    <icon_name>gparted</icon_name>
    <defaults>
      <allow_any>auth_self</allow_any>
      <allow_inactive>auth_self</allow_inactive>
      <allow_active>auth_self</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/bin/mount</annotate>
    <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
  </action>

</policyconfig>
EOF

    # copy the example ploicy file to /usr/share/polkit-1/actions/
    cp $TCTMP/org.freedesktop.example.policy /usr/share/polkit-1/actions/
}
function tc_local_cleanup()
{
    # Remove the example policy from polkit-1/actions
    rm -rf /usr/share/polkit-1/actions/org.freedesktop.example.policy
}
function runtest()
{
    pushd $TESTDIR >$stdout 2>$stderr
    # Export the test variables
    export  MOCK_GROUP=data/etc/group
    export MOCK_PASSWD=data/etc/passwd
    export MOCK_NETGROUP=data/etc/netgroup
    export TESTS_ENVIRONMENT=mocklibc/bin/mocklibc
    export POLKIT_TEST_DATA=data

    # Execute the tests under polkit
    TESTS=`ls -I lt-* tests-polkit/`
    for test in $TESTS; do
        tc_register "Test $test"
        mocklibc/bin/mocklibc tests-polkit/$test >$stdout 2>$stderr
        tc_pass_or_fail $? "$test failed"
    done

    popd >$stdout 2>$stderr

    # copy the example ploicy file to /usr/share/polkit-1/actions/
    cp $TCTMP/org.freedesktop.example.policy /usr/share/polkit-1/actions/
    cp $TCTMP/org.freedesktop.example.policy .
    tc_register "pkaction for example policy"

    # Test pkaction displays the annotate for "mount"
    pkaction --action-id org.archlinux.pkexec.mount --verbose &>$stdout 2>$stderr
    tc_fail_if_bad $? "pkaction failed"

    grep -q "annotation:\ *org.freedesktop.policykit.exec.path -> /usr/bin/mount" $stdout
    tc_pass_or_fail $? "Failed to display annotation in pkaction output" || return

    # Test pkcheck to know if the process is authorized for
    # action "policykit.example.pkexec.run-mount"
    # Use the sshd process id for root
    tc_register "pkcheck of example policy"
    PS=`ps ax|grep "sshd:\ *root"`
    set $PS
    pkcheck --action-id org.archlinux.pkexec.mount --process $1 &>$stdout 2>$stderr
    tc_pass_or_fail $? "pkcheck failed"

    tc_register "pkexec - to execute a command as another user"
    # Create temporary user to test pkexec
    tc_add_user_or_break || return # sets TC_TEMP_USER
    USER1=$TC_TEMP_USER
    PASSWORD1=$TC_TEMP_PASSWD

    # Test if user is authorized to execute comand
    # as root by self authentication (auth_self ) as mentioned
    # in org.freedesktop.example.policy
    # pass username, user-password for login, user-password for pkexec authentication
    $TCTMP/login.sh $USER1 $PASSWORD1 $PASSWORD1 &>$stdout 2>$stderr
    grep -q "AUTHENTICATION COMPLETE" $stdout
    tc_pass_or_fail $? "pkexec failed to execute command as another user"

    tc_register "pkexec - should fail for unauthorized user"
    # Pass wrong password and verify it fails to authenticate
    $TCTMP/login.sh $USER1 $PASSWORD1 "wrong-password" &>$stdout 2>$stderr
    grep -q "AUTHENTICATION FAILED" $stdout
    tc_pass_or_fail $? "pkexec should fail for unauthorized user"
}

#
#MAIN
#
tc_setup
runtest
