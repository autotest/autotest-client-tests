#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
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
################################################################################
#
# File :	quota.sh
#
# Description:	test quota support.
#
# Author:	Robert Paulsen, rpaulsen@us.ibm.com
#
################################################################################

################################################################################
# source the standard utility functions
################################################################################

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

do_unmount="no"	# set to yes after successful mount. checked in tc_local_cleanup
initquota=`which quotaon`
initquotad=`which rpc.rquotad`
stop_quotad="no"

################################################################################
# utility functions
################################################################################

#
# tc_local_setup	tc_setup specific to this testcase
#
function tc_local_setup()
{
	tc_exec_or_break ls mkdir cp gunzip mount grep || return
	tc_root_or_break || return

	# busybox does not support usrquota mounts
	! tc_is_busybox mount
	tc_break_if_bad $? "busybox does not support usrquota mounts" || return

	# user to be quota-managed
	tc_add_user_or_break || return

	# mount volume for quota management
        mkdir $TCTMP/q_mnt
	cp ${LTPBIN%/shared}/quota/q_mount/q_mount.img.gz $TCTMP/
        gunzip $TCTMP/q_mount.img.gz
        if ! mount $TCTMP/q_mount.img $TCTMP/q_mnt \
		-o loop,usrquota 2>$stderr ; then
		tc_break_if_bad 1 "could not mount loopback"
		return 1
	fi
	do_unmount="yes"
	return 0
}

#
# tc_local_cleanup	cleanup specific to this testcase
#
function tc_local_cleanup()
{
	[ "$do_unmount" = "yes" ] && umount $TCTMP/q_mnt &>/dev/null
	[ "$stop_quotad" = "yes" ] && $initquotad --off &>/dev/null
	[ "$stop_quota" = "yes" ] && $initquota --off &>/dev/null
}

################################################################################
# the testcase functions
################################################################################

#
# test01	install check
#
function test01()
{
	tc_register	"install check"
	[ -x "$initquota" -a -x "$initquotad" ]
	tc_pass_or_fail $? "quota support not installed properly!"
}

#
# test02	initialize quota
#
function test02()
{
	tc_register	"initialize"

	quotacheck -avug >$stdout 2>/dev/null	# stderr expected
	tc_fail_if_bad $? "quotacheck failed" || return

	# quotad not needed
	# $initquotad status &>/dev/null
	# [ $? -ne 0 ] && stop_quotad="yes"
	# $initquotad start 2>$stderr >$stdout
	# tc_fail_if_bad $? "quotad support did not start" || return

	$initquota -p -a &>/dev/null
	[ $? -ne 0 ] && stop_quota="yes"
	$initquota -a 2>$stderr >$stdout
	tc_pass_or_fail $? "quota support did not start"
}

#
# test03	setquota
#
function test03()
{
	tc_register	"setquota"
	tc_info "setting quota for $TC_TEMP_USER"
	setquota $TC_TEMP_USER 39 39 39 39 $TCTMP/q_mnt 2>$stderr >$stdout
	tc_pass_or_fail $? "unexpected response"
}

#
# test04	reach quota
#
function test04()
{
	tc_register	"reach quota"

	# script for TC_TEMP_USER to use up space
	cat > $TCTMP/reachquota.sh <<-EOF
		#!$SHELL
		declare -i i=0
		while [ \$i -lt 60 ] ; do
			echo "use space" > $TCTMP/q_mnt/user/file.\$i
			let i+=1
		done
	EOF
	chmod a+x $TCTMP/reachquota.sh
	mkdir $TCTMP/q_mnt/user
	chown $TC_TEMP_USER $TCTMP/q_mnt/user

	# Have user execute the above script and thereby reach quota.
	# The "file limit reached" message is asynchronous and cannot be
	# redirected. TINFO message to console so user is not concerned.
	# stderr is expected so it is not fed to $stderr where it would
	# cause testcase failure.
	tc_info "It is normal to see a \"file limit reached\" message ..."
	echo "$TCTMP/reachquota.sh" | su $TC_TEMP_USER &> $stdout
        echo
	cat -n "$TCTMP/reachquota.sh" 
	echo 

#	grep "No space left on device" < $stdout >/dev/null
        grep " exceeded" < $stdout >/dev/null
	tc_pass_or_fail $? "Disk quote not reached but it should have been"
}

#
# test05	repquota
#
function test05()
{
	tc_register "repquota"

	repquota $TCTMP/q_mnt 2>$stderr >$stdout
	tc_fail_if_bad $? "bad response from repquota" || return

	local expected="u1836401  --      39      39      39             39    39    39"
	grep "^$TC_TEMP_USER.*39.*39.*39.*39.*39" < $stdout >/dev/null
	tc_pass_or_fail $? "incorrect output from repquota" \
		"expected to see this line in stdout ..."$'\n'"$expected"
}

################################################################################
# main
################################################################################

TST_TOTAL=5

# standard tc_setup
tc_setup

test01 && \
test02 && \
test03 && \
test04 && \
test05
