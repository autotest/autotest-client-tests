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
############################################################################################
#
# File :        fusetest.sh
#
# Description:  Test the "fuse" package
#
#
# Author:       Athira Rajeev <atrajeev@in.ibm.com>
############################################################################################
# source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/fuse
source $LTPBIN/tc_utils.source

TEST_DIR=${LTPBIN%/shared}/fuse
USER_PROGRAM=$TEST_DIR/user_program
FUSE_BIN=`which fusermount`
MOUNT_BIN=`which mount.fuse`
mountpoint1=/tmp/fuse1
mountpoint2=/tmp/fuse2
mountpoint3=/tmp/fuse3

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
  tc_exec_or_break ls cat grep mount mkdir || exit
  grep -wq fuse /proc/filesystems; RC=$?
  if [ $RC -ne 0 ]; then
 	modprobe fuse >$stdout 2>$stderr
	RC=$?
  fi        
  tc_fail_if_bad $RC "fuse module doesnt exist" || return
  [ -e /etc/fuse.conf ] && cp /etc/fuse.conf /etc/fuse.conf.bak
  
  # Add fuse group if not exists
  grep -iq fuse /etc/group
  if [ $? -eq 1 ]; then
  	tc_add_group_or_break fuse || return
  fi
}

#
# tc_local_cleanup
#
function tc_local_cleanup()
{
  mount | grep -wq $mountpoint1
  [ $? -eq 0 ] && umount $mountpoint1
  mount | grep -wq $mountpoint2
  [ $? -eq 0 ] && umount $mountpoint2
  mount | grep -wq $mountpoint3
  [ $? -eq 0 ] && umount $mountpoint3
  rm -rf $mountpoint1
  rm -rf $mountpoint2
  rm -rf $mountpoint3
  [ -e /etc/fuse.conf.bak ] && mv /etc/fuse.conf.bak /etc/fuse.conf
}
#######################################
# the subtest functions
#######################################

#
# test01        Installation check
#
function test01()
{
  tc_register "Installation check"
  tc_executes $FUSE_BIN $MOUNT_BIN
  tc_pass_or_fail $? "fuse is not properly installed" || exit
}

#
# test02	mount at mounpoint using userspace program
#
function test02()
{
  tc_register "mount fuse filesystem"
  # create user
  tc_add_user_or_break
  USER1=$TC_TEMP_USER

  # adding user to fuse group
  gpasswd -a $USER1 fuse >$stdout 2>$stderr
  tc_fail_if_bad $? "failed to add user to fuse group" || return

  # Creating mountpoint 
  su - $USER1 -c "mkdir $mountpoint1"

  # Mount sample filesystem as user
  su - $USER1 -c "$USER_PROGRAM $mountpoint1"
  tc_fail_if_bad $? "unable to mount using userspace program" || return
 
  # check for filesystem using mount command
  tc_info "checking fuse filesystem using mount"
  mount | grep -wq "fuse.user_program"
  tc_fail_if_bad $? "mount check for fuse filesystem failed" || return 

  # Check ls -l as user to see file hello
  tc_info "checking ls -l" 
  su - $USER1 -c "ls -l $mountpoint1 | grep -wq hello"
  tc_fail_if_bad $? "ls -l failed" || return
  
  # Checking cat command
  tc_info "checking cat for file hello"
  su - $USER1 -c "cat $mountpoint1/hello | grep -wq user_filesystem"
  tc_pass_or_fail $? "cat failed to print contents of the file"

}

#
# test03	Check if other user can acces the files
#
function test03()
{
  tc_register "other user access"

  # create another user
  tc_add_user_or_break
  USER2=$TC_TEMP_USER
 
  # check if another user can access fuse filesystem
  su - $USER2 -c "ls -l $mountpoint1 >$stdout 2>$stderr"; RC=$?
  if [ $RC -eq 0 ]; then
	  tc_fail "other user should not be allowed to access files" || return
  fi

  tc_pass
}

#
# test04	checking "allow_other"
#
function test04()
{
  tc_register "check mount.fuse using allow_other and fsname option"
  #adding allow_other as option allows all users to access fuse filesystem
  # which is created by another user

  #mount fuse filesystem at another mount point
  su - $USER1 -c "mkdir $mountpoint2"

  # Add "user_allow_other" to fuse.conf
  echo "user_allow_other" >> /etc/fuse.conf

  # mount using allow_other option
  su - $USER1 -c "$MOUNT_BIN $USER_PROGRAM $mountpoint2 -o allow_other -o fsname=fuse.virtual"
  tc_fail_if_bad $? "mount.fuse failed" || return
  
  mount | grep -wq fuse.virtual
  tc_fail_if_bad $? "failed to set filesystem name using fsname"

  # check if root user can access the filesystem
  ls -l $mountpoint2 | grep -wq hello
  tc_fail_if_bad $? "unable to mount using allow_other option for root" || return

  # check if user2 can access the filesystem
  su - $USER2 -c "ls -l $mountpoint2 | grep -wq hello"
  tc_pass_or_fail $? "unable to mount using allow_other option for USER2" || return

}
#
# test05        Try mounting to a sticky directory
#
function test05()
{
  tc_register "mount to sticky directory"
  # create directory with sticky bit
  mkdir $mountpoint3
  chmod +t $mountpoint3 

  #mount at mountpoint which is sticky directory
  su - $USER1 -c "$USER_PROGRAM $mountpoint3 >$stdout 2>$stderr"; RC=$?
  if [ $RC -eq 0 ]; then
  	tc_fail "user should not be able to mount at sticky directory" || return
  fi

  tc_pass
}

#
# test06       Mounting at non-empty directory 
#
function test06()
{
  tc_register "mountpoint at nonemty directory"

  #Trying to mount at already used mountpoint again
  su - $USER1 -c "$USER_PROGRAM $mountpoint >$stdout 2>$stderr"; RC=$?
  if [ $RC -eq 0 ]; then
        tc_fail "user should not be able to mount at nonempty directory" || return
  fi

  tc_pass
}

#
# test07       umount
#
function test07()
{
  tc_register "umount using fusermount"
  $FUSE_BIN -u $mountpoint1
  tc_pass_or_fail $? "Unable to umount using fusermount" || return
}

########################################
#main
########################################

tc_setup

TST_TOTAL=7
test01
test02 && test03
test04
test05
test06
test07
