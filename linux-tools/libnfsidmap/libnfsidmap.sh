#!/bin/sh
###########################################################################################
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
## File:         libnfsidmap.sh
##
## Description:  This program tests basic functionality of libnfsidmap
##
## Author:       Ramya BS <ramyabs1@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/libnfsidmap
source $LTPBIN/tc_utils.source
TESTDIR=${LTPBIN%/shared}/libnfsidmap/

MYREALM="EXAMPLE.COM"
KDC_SERVER=`hostname -f`
onlyhostname=`hostname -s`
ipaddr=`hostname -i | awk '{print $1}'`
domain_name=`dnsdomainname`
required="cat chmod cut diff dnsdomainname expect grep hostname id"

#
# local setup
#
function tc_local_setup()
{
	
	#check installation and environment
	tc_root_or_break || return
        
      tc_check_package libnfsidmap
	tc_break_if_bad $? "libnfsidmap required, but not installed" || return

      tc_check_package libnfsidmap
	tc_fail_if_bad $? "krb5-server not present" || return
	

	useradd rende -p password
	useradd admin -p password
	# back up
	[ -e /etc/krb5.conf  ] && mv /etc/krb5.conf   /etc/krb5.conf.org
	[ -e /etc/krb5.keytab  ] && mv /etc/krb5.keytab  /etc/krb5.keytab.org
	[ -e /etc/idmapd.conf  ] && cp /etc/idmapd.conf   /etc/idmapd.conf.org
	[ -e /etc/exports  ] && cp /etc/exports   /etc/exports.org	
	
	tc_info "Creating configs"
	cat >> /etc/krb5.conf <<-EOF
		[logging]
			 default = FILE:/var/log/krb5libs.log
			 kdc = FILE:/var/log/krb5kdc.log
			 admin_server = FILE:/var/log/kadmind.log

		[libdefaults]
			 dns_lookup_realm = false
			 ticket_lifetime = 24h
			 renew_lifetime = 7d
			 forwardable = true
			 rdns = true
			 default_realm = EXAMPLE.COM
			 default_ccache_name = KEYRING:persistent:%{uid}

		[realms]
			EXAMPLE.COM = {
			  kdc =  $KDC_SERVER:88
			  admin_server =  $KDC_SERVER:749
			 }

			[domain_realm]
			 #.example.com = EXAMPLE.COM
			 # example.com = EXAMPLE.COM
	EOF

	#edit configuration files
	sed -i "s/#Domain = local.domain.edu/Domain=EXAMPLE.COM/g" /etc/idmapd.conf
	sed -i "s/#Nobody-User = nobody/Nobody-User = nobody/g" /etc/idmapd.conf
	sed -i "s/#Nobody-Group = nobody/Nobody-Group = nobody/g" /etc/idmapd.conf

	
	# Script to create realm EXAMPLE.COM
        cat >> $TCTMP/krb5.sh <<-EOF
	#!/usr/bin/expect -f
	set timeout 5
	proc abort {} { exit 1 }
	spawn kdb5_util create -r EXAMPLE.COM -s -W
	expect "*key:*"
	send -- "password\r"
	expect "*key to verify:*"
	send -- "password\r"
	expect eof
	EOF
	
	
	# Scripts to add Principals for nfs
	# to KDC database
	cat >> $TCTMP/kadmin.sh <<-EOF
	#!/usr/bin/expect -f
	set timeout 5
	proc abort {} { exit 1 }
	spawn kadmin.local
	expect "kadmin.local:"
	send -- "addprinc admin\r"
	expect "Enter password for principal \"admin@EXAMPLE.COM\":"
	send -- "password\r"
	expect "*password for principal \"admin@EXAMPLE.COM\":"
	send -- "password\r"
	expect "kadmin.local:"
	send -- "addprinc rende\r"
	expect "Enter password for principal \"rende@EXAMPLE.COM\":"
	send -- "password\r"
	expect "*password for principal \"rende@EXAMPLE.COM\":"
	send -- "password\r"
	expect "kadmin.local:"
	send -- "addprinc -randkey host/$KDC_SERVER\r"
	expect "kadmin.local:"
	send -- "addprinc -randkey host/$ipaddr\r"
	expect "kadmin.local:"
	send -- "ktadd host/$KDC_SERVER\r"
	expect "kadmin.local:"
	send -- "ktadd host/$ipaddr\r"
	expect "kadmin.local:"	
	send -- "addprinc -randkey nfs/$KDC_SERVER\r"
	expect "kadmin.local:"
	send -- "addprinc -randkey nfs/$ipaddr\r"
	expect "kadmin.local:"
	send -- "ktadd nfs/$KDC_SERVER\r"
	expect "kadmin.local:"
	send -- "ktadd nfs/$ipaddr\r"
	expect "kadmin.local:"
	send -- "exit"
	expect eof
	EOF

	chmod +x $TCTMP/krb5.sh $TCTMP/kadmin.sh
	tc_exec_or_break $required || return
	

	$TCTMP/krb5.sh &>$stdout
        tc_fail_if_bad $? "Failed to create EXAMPLE.COM realm" || return
	
	sleep 120
	$TCTMP/kadmin.sh &>$stdout
        tc_fail_if_bad $? "Failed to create principal for KDC database" || return
		
	tc_service_restart_and_wait kadmin
	tc_fail_if_bad $? "Failed to start kadmin" || return
	
	tc_service_restart_and_wait ntpd
	tc_fail_if_bad $? "Failed to start ntpd" || return

	tc_service_restart_and_wait krb5kdc
	tc_fail_if_bad $? "Failed to start krb5kdc" || return

	tc_info "Prepare and export the nfs partition"
        # Create regular file ext3.img
        dd if=/dev/zero of=ext3.img bs=1 count=10MB 1>$stdout 2>$stderr
        tc_break_if_bad_rc $? "dd command failed" || return

        img=`losetup --show -f ext3.img` 1>$stdout 2>$stderr
        tc_break_if_bad_rc $? "losetup failed" || return
        # Put ext3 filesystem
        mkfs.ext3 -F $img 1>$stdout 2>$stderr
        tc_break_if_bad_rc $? "mkfs.ext3 failed" || return
	

        #enable secure NFS
        echo SECURE_NFS="yes" >> /etc/sysconfig/nfs
	
        # Update /etc/exports with nfs directory
        echo "/mnt/NFS_PARTITION/ $ipaddr(rw,no_root_squash,sec=krb5)" >> /etc/exports
        mkdir -p /mnt/NFS_PARTITION
        chmod  777 /mnt/NFS_PARTITION

        # mount the partition to be exported
        mount -o loop $img /mnt/NFS_PARTITION 1>$stdout 2>$stderr
        tc_break_if_bad_rc $? "Failed to mount nfs directory" || return


	systemctl restart rpcbind nfs-server nfs-lock nfs-idmap nfs-client.target
        tc_fail_if_bad $? "failed to start the nfs related services" || return
	
	tc_service_restart_and_wait nfs
        tc_fail_if_bad $? "failed to start the nfs" || return
        mount -t nfs4 -vvv -o sec=krb5 $ipaddr:/mnt/NFS_PARTITION/ /mnt 1>$stdout 2>$stderr
        tc_fail_if_bad $? "Failed to mount the exported NFS directory" || return


}

