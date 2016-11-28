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
### File :       tzdata.sh                                                     ##
##
### Description: Test for tzdata package                                       ##
##
### Author:      Kingsuk Deb <kingsdeb@linux.vnet.ibm.com>                     ##
###########################################################################################

############cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/fipscheck
source $LTPBIN/tc_utils.source
TEST_DIR="${LTPBIN%/shared}/fipscheck"
required="fipshmac fipscheck prelink diff"

function tc_local_setup()
{
	tc_root_or_break
	tc_exec_or_break "$required"
	if [ -f /lib*/libfipscheck.so.1 ]; then
		tc_break_if_bad $? "fipscheck-lib is not installed properly" || return
	fi
	
	if [[ -f /usr/lib*/fipscheck/fipscheck.hmac && -f /lib*/.libfipscheck.so.1.hmac ]]; then
		tc_break_if_bad $? "cksum files are not present" || return
	fi

	## Undo prelinking of binaries required before executing fips(check/hmac) ##
	## https://bugzilla.redhat.com/show_bug.cgi?id=492953                 ##
	prelink -u -a &>/dev/null
	tc_break_if_bad $? "Undo prelink failed"

	long_bit=`getconf LONG_BIT`
	if [ "$long_bit" -eq 64 ]; then
	        cp  /usr/lib64/fipscheck/fipscheck.hmac /usr/lib64/fipscheck/fipscheck.hmac.bak
        else
	        cp  /usr/lib/fipscheck/fipscheck.hmac /usr/lib/fipscheck/fipscheck.hmac.bak
	fi
}

function tc_local_cleanup()
{
	rm -f /usr/lib*/fipscheck/fipscheck.hmac.bak 
	prelink -a &>/dev/null
}
		
function restore_cksum_file()
{
	mv /usr/lib*/fipscheck/fipscheck.hmac.bak /usr/lib*/fipscheck/fipscheck.hmac 
}

### Test fipshmac command ###
function test01()
{
	tc_register "test fipshmac"
	fipshmac /usr/bin/fipscheck >$stdout 2>$stderr 
	diff /usr/lib*/fipscheck/fipscheck.hmac /usr/lib*/fipscheck/fipscheck.hmac.bak >$stdout 2>$stderr
	RC=$?
	
	case $RC in
        0)
		tc_pass_or_fail $RC
                ;;
        2)
		tc_pass_or_fail $RC "Missing filename"
                return $RC
                ;;
        3)
		tc_pass_or_fail $RC "Cannot open the checksum file."
                return $RC
                ;;
        4)
		tc_pass_or_fail $RC "Cannot read the file to be checksummed, or the checksum computation failed."
                return $RC
                ;;
        5)
		tc_pass_or_fail $RC "Memory allocation error."
                return $RC
                ;;
        6|7)
		tc_pass_or_fail $RC "Cannot write tothe checksum file."
                return $RC
                ;;
        *)
		tc_pass_or_fail $RC "Unexpected result ${RC}."
                return $RC
                ;;
        esac

        return $RC
	restore_cksum_file
}

### Test fipscheck command ###
function test02()
{
	tc_register "test fipscheck"
	## check self ##
	fipscheck /usr/bin/fipscheck > $stdout 2>$stderr
	RC=$?

	case $RC in
        0)
		tc_pass_or_fail $RC
                ;;
        1)
		tc_pass_or_fail $RC "Checksum mismatch."
                return $RC
                ;;
        2)
		tc_pass_or_fail $RC "Missing filename."
                return $RC
                ;;
        3)
		tc_pass_or_fail $RC "Cannot open the checksum file."
                return $RC
                ;;
        4)
		tc_pass_or_fail $RC "Cannot read the file to be checksummed, or the checksum computation failed."
                return $RC
                ;;
        5)
		tc_pass_or_fail $RC "Memory allocation error."
                return $RC
                ;;
        6|7)
		tc_pass_or_fail $RC "Cannot write tothe checksum file."
                return $RC
                ;;
        1[0-9])
		tc_pass_or_fail $RC "Failure during self-checking the libfipscheck.so shared library."
                return $RC
                ;;
        2[0-9])
		tc_pass_or_fail $RC "Failure during self-checking the fipscheck binary."
                return $RC
                ;;
        *)
		tc_pass_or_fail $RC "Unexpected result ${RC}."
                return $RC
                ;;
        esac

        return $RC
}


### main ###
RC=0
tc_setup
tc_run_me_only_once # as Description.xml has two packages in AUTO
TST_TOTAL=2
test01 
test02 
