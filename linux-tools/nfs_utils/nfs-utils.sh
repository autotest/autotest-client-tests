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
## File :	nfs-utils.sh
##
## Description:	This is a template that can be used to develop shell script
##
## Author:	Robert Paulsen, rpaulsen@us.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################


export_me=""				# directory path set by tc_local_setup
mount_me=""				# directory path set by tc_local_setup
local_setup_ok="no"			# set to yes by tc_local_setup
restart_nfsserver="no"			# set to yes by tc_local_setup and test02
must_unexport="no"			# set to yes by test03
must_unmount="no"			# set to yes by test04
nfs_port=2049

################################################################################
# utility functions specific to this script
################################################################################

function shut_down_server()
{
	[ "$SERVER" ] || return 0	# nothing to shut down
	umount $mount_me &>/dev/null
	exportfs -u $SERVER:$export_me &>/dev/null
	cp /etc/exports /etc/exports.bak
	rm /etc/exports
	[ -f $TCTMP/exports ] && cp -a $TCTMP/exports /etc || cp /etc/exports.bak /etc/exports 
}

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_info "IN tc_local_setup"
	tc_root_or_break || return	# this tc must be run as root
	tc_exec_or_break sync mount umount mkdir grep diff || return
	service nfs status &>/dev/null &&
		restart_nfsserver="yes"

	[ -f /etc/exports ] &&  mv /etc/exports $TCTMP/exports
	touch /etc/exports

	# create exportable directory, file and mount point. avoiding /tmp due to LTP-BUG:97328, Redhat:981574
	export_me=/mount_test$$/export_me; mkdir -p $export_me
	mount_me=/mount_test$$/mount_me; mkdir -p $mount_me
	echo "This is test data" > $export_me/test_file
	local_setup_ok="yes"

	ALL_SERVERS="localhost $(hostname -s)"

#	The following is for future expansion. (UNTESTED!)
#	ALL_SERVERS="localhost"
#	tc_ipv6_info && ALL_SERVERS="$ALL_SERVERS \
#				$(tc_ipv6_normalize $TC_IPV6_host_ADDRS) \
#				$(tc_ipv6_normalize $TC_IPV6_global_ADDRS) \
#				$(tc_ipv6_normalize $TC_IPV6_link_ADDRS)"
}

#
# tc_local_cleanup
#
function tc_local_cleanup()
{
	for SERVER in $ALL_SERVERS ; do
		shut_down_server
	done

	[ $restart_nfsserver = "yes" ] &&
		tc_service_restart_and_wait nfs   >$stdout 2>$stderr
	[ -f $TCTMP/exports ] && cp -a $TCTMP/exports /etc/
	rm -rf /mount_test$$ 

	return 0
}

################################################################################
# the testcase functions
################################################################################

#
# test01	check that nfs is installed
#
function test01()
{
	tc_register	"installation check"
	tc_executes  exportfs nfsstat showmount
	tc_pass_or_fail $? "nfs-utils not installed properly"
}

#
# test02	start the nfs server
#
function test02()
{
	tc_register	"(re)start nfs server"

	tc_service_restart_and_wait nfs >$stdout 2>$stderr
	tc_wait_for_active_port $nfs_port >$stdout 2>$stderr
	tc_pass_or_fail $? "nfs server not listening to port $nfs_port" || return
	sleep 2
}

#
# test03	export a directory
#
function test03()
{
	tc_register	"export a directory"

	# save original exports file and set up our export
	[ -f /etc/exports ] && mv /etc/exports $TCTMP/
	echo "$export_me $SERVER(rw,no_root_squash,sync,subtree_check)" > /etc/exports

	# export
	must_unexport="yes"	# remember to unexport it later
	exportfs -a >$stdout 2>$stderr
	tc_pass_or_fail $? "unexpected response to exportfs -a"
	sync; sync; sync;
}

#
# test04	read from nfs-mounted filesystem
#
function test04()
{
	tc_register	"read from nfs-mounted filesystem"
	echo $TCTMP
	tc_is_fstype $TCTMP nfs && { tc_info "$TCNAME: skip since we are already nfs-mounted" ; return 0 ; }
	echo "$TCTMPmmmmm"
	must_unmount="yes"

	local command="mount -t nfs $SERVER:$export_me $mount_me"
	$command >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from \"$command\"" || return

	diff $export_me/test_file $mount_me/test_file >$stdout 2>$stderr
	tc_pass_or_fail $? "mismatch between exported and mounted file"
}

