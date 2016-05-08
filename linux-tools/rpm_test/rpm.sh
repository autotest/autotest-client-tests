#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab:
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
# File :       rpm.sh
#
# Description:  This testcase tests 5 commands in the rpm package.
#		rpm gendiff rpm2cpio rpmquery rpmverify
#              
# 
# Author:       Andrew Pham, apham@us.ibm.com
#
################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

PKG_NAME=tst_rpm
FILE_NAME=hello.sh
INSTALL_DIR=for_my_test_$$
#PKGS_DIR=/usr/src/packages
PKGS_DIR=/root/rpmbuild
SPECS_DIR=$PKGS_DIR/SPECS
SOURCES_DIR=$PKGS_DIR/SOURCES
MESSAGE="Hello Sailor!"
REQUIRED="mkdir grep rpm2cpio"
ISPPCNF=0

#INSTALL_CHECK="rpm rcrpmconfigcheck gendiff rpm2cpio rpmbuild rpmdb rpme 
#               rpmgraph rpmi rpmqpack rpmquery rpmsign rpmu rpmverify"
#
#//////// COMMANDS COMMENTED ABOVE ARE NOT PART OF RHEL6 ////////// #

tc_get_os_arch
[ $TC_OS_ARCH = ppcnf ]&&  ISPPCNF=1

if [ $ISPPCNF -eq 1 ]; then
	INSTALL_CHECK="rpm rpm2cpio rpmdb rpmquery rpmverify"
	THE_RPM=tst_rpm-1.0-1.noarch
else
	INSTALL_CHECK="rpm gendiff rpm2cpio rpmbuild rpmdb rpmquery rpmverify"
fi



#
# local setup
#
function tc_local_setup()
{
	mkdir -p $SPECS_DIR
	mkdir -p $SOURCES_DIR
}

#
# local cleanup
#
function tc_local_cleanup()
{
	rpm -e $PKG_NAME >&/dev/null
	rm -rf /$INSTALL_DIR
	rm -rf $PKGS_DIR/BUILDROOT/tst_rpm*

	# temp to collect data when run via ABAT
	[ -f /etc/autobench.conf ] || return
	[ "$THE_RPM" ] || return
	source /etc/autobench.conf
	cp $THE_RPM $AUTODIR/logs/
	cp $SPECS_DIR/$PKG_NAME.spec $AUTODIR/logs/
}

################################################################################
# the testcase functions
################################################################################

#
# test01    Installation check
#
function test01()
{
	tc_register "Installation check"
	tc_executes $INSTALL_CHECK
	tc_pass_or_fail $? "rpm not installed properly"
}

#
# test02    rpmbuild -ba
#
function test02()
{
	tc_register "rpmbuild -ba"	
	# create a file in the SOURCES directory
	mkdir -p $SOURCES_DIR/$PKG_NAME-1.0
	cat > $SOURCES_DIR/$PKG_NAME-1.0/$FILE_NAME <<-EOF
	#!/bin/bash
	echo $MESSAGE
	EOF
        ( cd $SOURCES_DIR ; tar -zcf $PKG_NAME-1.0.tgz $PKG_NAME-1.0 ; )
	# Create a spec file
	mkdir -p $TCTMP/build_here
	cat > $SPECS_DIR/$PKG_NAME.spec <<-EOF
	%define INSTALL_DIR $INSTALL_DIR
	%define FILE_NAME $FILE_NAME
	%define PKG_NAME $PKG_NAME
	%define TCTMP $TCTMP
	Summary: Dummy package used to test rpm package
	Name: %{PKG_NAME}
	Version: 1.0
	Release: 1
	License: GPL
	Group: LillB test case
	Source: %{PKG_NAME}-1.0.tgz
	BuildRoot: %{TCTMP}/build_here
	%description
	A test RPM package used for testing rpm command.
	%prep
	%setup -q
	%build
	%install
        mkdir -p \$RPM_BUILD_ROOT/%{INSTALL_DIR}
	cd \$RPM_BUILD_ROOT/
	install $SOURCES_DIR/%{PKG_NAME}-1.0/%{FILE_NAME} %{INSTALL_DIR}
	%clean
	%files
	%defattr(-,root,root)
	/%{INSTALL_DIR}/
	/%{INSTALL_DIR}/%{FILE_NAME}
	EOF

	# Actual test begins
	rpmbuild -ba $SPECS_DIR/$PKG_NAME.spec &> $stdout
	tc_fail_if_bad $? "unexpected response" || return 
	NEW_RPM=`grep Wrote $stdout | grep -v src.rpm`

	[ "$NEW_RPM" ]
	tc_pass_or_fail $? "No rpm built" || return
}

