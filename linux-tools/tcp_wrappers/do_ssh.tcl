#!/usr/bin/expect -f
###########################################################################################
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
# File:           do_ssh.tcl
# 
# Description:    This expect script will ssh to user@localhost and use
#                 ~. (diconnect) as the password. The script fails with a 
#                 non zero value if ssh was not a success.
#
# Input:          argv0 - user name
#                 argv1 - password
#
# Output:         None.
#
# Exit:           This program exits with the follwing exit codes:
#                 0  - on success.
#                 1  - usage error, program requires username and password.
#                 2  - timeout, in case password was not send.
#                 3  - failed to spawn ssh command.
#
# Author:         Manoj Iyer manjo@mail.utexas.edu
#################################################################################################

set timeout 5 

if {$argc < 2} {
    puts "\nUsage: do_ssh.tcl \[user\] \[password\]\n"
    exit 1
}

set user [lindex $argv 0]
set password [lindex $argv 1]

if [ catch {spawn -noecho ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no $user} reason ] {
    send_user "failed to spawn passwd: $reason \n"
    exit 3
}

expect {
    timeout     { exit 2 }
    "assword:" { send "$password\r" }
    expect eof
}

exit 0
