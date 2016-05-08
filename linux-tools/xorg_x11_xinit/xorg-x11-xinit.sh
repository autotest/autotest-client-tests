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
## File :	xorg-x11-xinit.sh
##
## Description:	This testcase tests xorg-x11-xinit package.
##
## Author:	Nilesh Borate, nilesh.borate@in.ibm.com
###########################################################################################
## source the standard utility functions

#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
xinit_pid=""

################################################################################
# the testcase functions
################################################################################

#
# local setup function
#
function tc_local_setup()
{
	tc_exec_or_break "grep Xvnc"

	# Back up the original .xinitrc file, if present.
	[ -f ~/.xinitrc ] && mv ~/.xinitrc ~/.xinitrc_save$$
	
	# Create a new .xinitrc file, which will get invoked on xinit start
	cat > ~/.xinitrc <<EOF
	#!/bin/bash
	exec >$TCTMP/xinit-app.log
	echo "Display is set to \$DISPLAY"
	while true; do sleep 20; done
EOF
}

#
# local cleanup function
#
function tc_local_cleanup()
{
	if [ "$xinit_pid" != "" ]; then
		tc_info "Killing the xinit process that we have started. \
			This will kill the Xvnc server and .xinitrc invocation, as well."
		kill $xinit_pid >$stdout 2>$stderr
		sleep 5
	fi

	# Restore the original .xinitrc file, if it exists
	rm -rf ~/.xinitrc
	[ -f ~/.xinitrc_save$$ ] && mv ~/.xinitrc_save$$ ~/.xinitrc
		
}

#
# test01        installation check
#
function test01()
{
        tc_register     "installation check"
        tc_executes xinit
        tc_pass_or_fail $? "xorg-x11-xinit not properly installed" || exit
}

#
# test02	xinit
#
function test02()
{
	tc_register	"xinit test"

	tc_info "Running the xinit process. This will start an Xvnc server and invoke a sample .xinitrc script"
	export TCTMP
	xinit -- /usr/bin/Xvnc :4 & >$stdout 2>$stderr
	# Wait for xinit to get the X server and xterm to started properly.
	sleep 5

	tc_info "Checking if xinit has started properly with the parameters that we have passed"
	ps ax  | grep "xinit" | grep "\-\-"| grep "\/usr\/bin\/Xvnc" | grep "\:4" >$stdout 2>$stderr
	tc_fail_if_bad $? "xinit command failed to start properly" || return

	xinit_pid=$!

	tc_info "Checking if Xvnc has started properly on the required display"
	ps ax | grep Xvnc | grep "\:4" >$stdout 2>$stderr
	tc_fail_if_bad $? "Xvnc server did not start properly on the desired display :4" || return

	tc_info "Checking whether the .xinitrc file is invoked and executed properly after xinit is started"
	[ -f $TCTMP/xinit-app.log ] && grep "Display is set to :4" $TCTMP/xinit-app.log >$stdout 2>$stderr
	tc_pass_or_fail $? "Display is not set to :4 as desired in $TCTMP/xinit-app.log file, \
	or $TCTMP/xinit-app.log file not found"
}


################################################################################
# main
################################################################################

TST_TOTAL=2

# standard tc_setup
tc_setup

test01 
test02
