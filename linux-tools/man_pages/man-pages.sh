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
## File :       man-pages.sh
##
## Description: This testcase tests man pages provided by man-pages and man-pages-overrides
##
## Author:       Madhuri Appana, madhuria@linux.vnet.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source 

REQUIRED="man manpath"
################################################################################
# utility functions
################################################################################

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return
	tc_root_or_break || return
	rpm -q $mypkg >$stdout 2>$stderr
        tc_break_if_bad $? "\"$mypkg\" package is not installed"
}

################################################################################
# the testcase functions
################################################################################
function run_test()
{
	#This test case tests man pages for the additional packages listed in man-pages"
	installed_files=`rpm -qld $mypkg | grep /usr/share/man/`
	TESTS=`rpm -qld $mypkg | grep /usr/share/man/ | wc -l`
	TST_TOTAL=`expr $TESTS*2`
	for file in $installed_files
	do
        	section=`basename $file | sed s/\.gz$//g | awk '{print substr($0,length())}'`
		case $section in
			[a-z]*) 
                     		cmd=`basename $file | sed s/\.gz$//g | sed 's/\(.*\).../\1/'`
                     		man_section=`basename $file | sed s/\.gz$//g | awk '{print substr($0,length()-1)}'`;; 
                     	[0-9]*)
		     		cmd=`basename $file | sed s/\.gz$//g | sed 's/\(.*\)../\1/'` 
                     		man_section=`basename $file | sed s/\.gz$//g | awk '{print substr($0,length())}'`;; 
		esac 
                tc_register "Check for man page listing of $cmd additional packages"
                man $man_section $cmd >$stdout 2>$stderr
                tc_pass_or_fail $? "failed to display man page for \"$cmd\"" || return
                tc_register "Check for man path listing of $cmd additional packages"
                manfile_path=`man --path $cmd`
                RC=$?
                if  [ $file == $manfile_path ];
                then
                        tc_pass_or_fail $RC "Failed to display manpath for \"$cmd\""
                fi
        done

}

################################################################################
# main
################################################################################
mypkg=$1


if [ $# -eq 1 ]; then
	tc_setup
	run_test $1
else
     echo "Usage: $0 <package name> (package name can be either man-pages or man-pages-overrides)"
     exit
fi
