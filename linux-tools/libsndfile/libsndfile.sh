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
### File :        libsndfile.sh                                                ##
##
### Description:  Libsndfile is a library designed to allow the reading and    ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libsndfile
source $LTPBIN/tc_utils.source
LIBSNDFILE_TEST_DIR="${LTPBIN%/shared}/libsndfile/"
Required="sndfile-cmp sndfile-convert sndfile-info sndfile-metadata-get sndfile-metadata-set" 

function tc_local_setup()
{
     tc_exec_or_break "$Required" 
     tc_exist_or_break /usr/lib*/libsndfile.so.1 || return
     # Pedantic-header-test.sh requires gcc to be installed. Hence removing that test from test_wrapper.sh
     sed -i '/pedantic-header-test/d' $LIBSNDFILE_TEST_DIR/tests/test_wrapper.sh
}

function run_tests()
{
    pushd $LIBSNDFILE_TEST_DIR/tests &> /dev/null
    tc_register "testing libsnd tests with different types of files"
    ./test_wrapper.sh >$stdout 2>$stderr  
    tc_pass_or_fail $? "tests failed" 
    popd &> /dev/null
}

#Below tests covers the binaries of libsndfile

# compares two audio files using sndfile-cmp command
function test01()
{
   pushd $LIBSNDFILE_TEST_DIR &> /dev/null
   tc_register "test sndfile-cmp" 
   sndfile-cmp receive.wav alert.wav >$stdout 2>$stderr
   grep -q differ $stdout 
   tc_pass_or_fail $? "sndfile-cmp test failed"
}

#display basic information about a sound file using sndfile-info command
function test02()
{
   tc_register "test sndfile-info"
   sndfile-info receive.wav >$stdout 2>$stderr
   grep -q WAVE_FORMAT $stdout
   tc_pass_or_fail $? "sndfile-info test failed"
}

#converts sound files from one format to another using sndfile-convert command
function test03()
{
    tc_register "test sndfile-convert"
    sndfile-convert -override-sample-rate=10 -dwvw16 alert.wav $TCTMP/alertme.aif && file $TCTMP/alertme.aif >$stdout 2>$stderr
    grep -q AIFF-C $stdout
    tc_pass_or_fail $? "sndfile-convert test failed"
}

#set metadata in a sound file using sndfile-metadata-set
function test04()
{
   tc_register "test sndfile-metadata-set"     
   sndfile-metadata-set --str-title wav-file alert.wav >$stdout 2>$stderr
   tc_pass_or_fail $? "sndfile-metadata-set test failed"
}

#retrieve metadata from a sound file using sndfile-metadata-get
function test05()
{
   tc_register "test sndfile-metadata-get"
   sndfile-metadata-get --str-title alert.wav >$stdout 2>$stderr
   grep -q wav-file $stdout
   tc_pass_or_fail $? "sndfile-metadata-get test failed"
   popd &> /dev/null
}

#
#################################################################################
# main
#################################################################################

tc_setup 
TST_TOTAL=6
run_tests
test01
test02
test03
test04
test05
