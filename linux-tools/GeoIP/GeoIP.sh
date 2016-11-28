#!/bin/sh
############################################################################################
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
## File :        GeoIP.sh
##
## Description:  Test GeoIP package.
##
## source the utility functions
## Author:       Poornima Nayak      mpnayak@linux.vnet.ibm.com
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/GeoIP
source $LTPBIN/tc_utils.source
REQUIRED="geoiplookup geoiplookup6 geoipupdate"
ip=$(grep dns.au.example.com /etc/hosts | awk '{print $1}')

TESTS_DIR="${LTPBIN%/shared}/GeoIP/"

function tc_local_setup()
{
    # check installation and environment
    [ -f /usr/lib*/libGeoIP.so.1 ] && [ -f /usr/lib*/libGeoIPUpdate.so.0 ]
    tc_break_if_bad $? "GeoIP not installed"
    tc_exec_or_break $REQUIRED || return
    pushd $TESTS_DIR &>/dev/null
    mkdir -p /usr/local/share/GeoIP
    cp /usr/share/GeoIP/GeoIP-initial.dat /usr/local/share/GeoIP/GeoIP.dat
    cp /usr/local/share/GeoIP/GeoIP.dat $TESTS_DIR/data
    tc_break_if_bad $? "GeoIP test setup failed"
    popd &>/dev/null
}

function tc_local_cleanup()
{   
    rm -rf /usr/local/share/GeoIP
    rm -rf test/data
}

function test_geoiplookup()
{
    tc_register "GeoIPLookup $test"
    #Since this test fails in kvm guest as the ip is a private one
    #using IP of dns.au.example.com which belongs to IBM registered in US is pretty
    #enough for testing this
    op=`geoiplookup $ip`
    [ "$op" == "GeoIP Country Edition: US, United States" ] 
    tc_pass_or_fail $? "Test geoiplookup failed"
}
    
#
# main
#

TST_TOTAL=1
tc_setup
pushd $TESTS_DIR/test &>/dev/null
test_geoiplookup
popd &>/dev/null
tc_local_cleanup
