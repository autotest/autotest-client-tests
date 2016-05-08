#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab :
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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
# File :        libxslt 
#
# Description:  Libxslt is the XSLT C library developed for the GNOME project. 
#		XSLT itself is a an XML language to define transformation for XML. 
#		Libxslt is based on libxml2 the XML C library developed for the GNOME project. 
#
# Author:       Pravin S. Gaikar 
#
################################################################################
# source the standard utility functions
###############################################################################

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

cmd="/usr/bin/xsltproc"

samples=${LTPBIN%/shared}/libxslt/samples
fooxml=foo.xml
fooxsl=foo.xsl

REQUIRED="grep"

#
# Local cleanup
#
function tc_local_cleanup()
{
	rm -rf $samples/*.out
	return 0
}


function test02(){
	tc_register "libxslt"

        $cmd $fooxsl $fooxml > $stdout 2>$stderr
	tc_fail_if_bad $? "command $cmd failed" || return

	local expected="<title>s1 foo</title>"
        grep -qF "$expected" $stdout 2>$stderr
	tc_pass_or_fail $? "expected to see $expected in stdout"
}

#
# Installation check
#
function test01()
{
    tc_register "Installation check"

    tc_executes $cmd 
    tc_pass_or_fail $? "libxslt not properly installed."
}



# main
################################################################################

TST_TOTAL=1

tc_setup 

# Check if supporting utilities are available
tc_exec_or_break $REQUIRED || exit

test01 || exit 

my_pwd=$(pwd)
cd $samples || exit
test02
cd $my_pwd

exit 0

