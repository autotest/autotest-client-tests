#!/bin/bash
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##      1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##      2.Redistributions in binary form must reproduce the above copyright notice, this  ##
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
## File :	gnupg2.sh
##
## Description:	Test gnupg2 capablities. Tests ported from gpg source.
##
## Author:	Robb Romans <robb@austin.ibm.com>
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/gnupg2
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################

REQUIRED="which cmp cat ls rm make gpg"	# required executables


TESTS="armdetachm.test armsigs.test  decrypt-dsa.test  encrypt.test     
	seat.test  version.test armdetach.test clearsig.test   
	decrypt.test genkey1024.test signencrypt-dsa.test 
	armencryptp.test conventional-mdc.test  detachm.test 
	signencrypt.test armencrypt.test     
	detach.test  import.test  sigs-dsa.test armor.test 
	conventional.test  encrypt-dsa.test  mds.test  sigs.test  
	armsignencrypt.test encryptp.test  multisig.test"

# used by and for imported tests
export testdir=""	# directory for individual tests. (set by mysetup)
export srcdir=.		# directory testcases see.

################################################################################
# any utility functions specific to this file can go here
################################################################################

#
# setup specific to this file
#
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return

	# copy tests to temp directory
	cp -a ${LTPBIN%/shared}/gnupg2/gnupg2-tests $TCTMP/
	testdir=$TCTMP/gnupg2-tests/

	mkdir -p $TCTMP/g10
	ln -s $(which gpg) $TCTMP/g10
	mkdir -p $TCTMP/tools
	cp ${LTPBIN%/shared}/gnupg2/mk-tdata $TCTMP/tools
	mkdir $TCTMP/doc
	echo HACKING >$TCTMP/doc/HACKING
	echo DETAILS >$TCTMP/doc/DETAILS
	echo FAQ     >$TCTMP/doc/FAQ

	( cd $TCTMP/gnupg2-tests/ && make -f Makefile.am ) &>/dev/null
	tc_info "local setup complete"
}

################################################################################
# the testcase functions
################################################################################

#
# runtests	run the ported tests
#
function runtests()
{
	for tst in $TESTS; do
		tc_register $tst
		cd $testdir && ./$tst 1>$stdout 2>$stderr
		local -i rc=$?
		if [ $rc -eq 77 ] ; then
			let TST_TOTAL-=1
			let TST_COUNT-=1
			tc_info "$tst skipped on this platform"
		else
			tc_pass_or_fail $rc "unexpected results"
		fi
		rm -f $TCTMP/$tst.err &>/dev/null
	done
}

################################################################################
# main
################################################################################

set $TESTS
let TST_TOTAL=$#

tc_setup	# standard setup (exits if bad)

runtests
