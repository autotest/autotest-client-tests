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
### File :        librsvg2.sh                                                  ##
##
### Description:  librsvg is a free software SVG rendering library written as  ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/librsvg2
source $LTPBIN/tc_utils.source
LIBRSVG2_DIR="${LTPBIN%/shared}/librsvg2"
Required="rsvg-convert"

function tc_local_setup()
{
     tc_exec_or_break "$Required"

     [ -f  /usr/lib*/librsvg-2.so.2 ]
     tc_break_if_bad $? "librsvg2  not installed"
}

function run_tests()
{
     
    pushd $LIBRSVG2_DIR >$stdout 2>$stderr
    tc_register "Testing perceptualdiff" 
    #PerceptualDiff is an image comparison utility that makes use of a computational 
    #model of the human visual system to compare two images
    ./tests/perceptualdiff example.png example.png >$stdout 2>$stderr
    tc_pass_or_fail $? "perceptualdiff test failed"

    tc_register "Test: convert SVG file to PNG file"
    #Convert an SVG file to png file with width of 200
    rsvg-convert --width=200 svg-viewer.svg -o rsvg.png && file rsvg.png | grep -q PNG >$stdout 2>$stderr
    tc_pass_or_fail $? "Test Failed: convert SVG file to PNG file"

    tc_register "Test: convert SVG file to PS file"
    #Convert an SVG file to ps file by using the option --format
    rsvg-convert --format=ps svg-viewer.svg -o rsvg.ps && file rsvg.ps | grep -q PostScript >$stdout 2>$stderr
    tc_pass_or_fail $? "Test Failed: convert SVG file to PS file"

    tc_register "Test: convert SVG file to PDF file"
    #Convert an SVG file to pdf file using the option --format
    rsvg-convert --background-color=blue --format=pdf svg-viewer.svg -o rsvg.pdf && \
    file rsvg.pdf | grep -q PDF >$stdout 2>$stderr
    tc_pass_or_fail $? "Test Failed: convert SVG file to PDF file"

    popd >$stdout 2>$stderr

}

#############################################################################################
# main
#############################################################################################

TST_TOTAL=4
tc_setup && run_tests
