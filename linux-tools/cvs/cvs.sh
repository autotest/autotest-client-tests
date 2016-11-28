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
#
# File :	cvs.sh
#
# Description:	Test CVS
#
# Author:	CSTL: Wang Tao <wangttao@cn.ibm.com>
#
################################################################################
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/cvs
source $LTPBIN/tc_utils.source
SDIR=${LTPBIN%/shared}/cvs

init_file=/etc/xinetd.d/cvs
xinetd_active="no"
T_PRJNAME="FIV"
T_CVSROOT_NAME="cvstestroot"
T_PRJROOT=""
T_REPROOT=""
T_CVSROOT=""
T_CVSWORK=""
T_CVSPORT=""

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_root_or_break || return
	tc_exist_or_break /etc/services || return
	tc_exec_or_break hostname cat grep sed || return

        # get SELinux status and disable it if enabled
        selinux_state=`getenforce`
        set_selinux=0
        if [ $selinux_state == "Enforcing" ]
        then
                setenforce 0
                set_selinux=1
        fi

	# save the current state of xinetd.
	tc_service_status xinetd && xinetd_active="yes"

	# backup files which are touched by the testcase.
	[ -f ~/.cvspass ] && cp -f ~/.cvspass $TCTMP/
	[ -f "$init_file" ] && cp -f $init_file $TCTMP/cvs &>/dev/null
	cp -f /etc/services $TCTMP
	touch ~/.cvspass

	# find open port
	tc_find_port 33300
	tc_break_if_bad $? "could not find open port" || return
	T_CVSPORT=$TC_PORT
	export CVS_CLIENT_PORT=$T_CVSPORT
	sed /^cvspserver/s/2401/${T_CVSPORT}/ /$TCTMP/services > /etc/services

	# create temporary directories for cvs testing
	T_REPROOT="${TCTMP}/${T_CVSROOT_NAME}"
	T_CVSWORK="${TCTMP}/mycvs"
	mkdir -p $T_REPROOT
	mkdir -p $T_CVSWORK

	# create a temp user for testing
	tc_add_user_or_break || return

        IP_ADDR=$(hostname -i)
	set $IP_ADDR
	ipaddr=$1
	T_CVSROOT="${ipaddr}:${T_CVSPORT}${T_REPROOT}"

	# create a sample project.
	T_PRJROOT="${TCTMP}/${T_PRJNAME}"
	mkdir -p ${T_PRJROOT}
	mkdir -p ${T_PRJROOT}/{dir1,dir2}
	echo "file1" > ${T_PRJROOT}/dir1/file1
	echo "file2" > ${T_PRJROOT}/dir2/file2

	tc_info "T_CVSPORT=$T_CVSPORT"
	netstat -lpen
}

#
# tc_local_cleanup		cleanup unique to this testcase
#
function tc_local_cleanup()
{
	# some debug output in case of failure:
	netstat -lpen

	# restore files.
	[ -f $TCTMP/.cvspass ] && cp -f $TCTMP/.cvspass ~/
	[ -f $TCTMP/cvs ] && cp -f $TCTMP/cvs $init_file 
	[ -f $TCTMP/services ] && cp $TCTMP/services /etc/

	# restore the xinetd service.
	[ "$xinetd_active" = "yes" ] && tc_service_restart_and_wait xinetd ||
		tc_service_stop_and_wait xinetd
        if [ $set_selinux -eq 1 ]
        then
                 setenforce 1
        fi
}

################################################################################
# the testcase functions
################################################################################

#
# installation check
#
function test_installation()
{
	tc_register "installation check"

	# cvs must be installed
        tc_exists $init_file /usr/bin/cvs 
        tc_pass_or_fail $? "cvs package not properly installed." || return
}

#
# create a CVS repository 
#
function test_createrep
{
	tc_register "create cvs repository"
	
	# enable cvs with xinetd.
	cat - >$init_file <<-EOF
	service cvspserver
	{
		socket_type     = stream
		protocol        = tcp
		wait            = no
		user            = $TC_TEMP_USER
		server          = /usr/bin/cvs
		server_args     = -f --allow-root=$T_REPROOT pserver
	}
	EOF


	# create the repository
	cvs -d $T_REPROOT init >$stdout 2>$stderr
	tc_fail_if_bad $? "failed to create the cvs repository." || return
	
	# create the passwd file for pserver authentication.
	cat - >$T_REPROOT/CVSROOT/passwd <<-EOF
	anonymous::$TC_TEMP_USER
	$TC_TEMP_USER::
	EOF

	# set ownership to the TC_TEMP_USER
	chown ${TC_TEMP_USER}:users -R $T_REPROOT 
	tc_fail_if_bad $? "unable to set the ownership for the repository." || return

	# restart xinetd 
	tc_info "(re)starting xinetd..."
	tc_service_restart_and_wait xinetd
	tc_wait_for_active_port 33300
	tc_pass_or_fail $? "xinetd not listening on 33300" || return
}

#
# import a sample project, using pserver authentication method.
#
function test_import
{
	tc_register "cvs import"

	( cd ${T_PRJROOT} ;
	  cvs -d :pserver:${TC_TEMP_USER}@$T_CVSROOT import -m "import the sample project." $T_PRJNAME fivtest initial &>$stdout )
	tc_pass_or_fail $? "failed to import the sample project." 
}


#
# checkout the sample project, using the anonymous account, wich is mapped to a system user account.
#
function test_checkout
{
	tc_register "cvs checkout"

	( cd $T_CVSWORK ;
	  cvs -d :pserver:anonymous@$T_CVSROOT checkout $T_PRJNAME &>$stdout )
	tc_fail_if_bad $? "failed to check out the sample project." || return

	# compare the checked out project with the original sources.
	diff ${T_CVSWORK}/${T_PRJNAME}/dir1/file1 ${T_PRJROOT}/dir1/file1 >$stdout 2>$stderr &&
	diff ${T_CVSWORK}/${T_PRJNAME}/dir2/file2 ${T_PRJROOT}/dir2/file2 >$stdout 2>$stderr
	tc_pass_or_fail $? "the checked out project is not sane."
}

#
# do some modifications to the project and commit. 
#
function test_commit
{
	tc_register "cvs commit"

	# Modify dir1/file1
	echo "secret: $$" >> ${T_CVSWORK}/${T_PRJNAME}/dir1/file1
	( cd $T_CVSWORK ;
	  cvs -d :pserver:${TC_TEMP_USER}@$T_CVSROOT commit -m "done modifications to dir1/file1" &>$stdout )
	tc_pass_or_fail $? "failed to commit changes to the sample project."
}

#
# update the project.
#
function test_update
{
	tc_register "cvs update"

	( cd $T_CVSWORK ;
	  cvs -d :pserver:${TC_TEMP_USER}@$T_CVSROOT update -dR &>$stdout )
	tc_fail_if_bad $? "failed to update the sample project." || return

	# check the result.
	
	diff ${T_CVSWORK}/${T_PRJNAME}/dir2/file2 ${T_PRJROOT}/dir2/file2 >$stdout 2>$stderr
	tc_fail_if_bad $? "project data corruption detected." || return

	grep -q "secret: $$" ${T_CVSWORK}/${T_PRJNAME}/dir1/file1 
	tc_pass_or_fail $? "project data no updated."
}

################################################################################
# main
################################################################################

TST_TOTAL=6

tc_setup

test_installation &&
test_createrep &&
test_import &&
test_checkout &&
test_commit &&
test_update
