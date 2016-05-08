#!/bin/sh
############################################################################################
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
## File :        yum-metadata-parser
##
## Description:  Test the tools of yum-metadata-parser package.
##
## Author:      Athira Rajeev <atrajeev.linux.vnet.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

FIVDIR="${LTPBIN%/shared}/yum_metadata_parser"
REQUIRED="yum"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
	# To make sure we clean all the previous rpmdb errors
        yum clean all >$stdout 2>$stderr
	REPOLINK="http://`grep test1.au.example.com /etc/hosts| awk '{print $2}'`/yumtestrepo/testrepo"
	LOCALREPOLINK="file:///srv/testrepo/repo/localrepo"
	YUMREPO="/etc/yum.repos.d/testrepo.repo"
	UPDATESREPO="http://`grep test1.au.example.com /etc/hosts| awk '{print $2}'`/yumtestrepo/testupdates"	
 
	set `find /usr/lib* -name sqlitecachec.py\*`
	[ -f $1 ] &&  tc_break_if_bad $? "yum-metadata-parser not installed properly"
	tc_exec_or_break $REQUIRED
   
	cat > $YUMREPO <<-EOF
	[testrepo]
	name=This is test repo
	baseurl=$REPOLINK
	enabled=1
	gpgcheck=0

	[testupdates]
	name=This is test updates repo
	baseurl=$UPDATESREPO
	enabled=1
	gpgcheck=0

	[localrepo]
	name=This is local test repo
	baseurl=$LOCALREPOLINK
	enabled=1
	gpgcheck=0
	EOF

	# Create a local test repo
	mkdir -p /srv/testrepo/repo/localrepo
	cp $FIVDIR/yum1_rpm-1.0-1.noarch.rpm /srv/testrepo/repo/localrepo
	createrepo /srv/testrepo/repo/localrepo >$stdout 2>$stderr

	# Backup yum.conf
	cp /etc/yum.conf /etc/yum.conf.backup
}

function tc_local_cleanup()
{
	yum clean all >$stdout 2>$stderr
	tc_fail_if_bad $? "yum clean failed in clenaup" || return

	#remove requires_testlib
	yum -y remove requires_testlib provides_testlib >$stdout 2>$stderr
	
	mv /etc/yum.conf.backup /etc/yum.conf
	rm -rf /srv/testrepo/repo/localrepo

	# Remove the testrepo under /etc/yum.repos.d
	rm -rf $YUMREPO

	# Clear out the yum cache
	rm -rf $dir
}

function run_test()
{
	tc_register "Testing yum search works with new repo"
	tc_info "yum search yum1_rpm from new repo"
	yum search yum1_rpm >$stdout 2>$stderr
	tc_fail_if_bad $? "yum search failed" || return

	grep -iq "Matched: yum1_rpm" $stdout
	tc_pass_or_fail $? "yum search failed for yum1_rpm"
	
	# Find the cache dir for localrepo
	dir=`find /var/cache/yum -name localrepo`

	tc_register "Check if yum detects the corrupted metadata and fetches on next run"
	pushd $dir >$stdout 2>$stderr
	if [ -e primary.xml.gz ]; then
		gunzip primary.xml.gz
		sed -i 's:rel="1":rel="10":g' primary.xml
		gzip primary.xml
	else
		sed -i 's:type="sha256">:type="sha256">122345346:' repomd.xml
	fi
	popd >$stdout 2>$stderr

	# Try yum search yum1_rpm and it should fail
	#yum install should fail for corrupted metadata
	yum -y install yum1_rpm >$stdout 2>$stderr
	grep -iq "Metadata file does not match" $stderr
	if [ $? -eq 0 ]; then
		cat /dev/null > $stderr
		tc_pass
	else
		tc_fail "yum failed to throw error message for corrupted metadata"
	fi

	tc_register "Rerunning yum after corrupted metadata should succeed"
	# Again running yum will succeed as yum picks the correct metadata from the repo
	#Again running yum install should work
	yum -y install yum1_rpm >$stdout 2>$stderr
	tc_pass_or_fail $? "failed to install yum1_rpm"

	tc_register "check if primary*.sqlite database is created"
	ls -l $dir | grep -iq primary.*sqlite
	tc_pass_or_fail $? "primary*.sqlite database not created"
		
	tc_register "Check if yum picks the updated metadata from repo"

	# Modify the yum.conf
	echo "metadata_expire=1m" >> /etc/yum.conf

	#Running yum clean all
	yum clean all >$stdout 2>$stderr
	tc_fail_if_bad $? "yum clean all failed" || return

	#Remove a package from localrepo
	#yum remove yum1_rpm
	yum -y remove yum1_rpm >$stdout 2>$stderr
	grep -iq  Removed: $stdout
	tc_fail_if_bad $? "Failed to remove yum1_rpm" || return
	
	# Modify the repo to remove the package
	rm -rf /srv/testrepo/repo/localrepo/yum1_rpm-1.0-1.noarch.rpm

	# Update the repo
	createrepo --update /srv/testrepo/repo/localrepo >$stdout 2>$stderr

	tc_info "sleeping 1m to update metadata"
	sleep 60
	
	# Now try yum search and verify it lists the package
	#yum search yum1_rpm shouldnot list yum1_rpm
	yum search yum1_rpm >$stdout 2>$stderr
	if [ `grep -vc "Warning: No matches found for: yum1_rpm" $stderr` -eq 0 ];then cat /dev/null > $stderr; fi 
	grep -iq "No Matches found" $stdout
	tc_pass_or_fail $? "Yum failed to pick data from updated repository"

	tc_register "Check if yum picks updated package which provides the package under Requires:"
	# Check if yum picks updated package which provides the 
	# package under Requires:
	#Installing requires_testlib without dependencies
	yum -y install --disablerepo=testupdates requires_testlib >$stdout 2>$stderr
	grep -iq Installed: $stdout
	tc_fail_if_bad $? "yum failed to install requires_testlib package" 

	#update requires_testlib and see if it picks the updated provides_testlib as well
	yum -y update requires_testlib >$stdout 2>$stderr
	grep -iq "Dependency Updated" $stdout
	tc_pass_or_fail $? "yum failed to pick the dependency package"
}

################################################################################
# MAIN
################################################################################
TST_TOTAL=6
tc_setup
run_test
