#!/bin/sh
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
## File :        Xerces-C
##
## Description:	Xerces-C give your application the ability to read and write XML data.
##
## Author:	Pravin S. Gaikar
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/xerces_c
source $LTPBIN/tc_utils.source

test_dir="${LTPBIN%/shared}/xerces_c/xerces-c-tests"
data=$test_dir/data
fooxml=$data/personal.xml
fooout=$data/foo.out
fooschema=$data/personal-schema.xml

cmdlist="SAXCount SAXPrint SAX2Count SAX2Print MemParse Redirect DOMCount DOMPrint StdInParse PParse EnumVal SEnumVal CreateDOMDocument" 

REQUIRED="grep"

ErrMsg="Fail to grep output"
ErrMsg1="Fail to execute command"

#
# Local cleanup
#
function tc_local_cleanup()
{
	[ -f $fooout ] &&  rm -f $fooout
}

function test_SAXCount(){
	tc_register "$1"

	$test_dir/$1 -v=never $fooxml > $stdout 2>$stderr
	tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep "(.*elems,.*attrs,.*spaces,.*chars)" $fooout > $stdout 2>$stderr
	tc_fail_if_bad $? "$ErrMsg one" || return
	
	$test_dir/$1 -n -s $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout

        grep "(.*elems,.*attrs,.*spaces,.*chars)" $fooout > $stdout 2>$stderr
	tc_pass_or_fail $?  "$ErrMsg two"
}


function test_SAXPrint(){
	tc_register "$1"

        $test_dir/$1 $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 tne" || return
	cp $stdout $fooout

        grep "" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

        $test_dir/$1 -n -s $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout

        grep "" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg two"
}


function test_SAX2Count(){
	tc_register "$1"

        $test_dir/$1 -v=never $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep "(.*elems,.*attrs,.*spaces,.*chars)" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

        $test_dir/$1 -n -s $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout

        grep "(.*elems,.*attrs,.*spaces,.*chars)" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg two"
}

function test_SAX2Print(){
	tc_register "$1"

        $test_dir/$1 $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep "<name><family>Worker</family> <given>One</given></name>" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

        $test_dir/$1 -n -s $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout

        grep "<name xml:base=\"/car/foo/\"><family xml:base=\"bar/bar\">Worker</family> <given>One</given></name>" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg two"
}

function test_MemParse(){
	tc_register "$1"

        $test_dir/$1 > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep -F "(4 elements, 1 attributes, 16 spaces, 95 characters)." $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

        $test_dir/$1 -v=never > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout

        grep -F "(4 elements, 1 attributes, 0 spaces, 111 characters)." $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg two"
}

function test_Redirect(){
	tc_register "$1"

        (
        cd $data
        $test_dir/$1 $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	)
	cp $stdout $fooout

        grep -F "(37 elems, 12 attrs, 0 spaces, 268 chars)" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg one"
}

function test_DOMCount(){
        tc_register "$1"

        $test_dir/$1 -v=never $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep -F "(37 elems)." $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

        $test_dir/$1 -n -s $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout

        grep -F "(37 elems)." $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg two"
}

function test_DOMPrint(){
        tc_register "$1"

        $test_dir/$1  -wfpp=on -wddc=off $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep -F "  <person id=\"two.worker\">" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

        $test_dir/$1  -wfpp=off -wddc=on $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout

        grep -F "  <person id=\"two.worker\">" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg two" || return

        $test_dir/$1 -wfpp=on -wddc=off -n -s $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 three" || return
	cp $stdout $fooout

        grep -F "  <person contr=\"false\" id=\"one.worker\" xml:base=\"/auto/bar\">" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg three"
}

function test_StdInParse(){
        tc_register "$1"

	(
	cd $data  2>$stderr 
        $test_dir/$1 -v=never < $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout
	)

        grep -F "(37 elems, 12 attrs, 0 spaces, 268 chars)" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

	(
	cd $data 2>$stderr
        $test_dir/$1 -n -s < $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout
	)

        grep -F "(37 elems, 29 attrs, 140 spaces, 128 chars)" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg two"
}

function test_PParse(){
        tc_register "$1"

        $test_dir/$1 $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep -F "(37 elems, 12 attrs, 134 spaces, 134 chars)" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

        $test_dir/$1 -n -s $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 two" || return
	cp $stdout $fooout

        grep -F "(37 elems, 29 attrs, 140 spaces, 128 chars)" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg two"
}

function test_EnumVal(){
        tc_register "$1"

        $test_dir/$1 $fooxml > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep -F "  Name: personnel" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return


        grep -F "  Content Model: (person)+" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg two"
}

function test_SEnumVal(){
        tc_register "$1"

        $test_dir/$1 $fooschema > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep "Name:.*family" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg one" || return

        grep "Model Type:.*Simple" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg two" || return

        grep  "Create Reason:.*Declared" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg three" || return

        grep  "ComplexType:" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg four" || return

        grep ".*TypeName:.*,*C3" $fooout > $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg five" || return

        grep  "Base Datatype:.*string" $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg six"
}

function test_CreateDOMDocument(){
        tc_register "$1"

        $test_dir/$1 >  $stdout 2>$stderr
        tc_fail_if_bad $? "$ErrMsg1 one" || return
	cp $stdout $fooout

        grep  "The tree just created contains: 4 elements." $fooout > $stdout 2>$stderr
        tc_pass_or_fail $?  "$ErrMsg one"
}


################################################################################
# main
################################################################################

set $cmdlist
TST_TOTAL=$#

tc_setup

# Check if supporting utilities are available
tc_exec_or_break $REQUIRED || exit

for cmd  in $cmdlist
do
        test_$cmd  $cmd 
done
################################################################################
