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
### File :        gstreamer.sh                                                 ##
##
### Description:  GStreamer is a development framework for creating            ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/gstreamer
MAPPER_FILE="$LTPBIN/mapper_file"
source $LTPBIN/tc_utils.source
source  $MAPPER_FILE
TEST_DIR=${LTPBIN%/shared}/gstreamer
BENCHMARK_TEST_DIR="${LTPBIN%/shared}/gstreamer/tests/benchmark"
TEST1="caps complexity gstbufferstress gstclockstress masselements"
TOTAL1=`echo $TEST1 | wc -w`
TEST2="gst-launch gst-typefind"
TOTAL2=`echo $TEST2 | wc -w`
TST_TOTAL=$((TOTAL1 + TOTAL2))

function tc_local_setup()
{
	tc_check_package  "$GSTREAMER"
        tc_break_if_bad $? "$GSTREAMER is not installed"
}

function run_benchmarktests()
{
   pushd $BENCHMARK_TEST_DIR  &> /dev/null
   tc_register "Benchmarks for caps"
   ./caps >$stdout 2>$stderr 
   tc_pass_or_fail $? "Failed: Benchmarks for caps"

   tc_register "Benchmarks for complexity"
   ./complexity 2 4 >$stdout 2>$stderr
   tc_pass_or_fail $? "Failed: Benchmarks for complexity"

   tc_register "Benchamarks for gstbufferstress"
   ./gstbufferstress 6 5  |grep -q  "30 buffer" >$stdout 2>$stderr
   tc_pass_or_fail $? "Failed: Benchamarks for gstbufferstress"

   tc_register "Benchmarks for gstclockstress"
   ./gstclockstress 4 |grep -q "4 threads"  >$stdout 2>$stderr
   tc_pass_or_fail $? "Failed: Benchamarks for gstclockstress"

   tc_register "Benchmarks for masselements"
   ./mass-elements >$stdout 2>$stderr
   tc_pass_or_fail $? "Failed: Benchmarks for masselements"
   popd &> /dev/null
}

#Below tests covers the binaries of gstreamer

function test01()
{
    pushd $TEST_DIR  &> /dev/null
    tc_register "Testing gst-launch"
    #gst-launch builds and runs basic GStreamer pipelines

    gst-launch filesrc location=apev2-lyricsv2.mp3 |grep -q pipeline >$stdout 2>$stderr
    tc_pass_or_fail $? "Failed: Test for gst-launch"
    popd &> /dev/null
}

function test02()
{
   tc_register "Testing gst-typefind"
   #gst-typefind determines the GStreamer type of the given file"
   #Displaying  the Command Name

   gst-typefind --print |grep -q bin >$stdout 2>$stderr
   tc_pass_or_fail $? "Failed: Test for gst-typefind"
}

#################################################################################
#         main
#################################################################################

tc_setup 
run_benchmarktests
test01
test02
