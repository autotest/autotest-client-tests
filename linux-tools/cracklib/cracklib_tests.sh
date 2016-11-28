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
## File :        cracklib_tests.sh
##
## Description:  This program tests basic functionality of cracklib library
##
## Author:       Manoj Iyer  manjo@mail.utexas.edu
###########################################################################################

BAD_PASS=1  # password provided is bad
DICT_PASS=he11o # to test dictionary password

# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/cracklib
source $LTPBIN/tc_utils.source

###########################################################################
# the testcase functions
###########################################################################

#
# test01    Installation check
#
test01()
{
    tc_register "installation check"
    tc_executes mkdict packer create-cracklib-dict cracklib-check
    tc_pass_or_fail $? "cracklib not properly installed"
}

#
# test02    create dictionary
#
test02()
{
    tc_register "create dictionary"

    DICTDIR=$TCTMP/crack_dict
    mkdir -p $DICTDIR &>/dev/null
    cat > $DICTDIR/tst_cracklib.txt <<-EOF
cracktestpasswd
crack_test_1
$DICT_PASS
crackpasswd
passwdforcrack
EOF

    # create $DICTDIR/tst_cracklib.txt.gz
    # as required by busybox version of "gzip -d".
    gzip $DICTDIR/tst_cracklib.txt
    tc_fail_if_bad $? "gzip is required by the mkdict script" || return

    mkdict $DICTDIR/tst_cracklib.txt.gz | \
    packer $DICTDIR/tst_cracklib >$stdout 2>$stderr
    tc_pass_or_fail $? "Unexpected response"
}

#
# test03    good password
#
test03()
{
    tc_register "good password"

    crack_check manjo1234 $DICTDIR/tst_cracklib >$stdout 2>$stderr
    tc_pass_or_fail $? "Unexpected response"
}

#
# test04    bad password
#
test04()
{
    tc_register "bad password"

    crack_check bad $DICTDIR/tst_cracklib >$stdout 2>$stderr
    rc=$?
    [ $rc -eq $BAD_PASS ]
    tc_pass_or_fail $? "expected rc=$BAD_PASS but got rc=$rc"
}

#
# test05    dictionary password
#
test05()
{
    tc_register "dictionary password"

    crack_check $DICT_PASS $DICTDIR/tst_cracklib >$stdout 2>$stderr
    rc=$?
    [ $rc -eq $BAD_PASS ]
    tc_pass_or_fail $? "expected rc=$BAD_PASS but got rc=$rc"
}

#
# test06        test "cracklib-check" command with bad password
#
test06()
{
    tc_register "test \"cracklib-check\" command with bad password"

    local output="$(echo "bad"|cracklib-check 2>$stderr)"
    [ "$output" == "bad: it is WAY too short" ]
    tc_pass_or_fail $? "expected \"bad: it is WAY too short\" but got $output"
}

TST_TOTAL=6
tc_setup           # standard setup

test01 || exit
test02 || exit
test03
test04
test05
test06
