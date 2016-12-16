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
# File :   fbset_tests.sh
#
# Description: This program tests basic functionality of fbset command.
#
# Author:   Manoj Iyer  manjo@mail.utexas.edu
#

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/fbset
source $LTPBIN/tc_utils.source

#
# tc_local_cleanup
#
tc_local_cleanup()
{
	[ "$XRES" = "NONE" ] ||
	{
		fbset -xres $XRES -yres $YRES >$stdout 2>$stderr || \
		tc_break_if_bad $? "unable to restore original geometry" ||
			return
		tc_info "restored ${XRES}x$YRES geometry"
	}
	killall -9 Xvfb
}

#
# tc_local_setup
#
tc_local_setup()
{
	XRES="NONE"
	YRES="NONE"

	tc_root_or_break || return
	tc_exec_or_break grep Xvfb || return

	( Xvfb :6 -screen scrn 1024x768x16 & ) &>/dev/null
}

#
# test01	installation check
#
function test01()
{
	tc_register "installation check"
	tc_executes fbset
	tc_fail_if_bad $? "fbset not properly installed"

	fbset >$stdout 2>$stderr
	tc_pass_or_fail $? "unable to get current fb settings" || return

	set $(grep geometry $stdout)
	XRES=$2
	YRES=$3
	
	tc_info "Original geometry is ${XRES}x$YRES"
}

#
# test02	Test that fbset with no input parameters will display the 
#		current frame buffer settings.
#
function test02()
{
	tc_register    "fbset displays correct output"

	fbset >$stdout 2>$stderr
	tc_fail_if_bad $? "failed to print default settings" || return

	grep -q "geometry" $stdout &&
	grep -q "timings" $stdout &&
	grep -q "rgba" $stdout
	tc_pass_or_fail $? "expected key words(geometry, timings, rgba) not found"
}

#
# test03	Test that fbset command can resize the geometry
#
function test03()
{
	tc_register    "fbset geometry to 640x480"

	tc_info "This test seems to fail, even on SuSE. Probably not a valid testcase."
	
	fbset -xres 640 -yres 480 2>$stderr 1>$stdout
	tc_fail_if_bad $? "Failed to to set resolution to 640x480" || return

	fbset >$stdout 2>$stderr
	grep -q "640x480" $stdout 2>>$stderr
	tc_pass_or_fail $? "Failed to set 640x480 (or failed to report it)"
}

# 
# main
# 

TST_TOTAL=3
tc_get_os_arch
if [ "$TC_OS_ARCH" != "s390x" ]; then
	tc_setup
	test01 &&
	test02 &&
	test03
else
	echo "Could not initialize frame buffer :No available video devices "
fi
