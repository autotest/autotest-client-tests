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
### File : perl-DBI                                                            ##
##
### Description: This testcase tests perl-DBI package                          ##
##
### Author:      Sheetal Kamatar <sheetal.kamatar@in.ibm.com>                  ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/perl_DBI
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/perl_DBI"
REQUIRED="perl rpm"
function tc_local_setup()
{
    tc_exec_or_break $REQUIRED
    # Removing the blib directory usage from the script so that the script uses modules installed in system rather than the modules present in source
    cp $TESTDIR/t/85gofer.t $TESTDIR/t/85gofer.t.bkp
    sed "s:-Mblib=\$getcwd\/blib::g" -i $TESTDIR/t/85gofer.t
    # Providing the absolute path for dbiproxy
    ln -s `which dbiproxy` $TESTDIR/dbiproxy
}

function install_check()
{
        tc_register "Installation check"
      tc_check_package perl-DBI
        tc_pass_or_fail $? "perl-DBI not installed"
}

function tc_local_cleanup()
{
	rm $TESTDIR/dbiproxy
}


function runtests()
{
	pushd $TESTDIR >$stdout 2>$stderr
	TESTS=`ls t/*.t`
	TST_TOTAL=`echo $TESTS | wc -w`
	for test in $TESTS; do
		# Enabling tainting checks for certain tests
		echo $test |grep -E 'taint|coverage' > $stdout
		if [ $? -eq 0 ] ; then
			tc_register "Test -T $test"
			perl -T $test &>stdout
			tc_pass_or_fail $? "test failed"
		else
			tc_register "Test $test"
			perl $test &>$stdout
			tc_pass_or_fail $? "$test failed"
		fi
	done
	popd >$stdout 2>$stderr
}

#
#MAIN
#
tc_setup
install_check &&
runtests
