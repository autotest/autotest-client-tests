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
## File:         ttmkfdir.sh
##
## Description:  This program tests ttmkfdir
##
## Author:       Athira Rajeev>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/ttmkfdir
source $LTPBIN/tc_utils.source

################################################################################
# Utility functions
################################################################################

#
# local setup
#        
function tc_local_setup()
{       
	rpm -q ttmkfdir 1>$stdout 2>$stderr
	tc_break_if_bad $? "ttmkfdir not installed" || return

	TRUETYPE_DIR=`find /usr/share -name truetype`
	TRUETYPE_DIR_FONTFILE=`find $TRUETYPE_DIR -name *.ttf`
	set $TRUETYPE_DIR_FONTFILE
	FONT_FILE=$1
}

function runtest()
{
	#Create truetype font directory for testing
	# and copy true-type font file to that
	mkdir $TCTMP/truetype
	cp $FONT_FILE $TCTMP/truetype/

	pushd $TCTMP/truetype &>/dev/null

	tc_register "ttmkfdir -o"

	ttmkfdir -o fonts.dir >$stdout 2>$stderr
	tc_fail_if_bad $? "ttmkfdir -o failed" || return

    #Verify fonts.dir exists
	[ -s $TCTMP/truetype/fonts.dir ]
	tc_fail_if_bad $? "ttmkfdir failed to create fonts.dir" || return

    #Verify fonts.dir has valid entries not zero
	Entries=`head -1 fonts.dir`
	[ $Entries -gt 0 ]
	tc_pass_or_fail $? "ttmkfdir failed to generate entries"

	popd &>/dev/null

	tc_register "ttmkfdir -d"
	ttmkfdir -d $TCTMP/truetype -o $TCTMP/truetype/fonts.scale >$stdout 2>$stderr
	tc_fail_if_bad $? "ttmkfdir -d failed" || return

    #Verify fonts.dir and fonts.scale has same contents
	diff -Naurp $TCTMP/truetype/fonts.scale $TCTMP/truetype/fonts.dir
	[ $? -eq 0 ] && [ -s $TCTMP/truetype/fonts.scale ] 
	tc_pass_or_fail $? "ttmkfdir -d failed to create fonts.scale for truetype font"

	pushd $TCTMP/truetype &>/dev/null

    #with -x, ttmkfdir generate extra XLFDs
    #and for XTT-backend generates extra TTCaps stuff
	tc_register "ttmkfdir -b 1 -x"
	ttmkfdir -b 1 -o fonts-xft.dir >$stdout 2>$stderr
	tc_fail_if_bad $? "ttmkfdir -b failed" || reutn

	typeset -i entrieswithoutx=`head -1 fonts-xft.dir`

	ttmkfdir -b 1 -x 1 -o fonts-x-xft.dir >$stdout 2>$stderr
	tc_fail_if_bad $? "ttmkfdir -b -x failed" || return

	typeset -i entrieswithx=`head -1 fonts-x-xft.dir`

	[ $entrieswithx -gt $entrieswithoutx ]
	tc_pass_or_fail $? "ttmkfdir -x failed to generate extra XLFDs" 

	tc_register "ttmkfdir -b 2 x"

	ttmkfdir -b 2 -x 1 -o fonts-xtt.dir >$stdout 2>$stderr
	tc_fail_if_bad $? "ttmkfdir -b -x failed for XTT-backend" || return

	[ `grep -E "ai=|ds=|bw=" fonts-xtt.dir | wc -l` -gt 0 ]
	tc_pass_or_fail $? "ttmkfdir -b -x failed  to generate extra TTCaps stuff"

	tc_register "ttmkfdir -m"
	ttmkfdir -m 10 -d $TCTMP/truetype -o $TCTMP/truetype/fonts-m.dir >$stdout 2>$stderr
	tc_fail_if_bad $? "ttmkfdir -m failed" || return
	
	[ -s $TCTMP/truetype/fonts-m.dir ]
        tc_fail_if_bad $? "ttmkfdir failed to create fonts-m.dir" || return

        #Verify fonts-m.dir doesnt have zero entries
        Entries=`head -1 fonts-m.dir`
        [ $Entries -gt 0 ]
        tc_pass_or_fail $? "ttmkfdir failed to generate entries using -m"

	popd &>/dev/null
}

################################################################################
# MAIN
#
###############################################################################
#
tc_setup
TST_TOTAL=5
runtest
