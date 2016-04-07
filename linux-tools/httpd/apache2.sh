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
## File :	apache2.sh
##
## Description:	Test Apache2
##
## Author:	CSDL: xu zheng<zhengxu@cn.ibm.com>
###########################################################################################

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
SDIR=${LTPBIN%/shared}/httpd

# system files
HTTPD_CONF="/etc/httpd/conf/httpd.conf"
VSFTPD_CONF="/etc/vsftpd/vsftpd.conf"
VSFTPD_CONF_TMP="/etc/vsftpd/vsftpd.conf.bak"
CONFIG_DIR="/etc/apache2/sysconfig.d"
APACHE2_CONFIG="/etc/sysconfig/httpd"

# globals required for apache test
TYPE=""		# from command line
mpm=""		# filled in by tc_setup
PORT=""		# filled in by tc_setup
IPV4_HOST=""	# filled in by tc_setup
IPV6_HOST=""	# filed in in main
DOCROOT=""      # filled in by test_start
MYPAGE="testpage$$.html"	# name of page to fetch
CONTENT="secret message $$!"	# must be one line so it can be found with grep

# globals required for apache-mod-perl test
httpd_server="/var/www"
httpd_etc="/etc/httpd"
conf_file="httpd.conf"
default_conf="conf/$conf_file"
perl_conf="$httpd_etc/conf.d/mod_perl.conf"
perl_lib="$httpd_server/perl"
perl_cgi="$httpd_server/cgi-bin"
mypage_cgi="$perl_cgi/perltest.pl"
mypage_lib="$perl_lib/MyApache/MyTest.pm"
IPV6=no
module_path=""

# globals required for apache-mod-php test
mypage=""
we_started_apache=""
we_started_snmp=""
snmpinit="/etc/init.d/snmpd"
apache_was_running=""
snmp_was_running=""
snmp_udp_port=161
server_host=""
IPV6=no
STOP_FTP_SERVER=no

apacheinit="/etc/init.d/httpd"
SNMPDCONF=/etc/snmp/snmpd.conf
docroot=""

#
# test_installation     installation check
#
function test_installation()
{
        tc_register "installation check"

        # apache must be installed
        tc_exists $httpd_conf $default_server_conf $config_dir $mpm $initstart $sysconfig
        tc_pass_or_fail $? "apache is not installed properly." || return
}

