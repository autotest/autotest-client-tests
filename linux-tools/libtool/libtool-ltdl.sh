#!/bin/bash
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##    1.Redistributions of source code must retain the above copyright notice,            ##
##        this list of conditions and the following disclaimer.                           ##
##    2.Redistributions in binary form must reproduce the above copyright notice, this    ##
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
## File :       libtool-ltdl.sh                                                           ##
##                                                                                        ##
## Description: Test for libtool-ltdl package                                             ##
##                                                                                        ##
## Author:      Spoorthy < spoorts2@in.ibm.com >                                          ##
##                                                                                        ##
###########################################################################################

#
# Global variables used in this script
#

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libtool
TESTDIR=${LTPBIN%/shared}/libtool
source $LTPBIN/tc_utils.source
LTDLTEST="${LTPBIN%/shared}/libtool/tests"



#
# Function to run prerequisites to run this test
#

function tc_local_setup()
{
	#to check the required package is installed
	#tc_check_package "libtool-ltdl" >$stdout 2>$stderr
	tc_check_package "libltdl7" >$stdout 2>$stderr
	tc_break_if_bad $? "$PKG_NAME is not installed"

	#to link the libtool to the current path for test execution
        libpath=`which libtool`
	ln -s $libpath libtool
        grep -i "ubuntu" /etc/*release >/dev/null 2>&1
        if [ $? -eq 0 ];then
		lib_path="`ls /usr/lib/*-linux-gnu/libltdl.so.7`"
	else
		lib_path="`ls /usr/lib*/libltdl.so libltdl/.libs/`"
	fi
	ln -s $lib_path libltdl/.libs/
}


#
# run the test suites which are available on test/t directory
#

function run_test()
{
        tc_register "testing libtool and libtool-ltdl functionality"

	cd ./tests && autom4te --language=autotest `echo tests/testsuite.at tests/getopt-m4sh.at tests/libtoolize.at tests/help.at tests/duplicate_members.at tests/duplicate_conv.at tests/duplicate_deps.at tests/flags.at tests/inherited_flags.at tests/convenience.at tests/link-order.at tests/link-order2.at tests/fail.at tests/shlibpath.at tests/runpath-in-lalib.at tests/static.at tests/export.at tests/search-path.at tests/indirect_deps.at tests/archive-in-archive.at tests/exeext.at tests/execute-mode.at tests/bindir.at tests/cwrapper.at tests/deplib-in-subdir.at tests/infer-tag.at tests/localization.at tests/nocase.at tests/install.at tests/versioning.at tests/destdir.at tests/old-m4-iface.at tests/am-subdir.at tests/lt_dlexit.at tests/lt_dladvise.at tests/lt_dlopen.at tests/lt_dlopen_a.at tests/lt_dlopenext.at tests/ltdl-libdir.at tests/ltdl-api.at tests/dlloader-api.at tests/loadlibrary.at tests/lalib-syntax.at tests/resident.at tests/slist.at tests/need_lib_prefix.at tests/standalone.at tests/subproject.at tests/nonrecursive.at tests/recursive.at tests/template.at tests/ctor.at tests/exceptions.at tests/early-libtool.at tests/with-pic.at tests/no-executables.at tests/deplibs-ident.at tests/configure-iface.at tests/cmdline_wrap.at tests/pic_flag.at tests/darwin.at tests/dumpbin-symbols.at tests/deplibs-mingw.at tests/sysroot.at | sed 's,tests/,,g'` -o testsuite.tmp && mv -f testsuite.tmp testsuite		
	cd -
	abs_srcdir=`CDPATH="${ZSH_VERSION+.}:" && cd . && pwd`;
	cd -
	CONFIG_SHELL="/bin/sh" /bin/sh $abs_srcdir/tests/testsuite \
	MAKE="make" CC="gcc" CFLAGS="-g -O2" CPP="gcc -E" CPPFLAGS="" LD="/usr/bin/ld" LDFLAGS="" LIBS="-ldl " LN_S="ln -s" NM="/usr/bin/nm -B" RANLIB="ranlib" AR="ar" M4SH="autom4te --language=m4sh" SED="/usr/bin/sed" STRIP="strip" lt_INSTALL="/usr/bin/install -c" MANIFEST_TOOL=":" OBJEXT="o" EXEEXT="" SHELL="/bin/sh" CONFIG_SHELL="/bin/sh" CXX="g++" CXXFLAGS="" CXXCPP="" F77="" FFLAGS="" FC="" FCFLAGS="" GCJ="" GCJFLAGS="-g -O2" lt_cv_to_host_file_cmd="func_convert_file_noop" lt_cv_to_tool_file_cmd="func_convert_file_noop" _lt_pkgdatadir="${LTPBIN%/shared}/libtool" LIBTOOLIZE="/usr/bin/libtoolize" LIBTOOL="/usr/bin/libtool" tst_aclocaldir="${LTPBIN%/shared}/libtool/libltdl/m4"

	tc_pass_or_fail $? "$test failed"
}

function tc_local_cleanup()
{
	rm -rf libtool
}

#
# Main script
#
tc_setup                        # Calling setup function
run_test       			# Calling test functions
