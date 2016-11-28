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
## File :	test_pcre.sh
##
## Description:	Test pcre/libpcre package
##
## Author:	Robb Romans <robb@austin.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/pcre
source $LTPBIN/tc_utils.source

REQUIRED="diff"
testdir=${LTPBIN%/shared}/pcre/pcre-tests/
testdata=${testdir}/testdata
################################################################################
# testcase functions
################################################################################
# The core of the tests.
# Run the tests with options and compare the results.
# OPTS should be set to the options for the pcretest command
# $1 input
# $2 expected output
function runtest {
	pcretest -q $OPTS $1 $TCTMP/testtry 2>$stderr >$stdout
	tc_fail_if_bad $? "pcretest failed with exit status : $?" || return
	diff $TCTMP/testtry $2 >$stderr
	tc_pass_or_fail $? "Unexpected results"
}
	

function tc_local_setup {
    #tc_executes pcre-config pcregrep pcretest
    tc_executes pcregrep pcretest || { 
    	export PATH=$PATH:$testdir 
	tc_info "Using pcretest/pcregrep packaged with pcre-tests"
    }

    pcretest -C | pcregrep 'No UTF-8 support' &>/dev/null
    utf8=$?
    pcretest -C | pcregrep 'No Unicode properties support' &>/dev/null
    ucp=$?

    if [ $utf8 -ne 0 ]; then
    	tc_info "pcre : UTF-8 support is configured"
    fi
    if [ $ucp -ne 0 ]; then
    	tc_info "pcre: Unicode properties support is configured"
    fi
}

function test01 {
    tc_register "Testing main PCRE functionality (Perl compatible)."
    OPTS=
    runtest $testdata/testinput1 $testdata/testoutput1
}


# PCRE tests that are not Perl-compatible - API & error tests, mostly
function test02 {
    expect=$testdata/testoutput2

# The results are a little different for s390x due to recursion limit set to avoid
# stack overflows. See bug 57152
    ARCH=`uname -m 2>/dev/null`

# For s390x it is matching the output. So no separate output is required.
#    [ "$ARCH" == "s390x" ] && expect=$testdata/testoutput2-s390x
    tc_register "Testing PCRE API and error handling (not Perl compatible)."
    OPTS=
    runtest  $testdata/testinput2 $expect
}


# Additional Perl-compatible tests for Perl 5.005's new features
function test03 {
    locale -a 2>/dev/null | pcregrep '^fr_FR' &>/dev/null
    if [ $? -ne 0 ] ; then 
    	tc_info "Missing locale: fr_FR. Test locale specific features skipped"
	return
    fi
    tc_register "Testing locale specific features(fr_FR)"

    runtest $testdata/testinput3 $testdata/testoutput3
}

function test04 {
	tc_register "UTF-8 support (Perl compatible)"
	runtest $testdata/testinput4 $testdata/testoutput4
}

function test05 {
	tc_register "API and internals for UTF-8 support (not Perl compatible)"
	runtest $testdata/testinput5 $testdata/testoutput5
}

function test06 {
	tc_register "Unicode property support"
	runtest $testdata/testinput6  $testdata/testoutput6
}

function test07 {
	tc_register "Unicode property support (not Perl compatible)"
	runtest  $testdata/testinput7  $testdata/testoutput7
}

function test08 {
	tc_register "DFA matching"
	OPTS=-dfa
	runtest  $testdata/testinput8  $testdata/testoutput8
}

function test09 {
	tc_register "DFA matching with UTF-8"
	OPTS=-dfa
	runtest  $testdata/testinput9  $testdata/testoutput9
}

function test10 {
	tc_register "DFA matching with Unicode properties"
	OPTS=-dfa
	runtest  $testdata/testinput10  $testdata/testoutput10
}

####################################################################################
# MAIN
####################################################################################

# Function:	main
#

#
# Exit:		- zero on success
#		- non-zero on failure
#

UNIT_TESTS="pcrecpp_unittest pcre_scanner_unittest pcre_stringpiece_unittest"
tc_setup
tc_exec_or_break $REQUIRED || exit
test01 &&
test02 &&
test03

[ $utf8 -ne 0 ] && test04 && test05
[ $utf8 -ne 0 -a $ucp -ne 0 ] && test06 && test07
test08
[ $utf8 -ne 0 ] && test09
[ $utf8 -ne 0 -a $ucp -ne 0 ] && test10

for t in $UNIT_TESTS; do
	tc_register "$t"
	$testdir/$t > $stdout 2>$stderr
	tc_pass_or_fail $? "$t failed"
done