#
# tc_local_setup
#
function tc_local_setup()
{
	local modstr

	tc_root_or_break || exit
	tc_exec_or_break cat grep httpd snmpd || exit
	
	rpm -q "mod_ssl" >$stdout 2>$stderr
        mod_ssl=`echo $?`
	# backup files which are touched by the testcase.
        cp -f $APACHE2_CONFIG $TCTMP/sysconfig.apache2
        cp -f $HTTPD_CONF $TCTMP/httpd.conf
        [ -d /etc/apache2/vhosts.d ] && mv -f /etc/apache2/vhosts.d  $TCTMP/
        
	# ssl?
        use_ssl=no
        mkdir -p /etc/apache2/vhosts.d
        [ -f /usr/bin/openssl ] && {
                use_ssl=yes
                cp -f $SDIR/ssl/fiv-vhost-ssl.conf /etc/apache2/vhosts.d/
                cp -f $SDIR/ssl/fiv-server.{crt,key} /etc/apache2/
        }

	# Configurations to the test.
	echo "APACHE_MPM=\"${mpm##*-}\"" >> $APACHE2_CONFIG
	modstr=$(grep "^APACHE_MODULES" $APACHE2_CONFIG)
	echo ${modstr//php5/} >> $APACHE2_CONFIG
	echo APACHE_START_TIMEOUT=9 >> $APACHE2_CONFIG

	# Setup IPv4 hostname. Defaults to localhost	
	IPV4_HOST=$(hostname -f 2>/dev/null)
	[ "$IPV4_HOST" ] || IPV4_HOST="localhost"
	echo "ServerName	$IPV4_HOST" >> $HTTPD_CONF

	[ "$use_ssl" = "yes" ] && {
                PORT=443;
		if [ $mod_ssl -eq 1 ]
		then 
	        echo "Listen 443" >> $HTTPD_CONF
		fi

                
        }

	# Look for proper solution
	#sed -i.old "s/Include conf/#Include conf/" $HTTPD_CONF
	tc_ipv6_info

	# php Configuration change to test
	cp /etc/httpd/conf.d/php.conf $TCTMP/
	sed -i -r -e 's,^((php_value)[[:blank:]].*),# \1,g' /etc/httpd/conf.d/php.conf

}

function set_mpm()
{
	mpm="/usr/lib*/httpd/modules/mod_mpm_$TYPE.so"
	sed -i 's/LoadModule/#LoadModule/' /etc/httpd/conf.modules.d/00-mpm.conf
	sed -i  "/$TYPE/ s/^#*LoadModule/LoadModule/"  /etc/httpd/conf.modules.d/00-mpm.conf
}

#
# setup for apache mod perl test
#
function setup_modperl()
{
	tc_root_or_break || exit
	tc_exec_or_break uname cat grep || exit

	module_path=/usr/lib/httpd/modules

	if [ ! -d $module_path ]; then
		module_path=/usr/lib*/httpd/modules
	fi
	tc_exist_or_break $module_path || exit

	if [ ! -f /etc/httpd/conf/mime.types ]; then
		cp /etc/mime.types /etc/httpd/conf/
	fi

	# save original file
	mv $httpd_etc/$default_conf $TCTMP/
	[ -f $perl_conf ] && cp -ax $perl_conf $TCTMP/
	cp -ax $httpd_etc/conf.d/perl.conf $TCTMP/

	cat <<-EOF > $httpd_etc/$default_conf
		DocumentRoot "/var/www/html"
		<Directory "/var/www/html">
			Options None
			AllowOverride None
			Order allow,deny
			Allow from all
		</Directory>

		Alias /icons/ "/var/www/icons/"
		<Directory "/var/www/icons">
			Options Indexes MultiViews
			AllowOverride None
			Order allow,deny
			Allow from all
		</Directory>

		ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
		<Directory "/var/www/cgi-bin">
			AllowOverride None
			Options +ExecCGI -Includes
			Order allow,deny
			Allow from all
		</Directory>

		LoadModule userdir_module $module_path/mod_userdir.so
		<IfModule mod_userdir.c>
			UserDir public_html
		</IfModule>

		Listen 80
		User apache
		Group apache

		LoadModule cgi_module $module_path/mod_cgi.so
		LoadModule log_config_module    $module_path/mod_log_config.so
		LoadModule alias_module    $module_path/mod_alias.so
		LoadModule authz_host_module    $module_path/mod_authz_host.so
		LoadModule perl_module    $module_path/mod_perl.so
		LoadModule setenvif_module   $module_path/mod_setenvif.so
		LoadModule mime_module   $module_path/mod_mime.so
		LoadModule dir_module   $module_path/mod_dir.so

		Include /etc/httpd/conf.d/*.conf
	EOF
	apache_was_running=tc_service_status httpd
	if [ $apache_was_running != 3 ] ; then
		tc_info "stopping apache server"
		tc_service_stop_and_wait httpd
		sleep 2         # be sure server is stopped
	fi

	tc_ipv6_info && IPV6=yes
}

#
# apache php module test setup
#
function apache_modphp_setup()
{
	tc_service_status snmpd && snmp_was_running="no" || snmp_was_running="yes"
	tc_ipv6_info && {
		IPV6=yes
		[ "$TC_IPV6_host_ADDRS" ] && server_host=$TC_IPV6_host_ADDRS && conf_host=$TC_IPV6_host_ADDRS
		[ "$TC_IPV6_global_ADDRS" ] && server_host=$TC_IPV6_global_ADDRS && conf_hosts=$TC_IPV6_global_ADDRS
		[ "$TC_IPV6_link_ADDRS" ] && server_host=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES && conf_host=$TC_IPV6_link_ADDRS
		server_host=$(tc_ipv6_normalize $server_host)
}
}

#
# apache test cleanup  
# Cleanup unique to apache testcase
#
function apache_test_cleanup()
{
	tc_service_stop_and_wait httpd 
	
	[ -f $TCTMP/httpd.conf ] && cp -f $TCTMP/httpd.conf $HTTPD_CONF
	[ -f $TCTMP/sysconfig.apache2 ] && cp -f $TCTMP/sysconfig.apache2 $APACHE2_CONFIG
	[ -d $TCTMP/vhosts.d ] && mv -f $TCTMP/vhosts.d/* /etc/apache2/vhosts.d/ &>/dev/null
	rm -f /etc/apache2/vhosts.d/fiv-vhost-ssl.conf &>/dev/null
	rm -f /etc/apache2/fiv-server.{crt,key} &>/dev/null
	rm -f $DOCROOT/$MYPAGE &>/dev/null
	
	if [ $httpd_cleanup ]; then
                tc_service_start_and_wait httpd 
        fi
}

#
# apache mod test cleanup
# Cleanup specific to apache-perl module test
#
function apache_modperl_test_cleanup()
{
	mv -f $TCTMP/$conf_file $HTTPD_CONF &>/dev/null
	[ -f $TCTMP/mod_perl.conf ] && mv -f $TCTMP/mod_perl.conf $perl_conf
	[ -f $mypage_cgi ] && rm $mypage_cgi &>/dev/null
	[ -f $mypage_lib ] && rm $mypage_lib &>/dev/null
	[ -f $TCTMP/perl.conf ] && mv -f $TCTMP/perl.conf $httpd_etc/conf.d/

	if [ $apache_was_running != 3 ] ; then
			tc_info "stopping apache server"
			tc_service_stop_and_wait httpd 
		
	else
			tc_info "(re)starting the apache server"
			tc_service_restart_and_wait httpd
		
	fi
}

#
# apache mod php test cleanup
# Cleanup specific to apache-php module test
#
function apache_modphp_test_cleanup()
{
	if [ "$we_started_apache" = "yes" -a $apache_was_running != 3 ] ; then
			tc_info "stopping apache server"
			tc_service_stop_and_wait httpd 
		
	fi
	if [ "$we_started_apache" = "yes" ]; then
		tc_service_stop_and_wait httpd
	fi
	[ -f $mypage ] && rm $mypage &>/dev/null

	if [ "$we_started_snmp" = "yes" ] ; then
			tc_info "stopping our instance of snmp server"
			tc_service_stop_and_wait snmpd 
		
	fi

	[ -f $TCTMP/snmpd.conf ] && cp $TCTMP/snmpd.conf $SNMPDCONF

	#[ "$STOP_FTP_SERVER" = "yes" ] && $LTPBIN/vsftpd.sh STOP_SERVER
	[ "$STOP_FTP_SERVER" = "yes" ] && tc_service_stop_and_wait vsftpd 

	if [ "$snmp_was_running" = "yes" ] ; then
		tc_info "restarting snmpd server with original config file"
		tc_service_restart_and_wait snmpd 
	fi
	cp $TCTMP/php.conf /etc/httpd/conf.d/
}

################################################################################
# the testcase functions
################################################################################

#
# apache_test_setup 	configure conf file to start with ssl.
#
function apache_test_setup()
{
	tc_register "($TYPE) start the apache server (ssl=$use_ssl)"
	
	tc_service_status httpd 
        if [ $? -eq 0 ]; then
                httpd_cleanup=1;
                tc_service_stop_and_wait httpd 
        fi

	# DOCROOT must be defined
	DOCROOT=$(cat $HTTPD_CONF | grep "^DocumentRoot")
	[ -n "$DOCROOT" ]
	tc_fail_if_bad $? "DocumentRoot not specified in '$HTTPD_CONF'." || return

	set $DOCROOT
	local q="\""
	eval DOCROOT=${2#\$q}		  # trim leading quote
	eval DOCROOT=${DOCROOT%\$q}       # trim trailing quote
	[ -d "$DOCROOT" ] || mkdir -p "$DOCROOT"

	# Place a web page in server's DOCROOT.
	cat > $DOCROOT/$MYPAGE <<-EOF
		<html>
		<body>
		<p>
		$CONTENT
		</p>
		</body>
		</html>
	EOF
}

#
# Start apache server for apache test
#
function apache_server_start()
{
	tc_register "($TYPE) start the apache server (ssl=$use_ssl)"
	if [ "$prev_mpm" != "" ]; then
		tc_service_stop_and_wait httpd &>$stdout
		tc_fail_if_bad $? "did not stop" || return
		tc_wait_for_inactive_port 80 443
	fi
	
	if [ "$prev_mpm" == "" -o "$prev_mpm" != "$mpm" ]; then
		tc_service_start_and_wait httpd &>$stdout
		tc_fail_if_bad $? "did not start" || return
		tc_wait_for_active_port $PORT
		tc_pass_or_fail $? "apache server not listening on port $PORT." || return
		tc_info "$(<$stdout)"
	fi
	prev_mpm=$mpm
}

#
# do the fetch and compare
#	$1 IP to fetch from
#	$2 IP version
#	$3 protocol (http, https)
#	$4 arbitrary text for tc_register
#
function fetch()
{
	local ip=$1
	local ipver=$2
	local proto=$3
	local port=80; [ "$proto" = "https" ] && port=443
	local text="$4"

	tc_register "fetch web page via $proto from $ipver $ip $text"

	# get the page from apache sever via http
	fivget $proto $ip $port $MYPAGE >$stdout 2>$stderr
        # delete fivget $proto $ip $port $MYPAGE

	tc_fail_if_bad $? "failed to get web page from $ip via $proto." || return

	# compare for expected content
	grep -q "$CONTENT" $stdout 2>$stderr
	tc_pass_or_fail $? "expected to see: \"$CONTENT\" in the web page." 
}

################################################################################
# the testcase functions
################################################################################

#
# test01        installation check
#
function test01()
{
        tc_register "Apache/httpd installation check"

        # apache must be installed
        tc_executes /usr/sbin/httpd  
        tc_fail_if_bad $? "apache is not installed properly." || return

        # the perl module.
        tc_exists $module_path_perl
        tc_pass_or_fail $? "perl module not installed." || exit
}

#
# test02        configure apache for mod_perl
#
function test02()
{
        tc_register "configure and start apache with mod_perl"

        mkdir -p $perl_lib/MyApache
        pkg=MyTest

        echo $perl_mod >> $httpd_etc/$default_conf   # install mod_perl
        # configure apache for mod_perl and mod_perl handler
	cat <<-EOF >> $perl_conf        # config perl handler
		<Location /perltest>
			SetHandler  perl-script
			PerlResponseHandler MyApache::MyTest
		</Location>
	EOF

        # configure apache to pick up module from /var/www/perl
	cat <<-EOF >> $httpd_etc/conf.d/perl.conf
		PerlSwitches -I/var/www/perl
	EOF

        # Place handler page
	cat <<-EOF > $mypage_lib
		package MyApache::$pkg;
		use warnings;
		use Apache2::RequestRec ();
		use Apache2::RequestIO ();
		use Apache2::Const -compile => qw(OK);
		sub handler {
			if (\$ENV{MOD_PERL}) {
				my \$a="LIFE IS ";
				my \$b="GOOD";
				my \$r = shift;
				\$r->content_type('text/html');
				print "
					<html><body>
					<h1>Hello World from perl handler!</h1>
					<p>
				";
				print map { "\$_ = \$ENV{\$_}<br>\n" } sort (keys (%ENV));
				print "
					<p>\$a\$b
					</body></html>
				";
			} else {
				print "Content-type: text/plain\n\n";
				print "BAD NEWS!";
			}
			return Apache2::OK;
		}
		1;
	EOF

        chmod +x $mypage_lib
        # (re)start apache
        tc_service_restart_and_wait httpd 
}


#
# test03        fetch perl cgi page
#
function test03()
{
        tc_register "get perl cgi page"
        # Place web page
        # Construct perl web page in a way that the returned value will only
        # match the expected if the page has been procesed by Perl.
	cat <<-EOF > $mypage_cgi
		#!/usr/bin/perl
		my \$a="LIFE IS ";
		my \$b="GOOD";
		print "Content-Type: text/html\n\n";
		print "<html><head><title>Script Environment</title>
		</head><body>\n";
		print "<h1>Hello World from perl registry app!</h1>
		";
		print map { "\$_ = \$ENV{\$_}<br>\n" } sort (keys (%ENV));
		print "
		<p>\$a\$b
		</body></html>\n";
	EOF
        chmod +x $mypage_cgi

        local expected="LIFE IS GOOD";

        # get the page from apache sever via http
        fivget http localhost 80 cgi-bin/perltest.pl >$stdout 2>$stderr
        tc_fail_if_bad $? "failed to get perltest.pl from server" || return

        # compare for expected content
        grep -q "$expected" $stdout 2>$stderr
        tc_pass_or_fail $? "expected to see \"$expected\" in the web page."

        # Should we do IPV6 test?
        [ "$IPV6" = "no" ] && return 0
        ((++TST_TOTAL))
        tc_register "get perl cgi page via ipv6"

        local server_host
        [ "$TC_IPV6_host_ADDRS" ] && server_host=$TC_IPV6_host_ADDRS
        [ "$TC_IPV6_global_ADDRS" ] && server_host=$TC_IPV6_global_ADDRS
        [ "$TC_IPV6_link_ADDRS" ] && server_host=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
        server_host=$(tc_ipv6_normalize $server_host)
        fivget http $server_host 80 cgi-bin/perltest.pl >$stdout 2>$stderr
        tc_fail_if_bad $? "failed to get perltest.pl from server" || return
        # compare for expected content
        grep -q "$expected" $stdout 2>$stderr
        tc_pass_or_fail $? "expected to see \"$expected\" in the web page."
}


#
# test04        test the mod_perl handler
#
function test04()
{
        tc_register "get mod_perl handler"
        local expected="LIFE IS GOOD";
        # query the mod_perl handler via http
        fivget http localhost 80 perltest >$stdout 2>$stderr
        tc_fail_if_bad $? "failed to access the mod_perl handler" || return

        # compare for expected content
        grep -q "$expected" $stdout 2>$stderr
        tc_pass_or_fail $? "expected to see \"$expected\" in the web page."

        # Should we do IPV6 test?
        [ "$IPV6" = "no" ] && return 0

        ((++TST_TOTAL))
        tc_register "get mod_perl handler via ipv6"

        local server_host
        [ "$TC_IPV6_host_ADDRS" ] && server_host=$TC_IPV6_host_ADDRS
        [ "$TC_IPV6_global_ADDRS" ] && server_host=$TC_IPV6_global_ADDRS
        [ "$TC_IPV6_link_ADDRS" ] && server_host=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
        server_host=$(tc_ipv6_normalize $server_host)

        local expected="LIFE IS GOOD";
        # query the mod_perl handler via http
        fivget http $server_host 80 perltest >$stdout 2>$stderr
        tc_fail_if_bad $? "failed to access the mod_perl handler" || return

        # compare for expected content
        grep -q "$expected" $stdout 2>$stderr
        tc_pass_or_fail $? "expected to see \"$expected\" in the web page."
}


#
# PHP installation check
#
function test01_php()
{
        tc_register "installation check"
        tc_executes php
        tc_pass_or_fail $? "php not installed"
}

#
# Test fetch php page
#
function apache_php_test()
{
        tc_register "get PHP web page from server (ipv4)"

        tc_exec_or_break cat grep echo || return

        # apache must be installed
	tc_exist_or_break /usr/sbin/httpd || return

        # httpd.conf file must exist
        tc_exist_or_break $HTTPD_CONF || return

        # DocumentRoot must be specified in httpd.conf
        docroot="$(grep "^DocumentRoot" $HTTPD_CONF)"
        [ "$docroot" ]
        tc_break_if_bad $? "Could not find DocumentRoot in $HTTPD_CONF" || return

        set $docroot
        local q="\""
        eval docroot=${2#\$q}           # trim leading quote
        eval docroot=${docroot%\$q}     # trim trailing quote
        [ "$docroot" ]
        tc_break_if_bad $? "DocumentRoot not specified in $HTTPD_CONF" || return
        mkdir -p $docroot
	
	local apache_status=tc_service_status httpd
        [ "$apache_status" ]
        tc_break_if_bad $? "Could not get apache status" || return

        set $apache_status
        apache_was_running=$4

        # Place web page in server's docroot.
        # Construct php web page in a way that the returned value will only
        # match the expected if the page has been procesed by PHP.
        mypage="$docroot/$TCID$$.php"
        local a="$TCID";
        local b="$$"
        local expected="$a $b"
	cat > $mypage <<-EOF
		<?php
		\$a="$a";
		\$b = "$b";
		print "\$a \$b";
		?>
	EOF

        # stop apache if it was running
        if [ $apache_was_running != 3 ] ; then
                tc_info "stopping apache server"
		tc_service_stop_and_wait httpd 
        fi

        # start apache to make sure the default settings are used
        tc_info "starting apache web server"
        we_started_apache="yes"
	tc_service_start_and_wait httpd 

        # get the page from apache sever via http
        fivget http localhost 80 $TCID$$.php >$stdout 2>$stderr
        tc_fail_if_bad $? "failed to GET from server" || return
        # compare for expected content
        grep -q "$expected1" $stdout 2>$stderr
        tc_pass_or_fail $? "" "expected to see \"$expected1\" in stdout"
        grep -q "$expected2" $stdout 2>$stderr
        tc_pass_or_fail $? "" "expected to see \"$expected2\" in stdout"

        [ "$IPV6" = "yes" ] && {
                tc_register "get PHP web page from server (ipv6)"

                # get the page from apache sever via http
                fivget http $server_host 80 $TCID$$.php >$stdout 2>$stderr
                tc_fail_if_bad $? "failed to GET from ipv6 server" || return

                # compare for expected content
                grep -q "$expected" $stdout 2>$stderr
                tc_pass_or_fail $? "" "expected to see \"$expected\" in stdout"
        }
}


#
# snmp_test     Fetch snmp data
#               only runs if -s command line switch is used.
#
function snmp_test()
{
        hostname=$(hostname)
        tc_register "PHP snmp functions (ipv4 $hostname)"
        tc_exec_or_break cat grep echo || return

        tc_executes /usr/sbin/snmpd 
        tc_fail_if_bad $? \
                "snmp test requested, but snmp not properly installed" || return

        # stop snmpd if it was running
        if [ "$snmp_was_running" = "yes" ] ; then
                tc_info "stopping snmpd server"
		tc_service_stop_and_wait snmpd 
        fi

        # start snmpd to make sure the default settings are used
        tc_info "starting snmpd server"
        cp $SNMPDCONF $TCTMP/
        echo "rocommunity public $hostname" >> $SNMPDCONF
	echo "agentaddress udp:161" >> $SNMPDCONF
        echo "rocommunity6 public $conf_host" >> $SNMPDCONF
	echo "agentaddress udp6:161" >> $SNMPDCONF

        tc_service_restart_and_wait snmpd
	tc_wait_for_active_port $snmp_udp_port
        tc_fail_if_bad $? "snmpd server would not start" || return

	tc_service_status snmpd
        we_started_snmp="yes"

        local my_php=$TCTMP/my.php
        local my_ipv6_php=$TCTMP/my_ipv6.php
        local a="$TCID";
        local b="$$"

        cat > $my_php <<-EOF
		<?php
			\$host = '$hostname';
			\$community = 'public';
			\$sysName = snmpget(\$host, \$community, "system.sysName.0");
			print "\$sysName
			";
			\$a = snmpwalk(\$host, \$community, "system");
			for (\$i = 0; \$i < count(\$a); \$i++) {
				echo "\$a[\$i]
				";
			}
		?>
	EOF
        php $my_php >$stdout 2>$stderr
        tc_fail_if_bad $? "Unexpected response from \"php5 $my_php\"" || return

        # compare for expected content
        local exp1="$HOSTNAME"
        local exp2="$(uname -n)"
        local exp3="$(uname -m)"
        local exp4="$(uname -r)"
        local exp5="$(uname -s)"
        local exp6="$(uname -v)"

        grep -q "$exp1" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp1\" in stdout"  || return

        grep -q "$exp2" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp2\" in stdout"  || return

        grep -q "$exp3" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp3\" in stdout"  || return

        grep -q "$exp4" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp4\" in stdout"  || return

        grep -q "$exp5" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp5\" in stdout"  || return

        grep -q "$exp6" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp6\" in stdout"  || return

        tc_pass_or_fail 0 "always pass if we get this far"
        [ "$server_host" ] || return
        ((++TST_TOTAL))
        tc_register "PHP snmp functions (ipv6 $server_host)"
	cat > $my_ipv6_php <<-EOF
		<?php
			\$host = "[$server_host]";
			\$community = "public";
			\$sysName = snmpget(\$host, \$community, "system.sysName.0");
			print "\$sysName
			";
			\$a = snmpwalk(\$host, \$community, "system");
			for (\$i = 0; \$i < count(\$a); \$i++) {
				echo "\$a[\$i]
				";
			}
		?>
	EOF
        php $my_ipv6_php &>$stdout
        tc_fail_if_bad $? "Unexpected response from \"php5 $my_ipv6_php\"" || return

        grep -q "$exp1" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp1\" in stdout"  || return

        grep -q "$exp2" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp2\" in stdout"  || return

        grep -q "$exp3" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp3\" in stdout"  || return

        grep -q "$exp4" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp4\" in stdout"  || return

        grep -q "$exp5" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp5\" in stdout"  || return

        grep -q "$exp6" $stdout 2>$stderr
        tc_fail_if_bad $? "expected to see \"$exp6\" in stdout"  || return

        tc_pass_or_fail 0 "always pass if we get this far"

}
#
#Function will enable the ipv4 support for vsftpd
#
function ftp_enable_ipv4()
{
	# disable any ipv4 entry if any
	sed -i 's/\( *#*listen[_, a-z, 0-9]*=[A-Z, a-z]*\)//g' $VSFTPD_CONF
	# enable ipv4 now
	echo "listen=YES" >> $VSFTPD_CONF
}

function ftp_enable_ipv6()
{
	# disable any ipv6 entry if any
	sed -i 's/\( *#*listen[_, a-z, 0-9]*=[A-Z, a-z]*\)//g' $VSFTPD_CONF
	# enable ipv4 now
	echo "listen_ipv6=YES" >> $VSFTPD_CONF
}
#
#ftp functions test
#this test runs if -f command line switch is set
function ftp_test()
{
	tc_register "PHP ftp functions ($1)" 
	local vsftd_cleanup=0
	local FTP_SERVER=""
	tc_service_status vsftpd || tc_service_start_and_wait vsftpd
	cp $VSFTPD_CONF $VSFTPD_CONF_TMP
	if [ "$1" == "ipv4" ]; then
	
		FTP_SERVER=localhost4
		vsftd_cleanup=1
		ftp_enable_ipv4
	
	elif [ "$1" == "ipv6" ]; then
	
		FTP_SERVER=localhost6
		vsftd_cleanup=1
		ftp_enable_ipv6
	fi
	local STOP_FTP_SERVER=yes
	tc_service_start_and_wait vsftpd 
	local my_php=$TCTMP/my.php
	cat > $my_php <<-EOF
		<?php
		\$ftp=ftp_connect("$FTP_SERVER" , 21) or die ("Can't connect to FTP Server : $FTP_SERVER");
		\$ok=ftp_login(\$ftp , "anonymous" , "anonymous") or die ("Can't login to FTP Server : $FTP_SERVER");
		\$pwd=ftp_pwd(\$ftp);
		echo \$pwd;
		?>
	EOF
	php $my_php >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from my.php" || return
	grep -q "/" $stdout 2>$stderr
	tc_pass_or_fail $? "expected to see / in stdout"
	if [ $vsftd_cleanup ]; then
		cp $VSFTPD_CONF_TMP $VSFTPD_CONF
		rm -rf $VSFTPD_CONF_TMP
	fi
}


################################################################################
# main
################################################################################

TST_TOTAL=4
tc_setup
apache_test_setup || exit
SUPP_TYPES=(worker event prefork)
for TYPE in ${SUPP_TYPES[@]};
do
	set_mpm
	test_installation || exit
	apache_server_start
	fetch localhost http "IPv4"
	fetch localhost https "IPv4"

	[ "$IPV4_HOST" = "localhost" ] || {
		((TST_TOTAL+=2))
		fetch $IPV4_HOST http "IPv4"
		fetch $IPV4_HOST https "IPv4"
	}

	[ "$TC_IPV6_host_ADDRS" ] && {
		((TST_TOTAL+=2))
		IPV6_HOST=$TC_IPV6_host_ADDRS
		IPV6_HOST=$(tc_ipv6_normalize $IPV6_HOST)
		fetch $IPV6_HOST http IPv6 "(host scope)"
		fetch $IPV6_HOST https IPv6 "(host scope)"
	}

	[ "$TC_IPV6_global_ADDRS" ] && {
		((TST_TOTAL+=2))
		IPV6_HOST=$TC_IPV6_global_ADDRS
		IPV6_HOST=$(tc_ipv6_normalize $IPV6_HOST)
		fetch $IPV6_HOST http IPv6 "(global scope)"
		fetch $IPV6_HOST https IPv6 "(global scope)"
	}

	[ "$TC_IPV6_link_ADDRS" ] && {
		((TST_TOTAL+=2))
		IPV6_HOST=$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES
		IPV6_HOST=$(tc_ipv6_normalize $IPV6_HOST)
		fetch $IPV6_HOST http IPv6 "(link scope)"
		fetch $IPV6_HOST https IPv6 "(link scope)"
	}
done

apache_test_cleanup

# Start Apache perl module support test
#setup_modperl
#test01
#test02
#test03
#test04
#apache_modperl_test_cleanup

# Start PHP Apache, ftp & SNMP tests
apache_modphp_setup
apache_php_test
ftp_test ipv4
ftp_test ipv6 
snmp_test
apache_modphp_test_cleanup
