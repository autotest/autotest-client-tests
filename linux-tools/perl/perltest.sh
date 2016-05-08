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
## File :        perltest.sh
##
## Description:  Test suite to exhaustively test perl
##
## Author:       Robb Romans <robb@austin.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TEST_DIR="${LTPBIN%/shared}/perl/t"	# directory for individual testcases
# required executables
REQUIRED="perl"

function tc_local_setup()
{
	ln -sf /usr/bin/perl ${TEST_DIR}/perl
    mkdir ${TEST_DIR}/../lib

    # Making use of modules provided by perl rpm rather than those in source tarball
    for mod in `ls /usr/share/perl5` ; do
                cp -Rf /usr/share/perl5/$mod ${TEST_DIR}/../lib/
        done
        for mod in `ls /usr/lib*/perl5` ; do
                cp -Rf /usr/lib*/perl5/$mod ${TEST_DIR}/../lib/
        done

        # Some of the perl modules provided by different perl packagesare in different dir, getting them to one dir.
        cp -r ${TEST_DIR}/../lib/vendor_perl/* ${TEST_DIR}/../lib/ 
}

function tc_local_cleanup()
{
	rm -f ${TEST_DIR}/perl
        rm -rf ${TEST_DIR}/../lib 
}

################################################################################
# testcase functions
################################################################################

#
# Function run_tests
#
# Description	- run all perl standard testcases
#
# Return	- zero on success
#		- return value from testcase on failure ($RC)
function run_tests()
{
     pushd $TEST_DIR &>/dev/null
     TESTS=`find . -name *.t`
     TST_TOTAL=`echo $TESTS | wc -w` 
	local PERL_ARGUMENT=""

	local test
	local name
    for test in $TESTS ; do 
		name="`basename $test`"	
		tc_register "$name"
                PERL_ARGUMENT=`(head -n 1 $test | grep ".*\/*perl" | sed -e 's|.*\/*perl||')`
		if [ "$name" == "globvar.t" ] 
		then
			( cd ../ ; perl $PERL_ARGUMENT t/$test &>$stdout ; cd t/ ) 
		else
			perl $PERL_ARGUMENT $test &>$stdout
       	              rc=$?
        	    if [ $rc -ne 0 ] ; then
	            # Supressing win32 related errors
        	    # Excluding check for some of the missing CPAN and test related modules
	                if [ ` egrep -o "win32|FindExt.t|Simple.pm|OSType.pm|APItest.pm|SHA.pm|Checker.pm|More.pm|Maintainers.pm|version.pm|TestInit.pm" $stdout` ]; then
                	    rc=0
        	        fi
	            fi 
		fi
		tc_pass_or_fail $rc
		rm -f $name.out
	done
	popd &>/dev/null 
}

################################################################################
# main
################################################################################

# Function:	main
#
# Description:  Execute all tests, report results
#
# Exit:         zero on success
#               non-zero on failure
tc_setup
tc_exec_or_break $REQUIRED || exit
tc_info "Setting up perl test environment"

PERL_VER=`rpm -qv perl|cut -d"-" -f2` 
tc_info "PERL_VERSION = $PERL_VER"

run_tests
 
################################################################################
