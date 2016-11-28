#!/bin/sh
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
### File :       authconfig-test.sh                                            ##
##
### Description: This testcase tests authconfig package                        ##
##
### Author:      Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                      ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/authconfig
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/authconfig"

required="authconfig authconfig-tui cacertdir_rehash"

function tc_local_setup()
{
        tc_root_or_break || return
        tc_exec_or_break $required || return
        tc_add_user_or_break
}

function test_save_backup()
{
	tc_register "test --savebackup"
	authconfig --savebackup=$TCTMP/authconfig-backup 1>$stdout 2>$stderr
	tc_pass_or_fail $? "test --savebackup failed"
}

function test_passwd()
{
	tc_register "test --disableshadow"
	authconfig --disableshadow --update 1>$stdout 2>$stderr
	grep "USESHADOW" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disableshadow failed"

	tc_register "test --enableshadow"
	authconfig --enableshadow --update 1>$stdout 2>$stderr
	grep "USESHADOW" /etc/sysconfig/authconfig | grep -q "yes"
	tc_pass_or_fail $? "test --enableshadow failed" || return

	tc_register "test --enablemd5"
	authconfig --enablemd5 --update 1>$stdout 2>$stderr
	grep "PASSWDALGORITHM" /etc/sysconfig/authconfig | grep -q "md5"
	tc_pass_or_fail $? "test --enablemd5 failed"

	tc_register "test --disablemd5"
	authconfig --disablemd5 --update 1>$stdout 2>$stderr
	grep "PASSWDALGORITHM" /etc/sysconfig/authconfig | grep -q "descrypt"
	tc_pass_or_fail $? "test --disablemd5 failed"

	# Test setting of passwd algos
	local passwd_algo="descrypt bigcrypt md5 sha256 sha512"
	for algo in $passwd_algo; do
		tc_register "test --passalgo $algo"	
		authconfig --passalgo=$algo --update 1>$stdout 2>$stderr
		grep "PASSWDALGORITHM" /etc/sysconfig/authconfig | grep -q "$algo"
		tc_pass_or_fail $? "test --passalgo $algo failed"
	done
}

function test_nis()
{
	tc_register "test --enablenis"
	authconfig --enablenis --update 1>$stdout 2>$stderr
	grep "USENIS" /etc/sysconfig/authconfig | grep -q "yes"
	tc_pass_or_fail $? "test --enablenis failed" || return

	tc_register "test --disablenis"
	authconfig --disablenis --update 1>$stdout 2>$stderr
	grep "USENIS" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablenis failed"
}

