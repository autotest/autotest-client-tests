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
### File :        pango.sh                                                     ##
##
### Description: This testcase tests pango package                             ##
##
### Author:      Ramesh YR, rameshyr@linux.vnet.ibm.com                        ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/pango
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/pango/tests"
modules_file="${LTPBIN%/shared}/pango/modules/pango.modules"

function tc_local_setup()
{
        rpm -q "pango" >$stdout 2>$stderr
	tc_break_if_bad $? "pango package is not installed"

	#To resolve a linker issue for 'testboundaries' test
	version=`rpm -qv pango|cut -d"-" -f2` >$stdout 2>$stderr
	sed -i 's|/builddir/build/BUILD/pango-'$version'/modules/./thai|'${LTPBIN%/shared}'/pango/modules/thai|' $modules_file
	sed -i 's|/builddir/build/BUILD/pango-'$version'/modules/./indic|'${LTPBIN%/shared}'/pango/modules/indic|' $modules_file
	sed -i 's|/builddir/build/BUILD/pango-'$version'/modules/./arabic|'${LTPBIN%/shared}'/pango/modules/arabic|' $modules_file
}

function run_test()
{
        pushd $TESTS_DIR &>/dev/null
        TESTS=`ls -1 | grep -viw "boundaries.utf8\|pangorc"` #pangorc and boundaries.utf8 are needed by testboundaries test and should be in tests directory.
        TST_TOTAL=`echo $TESTS | wc -w`

        for test in $TESTS; do
                if [ $test == "dump-boundaries" ]
		 then
                        {
                                tc_register "Test $test"
                                ./$test testcolor >$stdout 2>$stderr # testcolor is just a file to dump-boundaries test (any file can be used in place of testcolor).
				tc_pass_or_fail $? "$test failed"
                        }
                 else
                        {
                                tc_register "Test $test"
                                ./$test >$stdout 2>$stderr
                                tc_pass_or_fail $? "$test failed"
		        }
		 fi
        done
        popd &>/dev/null
}
#
# main
#
tc_setup && \
run_test 
