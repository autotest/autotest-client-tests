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
### File :       texinfo.sh                                                    ##
##
### Description: Test for texinfo  package                                     ##
##
### Author:      Athira Rajeev <atrajeev@in.ibm.com>                           ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/texinfo
source $LTPBIN/tc_utils.source
#Texinfo::Parser Tests are under TP_DIR
TP_DIR="${LTPBIN%/shared}/texinfo/tp"
#Install-info tests are in INSTALLINFO_DIR
INSTALLINFO_DIR="${LTPBIN%/shared}/texinfo/install-info/tests"
POD_SIMPLE_TEX_DIR="${LTPBIN%/shared}/texinfo/Pod-Simple-Texinfo"
REQUIRED="makeinfo install-info grep"

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return 

	# link makeinfo to tests directory
	# path where it is referred to in the testcases
	texi2any_cmd=`which texi2any`
	ln -s /usr/share/texinfo/Texinfo $TP_DIR/Texinfo
	ln -s /usr/share/texinfo/DebugTexinfo $TP_DIR/DebugTexinfo
	ln -s /usr/share/texinfo/init $TP_DIR/init
	ln -s /usr/share/locale  $TP_DIR/LocaleData
	ln -s $texi2any_cmd $TP_DIR/texi2any.pl
	ln -s /usr/share/texinfo/Pod-Simple-Texinfo $POD_SIMPLE_TEX_DIR/lib
	# Take backup of def file
	cp $INSTALLINFO_DIR/defs $INSTALLINFO_DIR/defs.bak

	# Replace install-info path with 
	# system installed binary
	sed -i 's:install_info=${top_builddir}/install-info/ginstall-info:install_info="/sbin/install-info":g' $INSTALLINFO_DIR/defs
}

function tc_local_cleanup()
{
	mv $INSTALLINFO_DIR/defs.bak $INSTALLINFO_DIR/defs
	unset $ALL_TESTS
	unlink $TP_DIR/init
	unlink $TP_DIR/DebugTexinfo
	unlink $TP_DIR/Texinfo
	unlink $TP_DIR/LocaleData
	unlink $TP_DIR/texi2any.pl
	unlink $POD_SIMPLE_TEX_DIR/lib

}

function run_tp_test()
{
	pushd $TP_DIR/tests >$stdout 2>$stderr
	TESTS="sectioning coverage indices nested_formats contents layout"

	# There are many input files also in test
	# directory. Extracting only test executables to be run.
	for test in $TESTS;
	do
		tc_register "Test $test"
		export ALL_TESTS=yes
		./parser_tests.sh $test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
	done

	popd >$stdout 2>$stderr
}

function run_installinfo_test()
{
	pushd $INSTALLINFO_DIR/ >$stdout 2>$stderr
	TESTS=`ls | xargs file | grep executable | cut -f 1 -d ":"`
	for file in $TESTS
	do
		sed -i s'|^#!/bin/sh -x|#!/bin/sh|'g  $file
	done
	# There are many input files also in test
	# directory. Extracting only test executables to be run.
	for test in $TESTS;
        do
		tc_register "Test $test"
		./$test >$stdout 2>$stderr
		tc_pass_or_fail $? "$test failed"
        done

	popd >$stdout 2>$stderr
}

function run_pod_simple_tex_test()
{
	pushd $POD_SIMPLE_TEX_DIR/ > /dev/null 2>&1
	tc_register "Pod-Simple-Texinfo"
	sed -i s'|^#! /bin/sh -x|#!/bin/sh|'g prove.sh
	./prove.sh >$stdout 2>$stderr
	tc_pass_or_fail $? "Pod-Simple-Texinfo test failed"
	popd > /dev/null 2>&1
}
#
# main
#
tc_setup
run_installinfo_test
run_tp_test
run_pod_simple_tex_test
