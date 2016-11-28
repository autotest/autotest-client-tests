#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
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
## File :        ligogg.sh                			                           ##
##	
## Description: This testcase tests libogg package    			                   ##
##
## Author: Hariharan T.S. <harihare@in.ibm.com>                             	   ##
###########################################################################################

#######cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/libogg
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/libogg"
output="tempout"


function tc_local_setup()
{
	TST_TOTAL=1	
}

################################################################################
# testcase functions                                                           #
################################################################################
#
# Function:             runtests
#
# Description:          - test libogg
#
# Parameters:           - none
#
# Return                - zero on success
#                       - return value from commands on failure
################################################################################

function runtests()
{
    pushd $TESTS_DIR &>/dev/null
    TESTS=`find ./libogg_tests -maxdepth 1 -type f -perm -111`
    TST_TOTAL=`echo $TESTS | wc -w`
    for test in $TESTS; do
        tc_register "Test $test"
        $test >$stdout 2>$stderr
	RC=$?
	grep -iq "fail" $stderr
	RC1=$?
	if [ $RC -eq 1 ] || [ $RC1 -eq 0 ] 
	then
		RC=1
	else
		tc_ignore_warnings "^$\|Small preclipped packing (LSb): ok.\|Null bit call (LSb): ok.\|Large preclipped packing (LSb): ok.\|32 bit preclipped packing (LSb): ok.\|Small unclipped packing (LSb): ok.\|Large unclipped packing (LSb): ok.\|Single bit unclipped packing (LSb): ok.\|Testing read past end (LSb): ok.\|Small preclipped packing (MSb): ok.\|Null bit call (MSb): ok.\|Large preclipped packing (MSb): ok.\|32 bit preclipped packing (MSb): ok.\|Small unclipped packing (MSb): ok.\|Large unclipped packing (MSb): ok.\|Single bit unclipped packing (MSb): ok.\|Testing read past end (MSb): ok.\|testing single page encoding\|testing basic page encoding\|testing basic nil packets\|testing initial-packet lacing > 4k\|testing single packet page span\|testing page spill expansion\|testing max packet segments\|testing very large packets\|testing continuation resync in very large packets\|testing zero data page (1 nil packet)\|Testing loss of pages\|Testing loss of pages (rollback required)\|Testing sync on partial inputs\|Testing sync on 1+partial inputs\|Testing search for capture\|Testing recapture" 
        fi
	tc_pass_or_fail $RC "Test $test failed"
    done
    popd &>/dev/null
}



##############################################
#MAIN                                        #
##############################################
TST_TOTAL=1
tc_setup
runtests

