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
### File :        poppler.sh                                                   ##
##
### Description:  The Poppler package contains a PDF rendering library and     ##
##
### Author:       Anitha MallojiRao amalloji@in.ibm.com                        ##
###########################################################################################
## source the utility functions

######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/poppler
source $LTPBIN/tc_utils.source
POPPLER_TEST_DIR="${LTPBIN%/shared}/poppler/tests"

function tc_local_setup()
{
      tc_check_package poppler
        tc_break_if_bad $? "poppler not installed" 
}

function run_popplertest()
{
   pushd $POPPLER_TEST_DIR &> /dev/null
   TESTS="pdffonts  pdf-fullrewrite  pdfimages  pdfinfo pdftohtml  pdftoppm  pdftops  pdftotext  perf-test"
  
   TST_TOTAL=`echo $TESTS | wc -w` 
    
   #Copying sample.pdf to rewrite.pdf
   tc_register "pdf-full rewrite"
   ./pdf-fullrewrite ../sample.pdf $TCTMP/rewrite.pdf && file $TCTMP/rewrite.pdf |grep -q PDF >$stdout 2>$stderr 
   tc_pass_or_fail $? "pdf-full rewrite failed"

   #Generate the preview of sample.pdf in text format with resolution 20x30
   tc_register "perf-test"
   ./perf-test -preview -text -resolution 20x30 ../sample.pdf >$stdout 2>$stderr
   tc_pass_or_fail $? "perf-test failed"
  
   #Analyze the fonts used in pdf 
   tc_register "pdffonts"
   ./pdffonts -f 3 -l 8 ../sample.pdf | grep -q type >$stdout 2>$stderr
   tc_pass_or_fail $? "pdffonts failed"

   #Extract the image and store it as ppm, pbm or jpeg 
   tc_register "pdfimages"
   ./pdfimages -f 1 ../sample.pdf $TCTMP/image && file $TCTMP/image* |grep -q image >$stdout 2>$stderr
   tc_pass_or_fail $? "pdfimages failed"

   #Extract the info of PDF
   tc_register "pdfinfo"
    ./pdfinfo ../sample.pdf | grep -q "PDF version" >$stdout 2>$stderr
   tc_pass_or_fail $? "pdfinfo failed"

   #Convert pdf to html
   tc_register "pdftohtml"
   ./pdftohtml -f 5 -l 6 -stdout ../sample.pdf > $TCTMP/example.html && file $TCTMP/example.html |grep -q HTML >$stdout 2>$stderr
   tc_pass_or_fail $? "pdftohtml failed"

   #Convert pdf to ppm image
   tc_register "pdftoppm"
    ./pdftoppm -f 7 -l 8 -mono -scale-to 3 ../sample.pdf >$stdout 2>$stderr
    tc_pass_or_fail $? "pdftoppm failed"

   #Convert pdf to text
   tc_register "pdftotext"
   ./pdftotext -f 2 -l 3 -raw ../sample.pdf $TCTMP/sample.txt && file $TCTMP/sample.txt |grep -q text >$stdout 2>$stderr
   tc_pass_or_fail $? "pdftotext failed"

  #Converts pdf to level 3 seperable Postscript
  tc_register "pdftops"
  ./pdftops -level3sep ../sample.pdf $TCTMP/sample.ps && file $TCTMP/sample.ps | grep -q PostScript >$stdout 2>$stderr
  tc_pass_or_fail $? "pdftops failed"

  popd &> /dev/null 
}

#################################################################################
#         main
#################################################################################

tc_setup && \
run_popplertest