#
# test03    rpm -i
#
function test03()
{
	tc_register "rpm -i"	
	if [ $ISPPCNF -eq 1 ]; then 
		THE_RPM=tst_rpm-1.0-1.noarch.rpm
		INSTALL_DIR=for_my_test
	else
		set $NEW_RPM
		THE_RPM=$2
	fi
	# install the rpm just built
	rpm -i $THE_RPM >$stdout 2>$stderr
	tc_fail_if_bad $?  "unexpected results" || return
	[ -e /$INSTALL_DIR/$FILE_NAME ]
	tc_pass_or_fail $?  "rpm $THE_RPM not installed properly"
}
#
# test04    rpm -q
#
function test04()
{
	tc_register "rpm -q"	

	rpm -q $PKG_NAME >$stdout 2>$stderr
	tc_fail_if_bad $?  "unexpected respons to rpm -q" || return

	rpm -ql $PKG_NAME | grep $FILE_NAME &>/dev/null
	tc_pass_or_fail $?  "file $FILE_NAME not listed by rpm -ql"
}

#
# test05    gendiff
#
function test05()
{
	# can't test gendiff if find command is busybox version
	tc_is_busybox find && (( --TST_TOTAL )) && return 0
	tc_register "gendiff"
	
	mkdir $TCTMP/diff &>/dev/null

	cat > $TCTMP/diff/t <<-EOF
		one 1
		two 2
		three 3
	EOF
	cat > $TCTMP/diff/tt <<-EOF
		four 4
		five 5
		six 6
	EOF
	cat > $TCTMP/diff/t.orig <<-EOF
		one
		two
		three
	EOF
	cat > $TCTMP/diff/tt.orig <<-EOF
		four
		five
		six
	EOF
	cd $TCTMP
	gendiff diff .orig &>$stdout
	[ $? -ne 0 ]
	tc_fail_if_bad $?  "unexpected response from gendiff diff .orig" || return

	grep -q '+five 5' $stdout 2>$stderr
	tc_pass_or_fail $?  "Expected to see \"+five 5\" in stdout"
}
#
# test06   rpm2cpio
#
function test06()
{
	tc_register "rpm2cpio"
	
	rpm2cpio $THE_RPM >$stdout 2>$stderr
	tc_fail_if_bad $?  "unexpected response" || return
	
	grep -q "$MESSAGE" $stdout
	tc_pass_or_fail $? "expected to see \"Hello\" in stdout"
}

#
# test07    rpmquery
#
function test07()
{
	tc_register "rpmquery"
	
	rpmquery -a >$stdout 2>$stderr
	tc_fail_if_bad $?  "unexpected response" || return 
	
	rpmquery  $PKG_NAME | grep $PKG_NAME &>/dev/null
	tc_pass_or_fail $?  "expected to see \"$PKG_NAME\" in stdout"
}
#
# test08    rpmverify
#
function test08()
{
	tc_register "rpmverify"
	
	
	rpmverify $PKG_NAME &>/dev/null
	tc_pass_or_fail $?  "\"$PKG_NAME\" is not installed"
}

#
# test09    rpm -e
#
function test09()
{
	tc_register "rpm -e"	
		
		
	rpm -e $PKG_NAME >$stdout 2>$stderr
	tc_fail_if_bad $?  "unexpected response" || return 

	[ ! -e /$INSTALL_DIR/$FILE_NAME ]
	tc_pass_or_fail $?  "$TCTMP/$INSTALL_DIR/$PKG_NAME.spec not deleted"
	

	# install the rpm again required for rpm-python tests
        rpm -i $THE_RPM >$stdout 2>$stderr
        tc_fail_if_bad $?  "unable to reinstall rpm" || return

        [ -e /$INSTALL_DIR/$FILE_NAME ]
        tc_fail_if_bad $?  "rpm $THE_RPM not installed properly"


}
#
# test10    initiate rpm-python pkj tests
#
function test10()
{
	tc_register "Execute tests for rpm-python sub-package"	
	

	[ -x $LTPBIN/rpm-python.sh ]
	tc_pass_or_fail $?  "$LTPBIN/rpm_python.sh not present or is not executable"

	$LTPBIN/rpm-python.sh

}
################################################################################
# main
################################################################################

# Total number of testcases in this file.
TST_TOTAL=10
[ $ISPPCNF  ] && TST_TOTAL=6
tc_setup
tc_root_or_break || exit
tc_exec_or_break $REQUIRED || exit

if [ $ISPPCNF -eq 1 ] ; then
	test01 || exit
	test03 || exit
	test04
	test06
	test07
	test08
else
	test01 || exit
	test02 || exit
	test03 || exit
	test04
	test05
	test06
	test07
	test08
	test09 || exit
	test10
fi
	
