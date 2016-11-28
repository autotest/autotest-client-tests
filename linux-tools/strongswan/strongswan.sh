#!/bin/bash
###########################################################################################
## Copyright 2003, 2016 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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
### File :	strongswan.sh
##
### Description: Check for kernel configs and service start of strongswan
##
### Author:	Kumuda G
############################################################################################
#cd $(dirname $0)
#LTPBIN="${LTPBIN%/shared}/strongswan"
source $LTPBIN/tc_utils.source

configs="CONFIG_XFRM_USER CONFIG_NET_KEY CONFIG_INET CONFIG_IP_ADVANCED_ROUTER CONFIG_IP_MULTIPLE_TABLES CONFIG_INET_AH CONFIG_INET_ESP CONFIG_INET_IPCOMP CONFIG_INET_XFRM_MODE_TRANSPORT CONFIG_INET_XFRM_MODE_TUNNEL CONFIG_INET_XFRM_MODE_BEET CONFIG_IPV6 CONFIG_INET6_AH CONFIG_INET6_ESP CONFIG_INET6_IPCOMP CONFIG_INET6_XFRM_MODE_TRANSPORT CONFIG_INET6_XFRM_MODE_TUNNEL CONFIG_INET6_XFRM_MODE_BEET ONFIG_IPV6_MULTIPLE_TABLES CONFIG_NETFILTER CONFIG_NETFILTER_XTABLES CONFIG_NETFILTER_XT_MATCH_POLICY "
TST_TOTAL=`echo $configs|wc -w`

function tc_check_strongswan_configs
{
	for i in $configs
	do
		tc_register "$i"
		tc_check_kconfig $i
		rc=$?
		case $rc in
		2)
			tc_fail " not present, strongswan features may not work!"
			;;
		*)
			tc_pass
			;;
		esac
	done
}
tc_setup
tc_check_strongswan_configs &&
tc_service_start_and_wait strongswan &&
tc_service_stop_and_wait strongswan
