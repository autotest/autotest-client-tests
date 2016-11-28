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
## File :	popt.sh
##
## Description:	Tests for popt
##
## Author:	Suzuki K P <suzukikp@in.ibm.com>
###########################################################################################

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/popt
builddir=${LTPBIN%/shared}/popt/popt-tests

source $LTPBIN/tc_utils.source

run() {
    prog=$1; shift
    name=$1; shift
    answer=$1; shift

    tc_register "test $name"

    result=`$builddir/$prog $*`
    if [ "$answer" != "$result" ]; then
	tc_fail "Test \"$*\" failed with: \"$result\" != \"$answer\" "
    else
	tc_pass
    fi
}

run_diff() {
    prog=$1; shift
    name=$1; shift
    in_file=$1; shift
    answer_file=$1; shift

    out=$builddir/tmp.out
    diff_file=$builddir/tmp.diff

    tc_register "test $name."

    $builddir/$prog $in_file > $out
    ret=$?
    diff $out $answer_file > $diff_file
    diff_ret=$?

    if [ "$diff_ret" != "0" ]; then
       tc_fail "Test \"$name\" failed output is in $out, diff is:" \
	$(cat $diff_file)
    else
	tc_pass
    fi
    rm $out $diff_file
}

[ -z "$srcdir" ] && srcdir=$builddir
cd ${srcdir}
test1=${builddir}/test1

tc_setup 60	# This should finish way under 60 seconds
tc_info "Running tests in `pwd`"

source $builddir/testit.sh
