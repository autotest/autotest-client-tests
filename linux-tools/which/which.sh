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
## File:         which.sh
##
## Description:  This program tests basic functionality of which program
##
## Author:       Athira Rajeev<atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTDIR=/opt/fiv/ltp/testcases/fivextra/which

################################################################################
# Utility functions
################################################################################

#
# local setup
#        
function tc_local_setup()
{       
	tc_exec_or_break which || return
	tc_root_or_break || exit
}

#
# cleanup
#
function tc_local_cleanup()
{
	rm -rf /usr/bin/sample
}
################################################################################
# Tesytcase functions
################################################################################

#
# test01       which command 
#
function test01()
{
	tc_register     "which command"

        touch $TCTMP/sample
        chmod +x $TCTMP/sample
        cp -r $TCTMP/sample /usr/bin/sample

	which sample &>$stdout
	tc_pass_or_fail $? "which command failed" || return    
}

#
# test02       which --all 
#
function test02()
{
	grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
        if [ $? -eq 0 ];then  # Start of OS check
                ARG_OPT="-a"
        else
                ARG_OPT="--all"
        fi

	tc_register     "which $ARG_OPT command"
	
	mkdir $TCTMP/newpath
	cp -r $TCTMP/sample $TCTMP/newpath/sample
	PATH=$PATH:$TCTMP/newpath
 
	which $ARG_OPT sample | grep -q "$TCTMP/newpath/sample" && which $ARG_OPT sample | grep -q "/usr/bin/sample"
	tc_pass_or_fail $? "which $ARG_OPT command failed" 
}

#
# test03        which read-functions command
#
function test03()
{
	tc_register     "read-function option in which command"

	cat > $TCTMP/sample.sh <<-EOF
	fname(){ 
	echo "Foo" 
	}
	fname
        declare -f | which --read-functions fname
	EOF
  
	chmod +x $TCTMP/sample.sh 
        $TCTMP/sample.sh | grep -q "echo \"Foo\"" 2>stderr
	tc_pass_or_fail $? "which failed to read function fname" 
}

#
 

################################################################################
# main
################################################################################
tc_setup
grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
if [ $? -eq 0 ];then  # Start of OS check
	TST_TOTAL=2
	test01
	test02
else
	TST_TOTAL=3
	test01
	test02
	test03
fi
