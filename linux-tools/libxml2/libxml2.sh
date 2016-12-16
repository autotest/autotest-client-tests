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
## File :	libxml2.sh
##
## Description:	Tests the XML C libraries, xmlcatalog, and xmllint.
##
## Author:	Andrew Pham, apham@us.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libxml2
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/libxml2
cd $TESTDIR

# Initialize output messages
ErrMsg="Failed: Not available."
ErrMsg1="Failed: Unexpected output.  Expected:"
################################################################################
# global variables
################################################################################

commands=" libxml2 xmlcatalog "	

################################################################################
# the testcase functions
################################################################################

function TC_libxml2()
{
	cd libxml2-tests
	./runtest >$stdout 2>$stderr
	cat $stderr | grep -Ev "extparsedent|758588|759020|759573"
	if [ $? == 1 ]; then
		cat /dev/null > $stderr
	fi
	tc_pass_or_fail $? "libxml2 runtest failure"
}

function TC_xmlcatalog()
{
	local id=id$$b
	# Check if supporting utilities are available
	tc_exec_or_break  grep || return
	
	xmlcatalog --create --noout $TCTMP/xcatlog >/dev/null 2>$stderr
	tc_pass_or_fail $? "--create --nout does not work." || return

	tc_register "xmlcatalog --add --noout "
	let TST_TOTAL+=1
	
	xmlcatalog --add public $id xadd123 --noout $TCTMP/xcatlog
	tc_fail_if_bad $? "$ErrMsg" || return

	cat $TCTMP/xcatlog | grep $id >&/dev/null
	tc_pass_or_fail $? "$ErrMsg1 $id in catalog." || return

	tc_register "xmlcatalog --del --noout "
	let TST_TOTAL+=1
	
	xmlcatalog --del xadd123 --noout $TCTMP/xcatlog
	tc_fail_if_bad $? "$ErrMsg" || return

	grep -q $id $TCTMP/xcatlog
	[ $? -ne 0 ]
	tc_pass_or_fail $? "$ErrMsg1 $id NOT found in catalog."
}

function TC_xmllint()
{
	local id=id123
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return

	# Creating a test xml file
	cat > $TCTMP/test.xml<<-EOF
	<?xml version="1.0" encoding="ISO-8859-1" ?>
	<Msg>
	<text1 title="Testing xmllint">
	id123: My testing sample file.
	</text1>
	</Msg>
	EOF
	
	xmllint --htmlout --nowrap $TCTMP/test.xml >&/dev/null
	tc_fail_if_bad $? "--htmlout does not work." || return

	xmllint --htmlout --nowrap $TCTMP/test.xml | grep $id >&/dev/null
	tc_pass_or_fail $? " --htmlout $ErrMsg1 $id" || return

	tc_register "xmlcatalog --timing "
	let TST_TOTAL+=1
	
	xmllint --timing $TCTMP/test.xml >&$TCTMP/xmltiming.tst
	tc_fail_if_bad $? "--timing does not work." || return

	cat $TCTMP/xmltiming.tst | grep Freeing >&/dev/null
	tc_pass_or_fail $? "--timing: Failed: Unexpected output."
}
################################################################################
# main
################################################################################

set $commands
TST_TOTAL=$#

tc_setup

[ "$TCTMP" ] && rm -rf $TCTMP/*

FRC=0
#
# run all the tests
#
for cmd in $commands ; do
	tc_register $cmd
	TC_$cmd || FRC=$?
done
exit $FRC