function tc_local_cleanup()
{

        # Restore the krb5 configuration files
        [ -e /etc/krb5.keytab.org  ] && mv /etc/krb5.keytab.org  /etc/krb5.keytab
        [ -e /etc/idmapd.conf.org  ] && mv /etc/idmapd.conf.org  /etc/idmapd.conf
	[ -e /etc/exports.org  ] && mv /etc/exports.org /etc/exports


        # unmount the NFS directory
        tc_service_stop_and_wait nfs
        tc_service_stop_and_wait nfs-secure
	tc_service_stop_and_wait nfs-secure-server
	umount /mnt
        umount /mnt/NFS_PARTITION
        rm -f $TESTDIR/ext3.img
        losetup -d $img 1>$stdout 2>$stderr
	kdb5_util destroy -f 1>$stdout 2>$stderr

        #delete users test, admin
        id -u rende
        if [ $? -eq 0 ];
        then
                userdel -r rende
        fi
        id -u admin
        if [ $? -eq 0 ];
        then
                userdel -r admin
        fi
}




# Function:             runtest
#               This executes tests that comes with source
function runtest()
{
	tc_register "libnfsidmap test"
	pushd $TESTDIR >$stdout 2>$stderr
	./libtest admin@EXAMPLE.COM  rende@EXAMPLE.COM 1>$stdout 2>$stderr
	tc_pass_or_fail $? "libnfsidmap test"
	popd >$stdout 2>$stderr

}

####################################################################################
# MAIN
####################################################################################

# Function: main
TST_TOTAL=1
tc_setup
runtest