function test_ldap()
{
	tc_register "test --enableldap"
	authconfig --enableldap --update 1>$stdout 2>$stderr
	grep "USELDAP" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?
        [ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enableldap failed" || return

	tc_register "test --disableldap"
	authconfig --disableldap --update 1>$stdout 2>$stderr
	grep "USELDAP" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disableldap failed"

	tc_register "test --enableldapauth"
	authconfig --enableldapauth --update 1>$stdout 2>$stderr
	grep "USELDAPAUTH" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?    
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enableldapauth failed"

	tc_register "test --disableldapauth"
	authconfig --disableldapauth --update 1>$stdout 2>$stderr
	grep "USELDAPAUTH" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disableldapauth failed"
}

function test_krb5()
{
	tc_register "test --enablekrb5"
	authconfig --enablekrb5 --update 1>$stdout 2>$stderr
	grep "USEKERBEROS" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enablekrb5 failed" || return

	tc_register "test --disablekrb5"
	authconfig --disablekrb5 --update 1>$stdout 2>$stderr
	grep "USEKERBEROS" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablekrb5 failed"
   
        if cp "/etc/krb5.conf" "$TCTMP/" && cp "$TESTS_DIR/krb5_test.conf" "/etc/krb5.conf" ; then

		tc_register "test --krb5kdc"
		authconfig --krb5kdc="test.com" --update 1>$stdout 2>$stderr
		authconfig --test 1>$stdout 2>$stderr
		grep "krb5 kdc" $stdout | grep -q "test.com"
		tc_pass_or_fail $? "test --krb5kdc failed"

		tc_register "test --krb5adminserver"
		authconfig --krb5adminserver="test.com" --update 1>$stdout 2>$stderr
		authconfig --test 1>$stdout 2>$stderr
		grep "krb5 admin server" $stdout | grep -q "test.com"
		tc_pass_or_fail $? "test --krb5adminserver failed"
        else
                tc_register "test --krb5kdc"
                tc_break_if_bad 1 "cannot copy the correct krb5.conf file"

                tc_register "test --krb5adminserver"
                tc_break_if_bad 1 "cannot copy the correct krb5.conf file"
        fi

	tc_register "test --krb5realm"
	authconfig --krb5realm="TEST.COM" --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep "krb5 realm" $stdout | grep -q "TEST.COM"
	tc_pass_or_fail $? "test --krb5realm failed"

	tc_register "test --enablekrb5kdcdns"
	authconfig --enablekrb5kdcdns --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep -q "krb5 kdc via dns is enabled" $stdout 
	tc_pass_or_fail $? "test --enablekrb5kdcdns failed"

	tc_register "test --disablekrb5kdcdns"
	authconfig --disablekrb5kdcdns --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep -q "krb5 kdc via dns is disabled" $stdout 
	tc_pass_or_fail $? "test --disablekrb5kdcdns failed"

	tc_register "test --enablekrb5realmdns"
	authconfig --enablekrb5realmdns --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep -q "krb5 realm via dns is enabled" $stdout
	tc_pass_or_fail $? "test --enablekrb5realmdns failed"

	tc_register "test --disablekrb5realmdns"
	authconfig --disablekrb5realmdns --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep -q "krb5 realm via dns is disabled" $stdout
	tc_pass_or_fail $? "test --disablekrb5realmdns failed"
}

function test_winbind()
{
	tc_register "test --enablewinbind"
	authconfig --enablewinbind --update 1>$stdout 2>$stderr
	grep "USEWINBIND" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enablewinbind failed" || return

	tc_register "test --disablewinbind"
	authconfig --disablewinbind --update 1>$stdout 2>$stderr
	grep "USEWINBIND" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablewinbind failed"

	tc_register "test --enablewinbindauth"
	authconfig --enablewinbindauth --update 1>$stdout 2>$stderr
	grep "USEWINBINDAUTH" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$? 
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enablewinbindauth failed"

	tc_register "test --disablewinbindauth"
	authconfig --disablewinbindauth --update 1>$stdout 2>$stderr
	grep "USEWINBINDAUTH" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablewinbindauth failed"

	#Test smbsecurity types
	local smb_security_types="user server domain ads"
	for types in $smb_security_types; do
		tc_register "test --smbsecurity $types"
		authconfig --smbsecurity=$types --update 1>$stdout 2>$stderr
		authconfig --test 1>$stdout 2>$stderr
		grep "SMB security" $stdout | grep -q "$types"
		tc_pass_or_fail $? "test --smbsecurity $types failed"
	done

	tc_register "test --smbrealm"
	authconfig  --smbrealm="TEST.COM" --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep "SMB realm" $stdout | grep -q "TEST.COM"
	tc_pass_or_fail $? "test --smbrealm failed"

	tc_register "test --smbserver"
	authconfig --smbserver=localhost --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep "SMB servers" $stdout | grep -q "localhost"
	tc_pass_or_fail $? "test --smbserver failed"
	
	tc_register "test --smbworkgroup"
	authconfig --smbworkgroup="TESTGROUP" --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep "SMB workgroup" $stdout | grep -q "TESTGROUP"
	tc_pass_or_fail $? "test --smbworkgroup failed"
}

function test_hesiod()
{
	tc_register "test --enablehesiod"
	authconfig --enablehesiod --update 1>$stdout 2>$stderr
	grep "USEHESIOD" /etc/sysconfig/authconfig | grep -q "yes"
	tc_pass_or_fail $? "test --enablehesiod failed" || return

	tc_register "test --disablehesiod"
	authconfig --disablehesiod --update 1>$stdout 2>$stderr
	grep "USEHESIOD" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablehesiod failed"

	tc_register "test --hesiodlhs"
	authconfig --hesiodlhs=lhs --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep "hesiod LHS" $stdout | grep -q "lhs"
	tc_pass_or_fail $? "test --hesiodlhs failed"

	tc_register "test --hesiodrhs"
	authconfig --hesiodrhs=rhs --update 1>$stdout 2>$stderr
	authconfig --test 1>$stdout 2>$stderr
	grep "hesiod RHS" $stdout | grep -q "rhs"
	tc_pass_or_fail $? "test --hesiodlhs failed"
}

function test_sssd()
{
	tc_register "test --enablesssd"
	authconfig --enablesssd --update 1>$stdout 2>$stderr
	grep "USESSSD" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?
        [ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enablesssd failed" || return

	tc_register "test --disablesssd"
	authconfig --disablesssd --update 1>$stdout 2>$stderr
	grep "USESSSD" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablesssd failed"

	tc_register "test --enablesssdauth"
	authconfig --enablesssdauth --update 1>$stdout 2>$stderr
	grep "USESSSDAUTH" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
     	tc_pass_or_fail $RC "test --enablesssdauth failed"

	tc_register "test --disablesssdauth"
	authconfig --disablesssdauth --update 1>$stdout 2>$stderr
	grep "USESSSDAUTH" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablesssdauth failed"

	tc_register "test --enableforcelegacy"
	authconfig --enableforcelegacy --update 1>$stdout 2>$stderr
	grep "FORCELEGACY" /etc/sysconfig/authconfig | grep -q "yes"
	tc_pass_or_fail $? "test --enableforcelegacy failed"
	
	tc_register "test --disableforcelegacy"
	authconfig --disableforcelegacy --update 1>$stdout 2>$stderr
	grep "FORCELEGACY" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disableforcelegacy failed"
}

function test_cachecreds()
{
	tc_register "test --enablecachecreds"
	authconfig --enablecachecreds --update 1>$stdout 2>$stderr
	grep "CACHECREDENTIALS" /etc/sysconfig/authconfig | grep -q "yes"
	tc_pass_or_fail $? "test --enablecachecreds failed" 
	
	tc_register "test --disablecachecreds" 
	authconfig --disablecachecreds --update 1>$stdout 2>$stderr
	grep "CACHECREDENTIALS" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablecachecreds failed"
}

function test_access()
{
	tc_register "test --enablelocauthorize"
	authconfig --enablelocauthorize --update 1>$stdout 2>$stderr
	grep "USELOCAUTHORIZE" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enablelocauthorize failed"

	tc_register "test --disablelocauthorize"
	authconfig --disablelocauthorize --update 1>$stdout 2>$stderr
	grep "USELOCAUTHORIZE" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --enablelocauthorize failed"

	tc_register "test --enablepamaccess"
	authconfig --enablepamaccess --update 1>$stdout 2>$stderr
	grep "USEPAMACCESS" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enablepamaccess failed"

	tc_register "test --disablepamaccess"
	authconfig --disablepamaccess --update 1>$stdout 2>$stderr
	grep "USEPAMACCESS" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablepamaccess failed"
	
	tc_register "test --enablesysnetauth"
	authconfig --enablesysnetauth --update 1>$stdout 2>$stderr
	grep "USESYSNETAUTH" /etc/sysconfig/authconfig | grep -q "yes"
	tc_pass_or_fail $? "test --enablesysnetauth failed"

	tc_register "test --disablesysnetauth"
	authconfig --disablesysnetauth --update 1>$stdout 2>$stderr
	grep "USESYSNETAUTH" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablesysnetauth failed"
}	

function test_mkhomedir()
{
	tc_register "test --enablemkhomedir"
	authconfig --enablemkhomedir --update 1>$stdout 2>$stderr
	grep "USEMKHOMEDIR" /etc/sysconfig/authconfig | grep -q "yes"
        RC=$?
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings ".*pam_.*\.so is missing.*"
        tc_pass_or_fail $RC "test --enablemkhomedir failed" || return
	
	tc_register "test --disablemkhomedir"
	authconfig --disablemkhomedir --update 1>$stdout 2>$stderr
	grep "USEMKHOMEDIR" /etc/sysconfig/authconfig | grep -q "no"
	tc_pass_or_fail $? "test --disablemkhomedir failed"
}

function user_test()
{
	tc_register "test --test with user"
	su - $TC_TEMP_USER -c "/usr/sbin/authconfig --test" 1>$stdout 2>$stderr
	tc_pass_or_fail $? "test --test with user failed" || return	

	tc_register "test --updateall with user"
	su - $TC_TEMP_USER -c "/usr/sbin/authconfig --updateall" &>$stdout
	grep -q "can only be run as root" $stdout
	tc_pass_or_fail $? "test --updateall with user failed"
}

function test_probe()
{
	tc_register "test --probe"
	authconfig --probe 1>$stdout 2>$stderr
	tc_pass_or_fail $? "test --probe failed"
}

function test_updateall()
{
	tc_register "test --updateall"
	authconfig --updateall 1>$stdout 2>$stderr
	tc_pass_or_fail $? "test --updateall failed"
}

function test_restore()
{
	tc_register "test --restorelastbackup"
	authconfig --restorelastbackup 1>$stdout 2>$stderr
        RC=$?
        [ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings "restorecon.*lstat.*No such file or directory.*"
        tc_pass_or_fail $RC "test --restorelastbackup failed" 
	
	tc_register "test --restorebackup"
	authconfig --restorebackup=$TCTMP/authconfig-backup 1>$stdout 2>$stderr
        RC=$?
	[ $RC -eq 0 -a -s $stderr ] && tc_ignore_warnings "restorecon.*lstat.*No such file or directory.*"
        tc_pass_or_fail $RC "test --restorebackup failed"
}
	
#
# main
#
tc_setup
TST_TOTAL=15
test_save_backup 
test_passwd
test_nis
test_ldap
test_krb5
test_winbind
test_hesiod
test_sssd
test_cachecreds
test_access
test_mkhomedir
user_test
test_probe
test_updateall
test_restore