#
# test05	write to nfs-mounted filesystem
#
function test05()
{
	tc_register	"write to nfs-mounted filesystem"
	tc_is_fstype $TCTMP nfs && { tc_info "$TCNAME: skip since we are already nfs-mounted" ; return 0 ; }

	echo "more test data" > $mount_me/more_test_data
	tc_fail_if_bad $? "could not write to nfs-mounted filesystem" || return

	diff $mount_me/more_test_data $export_me/more_test_data >$stdout 2>$stderr
	tc_pass_or_fail $? "mismatch between exported and mounted file"
}

#
# test06	showmount
#
function test06()
{
	tc_register	"showmount"
	tc_is_fstype $TCTMP nfs && { tc_info "$TCNAME: skip since we are already nfs-mounted" ; return 0 ; }

	showmount $SERVER >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from showmount" || return

	local expected="$SERVER"
	grep -q $expected $stdout 2>$stderr
	tc_pass_or_fail $? "expected to see $expected in stdout"
}

#
# test07	nfsstat       See Bug #67587
#
function test07()
{
	tc_register	"nfsstat"

	nfsstat >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from nfsstat" || return

	grep -qi "client rpc" $stdout 2>$stderr
	tc_fail_if_bad $? "expected to see client nfs in stdout" || return

	# On nfs-mounted test system we skipped the mount above so the "nfs server"
	# line will not be in this output in which case we also skip this test.
	! tc_is_fstype $TCTMP nfs && {
		grep -qi "Server nfs" $stdout 2>$stderr
		tc_fail_if_bad $? "expected to see server nfs in stdout" || return
	}

	grep -qi "client rpc" $stdout 2>$stderr
	tc_fail_if_bad $? "expected to see client rpc in stdout" || return

	grep -qi "server rpc" $stdout 2>$stderr
	tc_pass_or_fail $? "expected to see server rpc in stdout"
}

#
# test08	minor stress test
#
function test08()
{
	tc_register	"minor stress test"
	tc_is_fstype $TCTMP nfs && { tc_info "$TCNAME: skip since we are already nfs-mounted" ; return 0 ; }
	
	declare -i local i=0
	declare -i local MAX=500
	declare -i local TOTAL
	let TOTAL=2*$MAX
	tc_info "$TCNAME: NFS client and server each create $MAX files"
	while [ $i -lt $MAX ] ; do

		# client create file
		rm -f $mount_me/client_file_$i
		cp $0 $mount_me/client_file_$i 2>$stderr
		echo "client file nbr $i" >> $mount_me/client_file_$i 2>$stderr
		tc_fail_if_bad $? "couldn't create client_file_$i" || return

		# server create file
		rm -f $export_me/server_file_$i
		cp $0 $export_me/server_file_$i 2>$stderr
		echo "server file nbr $i" >> $export_me/server_file_$i 2>$stderr
		tc_fail_if_bad $? "couldn't create server_file_$i" || return
		let ++i
	done

	# an attempt to defeat caching by client or server
	rm -rf $TCTMP/server_files $TCTMP/client_files
	mkdir $TCTMP/server_files; cp $export_me/* $TCTMP/server_files/
	mkdir $TCTMP/client_files; cp $mount_me/* $TCTMP/client_files/

	# now compare the files
	tc_info "$TCNAME: Compare all $TOTAL files"
	diff $TCTMP/server_files $TCTMP/client_files >$stdout 2>$stderr
	tc_pass_or_fail $? "mismatch between exported and mounted file"
}

################################################################################
# main
################################################################################


tc_setup

tc_run_me_only_once

TST_TOTAL=1
test01 &&
for SERVER in $ALL_SERVERS ; do 
	((TST_TOTAL+=7))
	tc_info "testing with $SERVER"
	test02 &&
	test03 &&
	test04 &&
	test05 &&
	test06 &&
	test07 &&
	test08
	shut_down_server
done
