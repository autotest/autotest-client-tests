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
## File :	dos2unix.sh
##
## Description:	Test dos2unix package
##
## Author:	Andrew Pham, apham@austin.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/dos2unix
source $LTPBIN/tc_utils.source
TEST_PATH=${LTPBIN%/shared}/dos2unix

TST_TOTAL=6
REQUIRED="dos2unix mac2unix ls cat"
date1="no"
date2="yes"

# a function to return the date of a given file.
function getdate()
{
	local cnt=0
	for i in `ls -l $2`
	do
		let cnt+=1
		[ $cnt -eq 6 ] && d=$i && break
	done
	[ $1 -eq 1 ] && date1=$d
	[ $1 -eq 2 ] && date2=$d
}
################################################################################
# testcase functions
################################################################################
function TC_dos2unix-n()
{	
	tc_register "dos2unix -n"
	
	dos2unix -n $TCTMP/tstfile.txt $TCTMP/dos_out.txt > $stdout 2>/dev/null
	tc_fail_if_bad $? "Not available." || return

	$TEST_PATH/dos2unix_chk dos $TCTMP/dos_out.txt 
	tc_pass_or_fail $? "Unexpected output: cr still there in output." 
}

function TC_dos2unix-k()
{	
	tc_register "dos2unix -nk"
	
	dos2unix -n -k $TCTMP/tstfile.txt $TCTMP/dos_out.txt > $stdout 2>/dev/null
	tc_fail_if_bad $? "Not available." || return

	getdate 1 $TCTMP/tstfile.txt
	getdate 2 $TCTMP/dos_out.txt
	
	[ "$date1" == "$date2" ]
	tc_pass_or_fail $? "Unexpected output: dates are not the same:$date1, $date2."
}

function TC_mac2unix-n()
{	
	tc_register "mac2unix -n"

	mac2unix -n $TCTMP/mac_tstfile.txt $TCTMP/mac_out.txt >$stdout 2>/dev/null
	tc_fail_if_bad $? "Not available." || return
	
	$TEST_PATH/dos2unix_chk mac $TCTMP/mac_out.txt 
	tc_pass_or_fail $? "Unexpected output: cr still there or cr not converted to newline." 
}


function TC_mac2unix-k()
{	
	tc_register "mac2unix -nk"
	
	mac2unix -n -k $TCTMP/tstfile.txt $TCTMP/mac_out.txt > $stdout 2>/dev/null
	tc_fail_if_bad $? "Not available." || return
	
	getdate 1 $TCTMP/mac_tstfile.txt
	getdate 2 $TCTMP/mac_out.txt
	
	[ "$date1" == "$date2" ]
	tc_pass_or_fail $? "Unexpected output: the dates are not the same."
}
function TC_unix2dos-n()
{	
	tc_register "unix2dos -n"
	
	# create a test file
	cat > $TCTMP/file.txt <<-EOF
	A test file for dos2unix.
	There should be 3 ^M removed by dos2unix.



	That's all folks!!!
	EOF

	unix2dos -n $TCTMP/file.txt $TCTMP/tstfile.txt > $stdout 2>/dev/null
	tc_pass_or_fail $? "Unexpected output: cr still there in output." 
}
function TC_unix2mac-n()
{
        tc_register "unix2mac -n"

        # create a test file
        cat > $TCTMP/file.txt <<-EOF
        A test file for dos2unix.
        There should be 3 ^M removed by dos2unix.



        That's all folks!!!
	EOF

        unix2mac -n $TCTMP/file.txt $TCTMP/mac_tstfile.txt  > $stdout 2>/dev/null
        tc_pass_or_fail $? "Unexpected output: cr still there in output."
}


################################################################################
# main
################################################################################
tc_setup

# Check if supporting utilities are available
tc_exec_or_break  $REQUIRED || exit

# Test dos2unix
E_value=0
TC_unix2dos-n || E_value=$?
TC_dos2unix-n || E_value=$?
TC_dos2unix-k || E_value=$? 
TC_unix2mac-n || E_value=$?
TC_mac2unix-n || E_value=$?
TC_mac2unix-k || E_value=$?
exit $E_value
