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
## File :	libtool.sh
##
## Description: shell script for libtool package test
##
## Author:	CSDL
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libtool
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################
GCC=`< FIV_CC_NAME.txt`
REQUIRED="mkdir ldd grep"
INSTALLED="libtool"

CURDIR=`pwd`

LIBTOOL=`which libtool`
GREP=`which grep`
LDD=`which ldd`
MKDIR=`which mkdir`

TESTDIR=${LTPBIN%/shared}/libtool
cd $TESTDIR

#
# tc_local_setup
#
function tc_local_setup()
{
	tc_exec_or_break $REUIRED
	tc_fail_if_bad $? "require tools to do test" || exit

	tc_exec_or_break $INSTALLED
	tc_fail_if_bad $? "package libtool not properly installed" || exit

	cp -f $TESTDIR/libtool_demo/install-sh $TCTMP/
	cp -f $TESTDIR/libtool_demo/foo.h $TCTMP/
	cp -f $TESTDIR/libtool_demo/foo.c $TCTMP/
	cp -f $TESTDIR/libtool_demo/hello.c $TCTMP/
	cp -f $TESTDIR/libtool_demo/main.c $TCTMP/

	cd $TCTMP

	[ -f install-sh ] && [ -f foo.h ] && [ -f foo.c ] && \
	[ -f hello.c ] && [ -f main.c ]
	tc_pass_or_fail $? "source files for test not found"
}

################################################################################
# local utility functions
################################################################################

#
# test01: creating objects
#
function test01(){
	TST_TOTAL=1
	tc_register "libtool: creating object: foo.c --> foo.o"
	$LIBTOOL --mode=compile --tag=CC $GCC -DHAVE_MATH_H -g -O -c foo.c >$stdout 2>$stderr
	tc_pass_or_fail $? "compile foo.c failed"

	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: creating object: hello.c --> hello.o"
	$LIBTOOL --mode=compile --tag=CC $GCC -g -O -c hello.c >$stdout 2>$stderr
	tc_pass_or_fail $? "compile hello.c failed"

	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: creating object: main.c --> main.o"
	$LIBTOOL --mode=compile --tag=CC $GCC -g -O -c main.c >$stdout 2>$stderr
	tc_pass_or_fail $? "compile main.c failed"
}

#
# test02: linking libraries
#
function test02(){
	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: linking library: foo.lo, hello.lo --> libhello.la"
	$LIBTOOL --mode=link --tag=CC $GCC -g -O -o libhello.la foo.lo hello.lo -rpath $TCTMP/libs -lm >$stdout 2>$stderr
	tc_pass_or_fail $? "linking library libhello.la failed"
}

#
# test03: linking executables
#
function test03(){
	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: linking executable: main.o, libhello.la --> hell"
	$LIBTOOL --mode=link --tag=CC $GCC -g -O -o hell main.o libhello.la -lm >$stdout 2>$stderr
	tc_fail_if_bad $? "linking executable hell failed"

	./hell >$stdout 2>$stderr
	$GREP ".*This is not GNU Hello.*" $stdout >/dev/null 2>&1
	tc_fail_if_bad $? "excute hell result in unexpected output"
}

#
# test05: installing libraries
#
function test05(){
	$MKDIR -p $TCTMP/libs

	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: installing library: libhello.la --> libs/libhello.la"
	$LIBTOOL --mode=install cp libhello.la $TCTMP/libs/libhello.so >$stdout 2>$stderr
	tc_pass_or_fail $? "install library libs/libhello.la failed"
}

#
# test06: installing executables
#
function test06(){
	$MKDIR -p $TCTMP/bin

	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: installing executable: hell --> bin/hell"
	$LIBTOOL --mode=install install -c hell $TCTMP/bin/hell >$stdout 2>$stderr
	tc_fail_if_bad $? "install executable bin/hell failed" || return

	$LDD $TCTMP/bin/hell >$stdout 2>$stderr
	$GREP ".*libhello.so.*=>.*$TCTMP/libs/libhello.so.*" $stdout >/dev/null 2>&1
	tc_pass_or_fail $? "excutable bin/hell linking error"
}

#
# test07: linking static libraries
#
function test07(){
	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: linking static library: libhello.la --> libs/libhello.a"
	$LIBTOOL --mode=install ./install-sh -c libhello.la $TCTMP/libs/libhello.a >$stdout 2>$stderr
	tc_fail_if_bad $? "linking static library failed" || return

	$LIBTOOL --mode=link --tag=CC $GCC -o hell-static main.o libs/libhello.a -lm >$stdout 2>$stderr
	tc_fail_if_bad $? "linking static library to executable failed" || return

	$LDD $TCTMP/hell-static >$stdout 2>$stderr
	$GREP ".*libhello.*=>.*$TCTMP/libs/libhello.*" $stdout >/dev/null 2>&1
	[ $? -ne 0 ]
	tc_pass_or_fail $? "libhello should not appear as a shared object"
}

#
# test08: complete library installing
#
function test08(){
	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: finish library installing"
	$LIBTOOL --mode=finish $TCTMP/libs >$stdout 2>$stderr
	tc_fail_if_bad $? "complete library installing failed" || return

	$GREP ".*ldconfig.*$TCTMP/libs.*" $stdout >/dev/null 2>&1
	tc_pass_or_fail $? "$TCTMP/libs failed to be configured to dynamic linker run time bindings"
}

#
# test09: uninstall objects
#
function test09(){
	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: uninstall foo.o hello.o main.o"
	$LIBTOOL --mode=uninstall rm -f foo.o hello.o main.o >$stdout 2>$stderr
	tc_pass_or_fail $? "uninstall obsolete objects failed"
}

#
# test10: clean libraries
#
function test10(){
	let TST_TOTAL=$TST_TOTAL+1
	tc_register "libtool: clean libhello.la"
	$LIBTOOL --mode=clean rm -f libhello.la >$stdout 2>$stderr
	tc_pass_or_fail $? "clean up failed"
}

################################################################################
# main
################################################################################
tc_setup
test01 &&
test02 &&
test03 &&
test05 &&
test06 &&
test07 &&
{ test08; test09; test10; }
