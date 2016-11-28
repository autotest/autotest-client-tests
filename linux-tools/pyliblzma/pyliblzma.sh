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
### File : pyliblzma                                                           ##
##
### Description: This testcase tests pyliblzma package                         ##
##
### Author:      Athira Rajeev <atrajeev@in.ibm.com>   	                      ##
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/pyliblzma
source $LTPBIN/tc_utils.source
FIVDIR="${LTPBIN%/shared}/pyliblzma"
REQUIRED="python"
function tc_local_setup()
{
	tc_exec_or_break $REQUIRED
	rpm -q pyliblzma >$stdout 2>$stderr
	tc_fail_if_bad $? "pyliblzma not installed" || return
}

function runtests()
{
	pushd $FIVDIR >$stdout 2>$stderr
	tc_register "Running pyliblzma tests"
	python tests/test_liblzma.py  1>$stdout 2>$stderr
	RC=$?
	grep -q FAILED $stdout
	if [ $? -eq 0 ]; then
		tc_fail "test_liblzma.py failed with FAILED in stdout"
	else
		cat /dev/null > $stderr
		tc_pass_or_fail $RC "pyliblzma tests failed"
	fi
	popd >$stdout 2>$stderr
}

#
#MAIN
#
tc_setup
runtests
