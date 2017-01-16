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
## File :	expat.sh
##
## Description:	Test's EXPAT library API:
##
## Author:	Helen Pang, hpang@us.ibm.com
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/expat
source $LTPBIN/tc_utils.source
TEST_PATH=${LTPBIN%/shared}/expat

tc_local_setup()
{

OUTDIR=$TCTMP/output; mkdir $OUTDIR
GOODXML=$TCTMP/good.xml
BADXML=$TCTMP/bad.xml
cat<<EOF>$GOODXML
<?xml version="1.0" encoding="utf-8" ?> 
<department>
 <employee id="J.D">
  <name>John Doe</name> 
  <email>John.Doe@foo.com</email> 
 </employee>
 <employee id="B.S">
  <name>Bob Smith</name> 
  <email>Bob.Smith@foo.com</email> 
 </employee>
 <employee id="A.M">
  <name>Alice Miller</name> 
  <url href="http://www.foo.com/~amiller/" /> 
 </employee>
</department>
EOF

cat<<EOF>$BADXML
<?xml version="1.0" encoding="utf-8" ?> 
<department>
 <employee id="J.D">
  <name>John Doe</name> 
  <email>John.Doe@foo.com</email> 
 </employee>
 <employee id="B.S">
  <name>Bob Smith</name> 
  <email>Bob.Smith@foo.com</email> 
 </employee>
 </email>
 <employee id="A.M">
  <name>Alice Miller</name> 
  <url href="http://www.foo.com/~amiller/" /> 
 </employee>
</department>
EOF

}

################################################################################
# the testcase functions
################################################################################

#
# test01	test for good installation
#
function test01()
{
	tc_register "installation test"
	tc_exec_or_fail xmlwf || return
	tc_pass
}

#
# test02       test element processing
#
function test02()
{
        tc_register "test element"
	tc_exec_or_break diff || return

	$TEST_PATH/p_name <$GOODXML >$TCTMP/result1
	diff p_name.out $TCTMP/result1 >$stdout 2>$stderr
        tc_pass_or_fail $? "failed the element test"
}

#
# test03	test parsing attribute
#
function test03()
{
	tc_register "test attr"
	tc_exec_or_break diff || return

	$TEST_PATH/p_name_attr <$GOODXML >$TCTMP/result2
	diff p_name_attr.out $TCTMP/result2 >$stdout 2>$stderr
	tc_pass_or_fail $? "failed the attr test"
}

#
# test04	test xmlwf command (xml well formed) with good xml
#
function test04()
{
	local cmd="xmlwf -m -r -d $OUTDIR $GOODXML"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from $cmd" || return
	! [ -s $stdout ]
	tc_fail_if_bad $? "Should be nothing in stdout"
	local -a expected=(
	"attribute name"
	"starttag name"
	"endtag name"
	"chars str"
	)
	for exp in "${expected[@]}" ; do 
		grep -q "$exp" $OUTDIR/good.xml
		tc_fail_if_bad $? "expected to see \"$exp\" in output" || {
			tc_info "actual output follows ==============="
			cat $OUTDIR/good.xml
			tc_info "actual output above ================="
			return 1
		}
	done
	tc_pass
}

#
# test05	test xmlwf command (xml well formed) with bad xml
#
function test05()
{
	local cmd="xmlwf -m -r -d $OUTDIR $BADXML"
	tc_register "$cmd"
	$cmd >$stdout 2>$stderr
	if [ $? -eq 2 ]
        then
                tc_pass
        else
                tc_fail "unexpected response"
        fi
	[ -s $stdout ]
	tc_fail_if_bad $? "Should be a message in stdout"
	ls -l $OUTDIR >$stdout 2>$stderr
	! grep -q bad.xml $stdout
	tc_pass_or_fail $? "File \"bad.xml\" should not be in $OUTDIR"
}

################################################################################
# main
################################################################################

TST_TOTAL=5

# standard setup
tc_setup
tc_run_me_only_once

test01 &&
test02 
test03
test04
test05
