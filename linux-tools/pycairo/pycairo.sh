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
## File :    pycairo.sh
##
## Description:    Tests for pycairo package.
##
## Author:    Gowri Shankar <gowrishankar.m@in.ibm.com>
###########################################################################################
## source the utility functions

#cd $(dirname $0)
#LTPBIN="${PWD%%/testcases/*}/testcases/bin"
PYCAIRO="${LTPBIN%/shared}/pycairo/"
source $LTPBIN/tc_utils.source

################################################################################
# test variables
################################################################################
required="python convert"

################################################################################
# test functions
################################################################################
function tc_local_setup()
{
    # check installation and environment
    tc_root_or_break || return
    tc_exec_or_break $required || return

}

function tc_local_cleanup()
{
        rm -f $PYCAIRO/tests/*.png
        rm -f $PYCAIRO/tests/cairo_snippets/*.png
        rm -f $PYCAIRO/tests/cairo_snippets/*.pdf
        rm -f $PYCAIRO/tests/cairo_snippets/*.svg
        rm -f $PYCAIRO/tests/cairo_snippets/*.ps
}

#
# Run pycairo tests
#
function test_pycairo()
{
	pushd $PYCAIRO/tests &>/dev/null
	local size=""

	tc_register "test gradient"
	python gradient.py 1>$stdout 2>$stderr
	size=$(convert gradient.png -print "%wx%h\n" /dev/null)
	[ "$size" = "256x256" ]
	tc_pass_or_fail $? "gradient test fails"

	tc_register "test hering"
	python hering.py 1>$stdout 2>$stderr
	size=$(convert hering.png -print "%wx%h\n" /dev/null)
	[ "$size" = "300x600" ]
	tc_pass_or_fail $? "hering test fails"

	tc_register "test spiral"
	python spiral.py 1>$stdout 2>$stderr
	size=$(convert spiral.png -print "%wx%h\n" /dev/null)
	[ "$size" = "600x600" ]
	tc_pass_or_fail $? "spiral test fails"

	tc_register "test warpedtext"
	python warpedtext.py 1>$stdout 2>$stderr
	size=$(convert warpedtext.png -print "%wx%h\n" /dev/null)
	[ "$size" = "512x512" ]
	tc_pass_or_fail $? "warpedtext test fails"

	cd cairo_snippets
	tc_register "test snippets_pdf"
	python snippets_pdf.py 1>$stdout 2>$stderr
	[ $(grep -vc processing $stdout) -eq 0 ]
	tc_pass_or_fail $? "pdf tests failed"

	tc_register "test snippets_png"
	python snippets_png.py 1>$stdout 2>$stderr
	[ $(grep -vc processing $stdout) -eq 0 ]
	tc_pass_or_fail $? "png tests failed"

	tc_register "test snippets_ps"
	python snippets_ps.py 1>$stdout 2>$stderr
	[ $(grep -vc processing $stdout) -eq 0 ]
	tc_pass_or_fail $? "ps tests failed"

	tc_register "test snippets_svg"
	python snippets_svg.py 1>$stdout 2>$stderr
	[ $(grep -vc processing $stdout) -eq 0 ]
	tc_pass_or_fail $? "svg tests failed"

	popd &>/dev/null
}

################################################################################
# main
################################################################################
TST_TOTAL=8
tc_setup
test_pycairo 
