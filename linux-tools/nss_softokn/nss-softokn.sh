#!/bin/sh
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
## File :        nss-softokn.sh                                               ##
##
### Description:  Tests for nss-softokn package                                ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/nss_softokn
source $LTPBIN/tc_utils.source
NSS_SOFTOKN_TEST_DIR="${LTPBIN%/shared}/nss_softokn/test"
Required="perl"

#Individual set of tests
nss_tests1="bbsrand  mptest1 mptestb"
nss_tests2="mptest4b mptest6"
nss_tests3="mptest2 mptest3 mptest3a mptest4a"
nss_tests4="mptest4"
numb1=8
numb2=9
numb3=10
TOTAL=$(echo $nss_tests1|wc -w)
TOTAL1=$(echo $nss_tests2|wc -w)
TOTAL2=$(echo $nss_tests3|wc -w)
TOTAL3=$(echo $nss_tests4|wc -w)
TST_TOTAL=$((TOTAL + TOTAL1 + TOTAL2 + TOTAL3))

function tc_local_setup()
{
    tc_exec_or_break $Required
}

function test_softokn()
{
   
    pushd $NSS_SOFTOKN_TEST_DIR &> /dev/null

     #Run tests which do not expect any arguments
     for test in $nss_tests1
     do
          tc_register "Test $test"
          ./$test >$stdout 2>$stderr
          tc_pass_or_fail $? "$test failed"
     done
   
         #Run the tests which requires atleast 1 argument
     for test in $nss_tests2
     do
             tc_register "Test $test"
             ./$test $numb1>$stdout 2>$stderr
             tc_pass_or_fail $? "$test failed"
     done


     #Run the tests which requires 2 arguments
         for test in $nss_tests3
     do
             tc_register "Test $test"
             ./$test $numb1 $numb2 >$stdout 2>$stderr
             tc_pass_or_fail $? "$test failed"
     done
   
         #Run the tests which requires 3 arguments
         for test in $nss_tests4
     do
             tc_register "Test $test"
             ./$test $numb1 $numb2 $numb3 >$stdout 2>$stderr
             tc_pass_or_fail $? "$test failed"
     done

   popd  &> /dev/null
}

############################################################################
## main
############################################################################
tc_setup && \
test_softokn
