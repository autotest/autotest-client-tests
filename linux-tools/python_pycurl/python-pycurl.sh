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
## 	                                                                                  ##
## File : python-pycurl    	                                                          ##
##             		                                                                  ##
## Description: This testcase tests python-pycurl package	                          ##
##                                           		                                  ##
## Author:      Sheetal Kamatar <sheetal.kamatar@in.ibm.com>         		          ##
##                               	                                                  ##
############################################################################################
#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/python_pycurl/tests"
HTMLDIR="${LTPBIN%/shared}/python_pycurl/html_files/"
REQUIRED="python vsftpd httpd"
HTTP_SERVER=localhost
FTP_SERVER=localhost
vsftpd_cleanup=0
httpd_service=httpd
ftp_service=vsftpd
function tc_local_setup()
{
    if [ `grep -ci frobisher /etc/release.manifest` -gt 0 ];
    then
       HTTP_SERVER=test1.au.example.com
       FTP_SERVER=test1.au.example.com

       #The test will use HTTP_SERVER and FTP_SERVER for the testing
       #as there is no supported of these server package in Frobisher.
       #Required html pages are hosted in these server.
       #Relevant portion of fstab file in test1.au.example.com put for this test
       ##python-pycurl-START
       ##following mounts are used by python-pycurl test in Frobisher
       ##Please dont remove it 
       #/dev/vdb1 /support ext4 rw 0 0
       #/support/support/python-pycurl /srv/www/htdocs/python-pycurl none rw,bind 0 0
       #/support/support/python-pycurl /var/ftp/python-pycurl none rw,bind 0 0
       ##python-pycurl:END

       #Since there is not GUI support in Frobisher, for gtk related 
       #tests, test will be using a vncserver instance in test1.au.example.com
       #test1.au.example.com's cron has an entry to initiate this vncserver instance.
       ##python-pycurl test's vncserver
       #*/10 * * * * /support/support/vncstart

       export DISPLAY=test1.au.example.com:4

    else

       tc_exec_or_break $REQUIRED

       cp -r $TESTDIR $TESTDIR.org
       # Copy all html files to /var/www/html/python-pycurl
       mkdir -p /var/www/html/python-pycurl/
       cp -r $HTMLDIR/ /var/www/html/python-pycurl/

       mkdir -p /var/ftp/python-pycurl
       pushd /var/ftp/python-pycurl >$stdout 2>$stderr
       mkdir dir1 dir2 dir3 dir4 >$stdout 2>$stderr
       touch file1 file2 file3 file4
       popd >$stdout 2>$stderr

       #Service start
       systemctl is-active httpd >$stdout 2>$stderr
       if [ $? -eq 0 ]; then
           httpd_cleanup=1
       else
           tc_service_start_and_wait $httpd_service
       fi

       systemctl is-active vsftpd >$stdout 2>$stderr
       if [ $? -eq 0 ] ; then
       vsftpd_cleanup=1
       else
           tc_service_start_and_wait $ftp_service
       fi

       #Start the vnc server as test_gtk.py requires Xwindows
       vncserver -kill :4 > /dev/null 2>&1
       vncserver :4 -SecurityTypes None >/dev/null 2>&1
       export DISPLAY=:4
   fi
}

function tc_local_cleanup()
{
    if [ `grep -ic frobisher /etc/release.manifest` -gt 0 ];
    then
	return 0
    else
       # Restore status of httpd service
       if [ $httpd_cleanup -eq 0 ]; then
           systemctl stop httpd >/dev/null 2>&1
           systemctl status httpd >$stdout 2>$stderr
           grep -iqv "Active: active" $stdout
           tc_break_if_bad $? "failed to stop httpd"
       fi
       if [ $vsftpd_cleanup -eq 0 ]; then
           systemctl stop vsftpd >/dev/null 2>&1
           systemctl status vsftpd >$stdout 2>$stderr
           grep -qiv "Active: active" $stdout
           tc_break_if_bad $? "failed to stop vsftpd"
       fi

       # Restore the .bkp files
       mv $TESTDIR.org $TESTDIR >$stdout 2>$stderr

       vncserver -kill :4 >/dev/null 2>&1
   fi
}

function install_check()
{
    tc_register "Installation check"
      tc_check_package python-pycurl
    tc_pass_or_fail $? "python-pycurl not installed"


    # Following modifications are required to resolve outbound access
    sed -e 's|http://www.python.org/|http://'$HTTP_SERVER'/python-pycurl/noindex.html|g' -i $TESTDIR/test_cb.py
    sed -e 's|http://curl.haxx.se/|http://'$HTTP_SERVER'/python-pycurl/top.html|g' -i $TESTDIR/test_cb.py
    
    sed -e 's|http://curl.haxx.se/|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_debug.py

    sed -e 's|ftp://ftp.sunet.se/|ftp://'$FTP_SERVER'/|g' -i $TESTDIR/test_ftp.py
    sed -e 's|http://www.cnn.com|http://'$HTTP_SERVER'/python-pycurl/noindex.html|g' -i $TESTDIR/test_getinfo.py

    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_multi2.py
    sed -e 's|http://www.python.org|http://'$HTTP_SERVER'/python-pycurl/bottom.html|g' -i $TESTDIR/test_multi2.py
    sed -e 's|http://pycurl.sourceforge.net|http://'$HTTP_SERVER'/python-pycurl/multiple_links.net|g' -i $TESTDIR/test_multi2.py
    sed -e 's|http://pycurl.sourceforge.net/tests/403_FORBIDDEN|http://'$HTTP_SERVER'/python-pycurl/multiple_links.net/tests/403_FORBIDDEN|g' -i $TESTDIR/test_multi2.py
    sed -e 's|http://pycurl.sourceforge.net/tests/404_NOT_FOUND|http://'$HTTP_SERVER'/python-pycurl/multiple_links.net/tests/404_NOT_FOUND|g' -i $TESTDIR/test_multi2.py

    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_multi3.py
    sed -e 's|http://www.python.org|http://'$HTTP_SERVER'/python-pycurl/noindex.html|g' -i $TESTDIR/test_multi3.py
    sed -e 's|http://pycurl.sourceforge.net/THIS_HANDLE_IS_CLOSED|http://'$HTTP_SERVER'/python-pycurl/multiple_links.net/THIS_HANDLE_IS_CLOSED|g' -i $TESTDIR/test_multi3.py

    sed -e 's|http://www.python.org|localhost/noindex.html|g' -i $TESTDIR/test_multi4.py
    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/multiple_links.net|g' -i $TESTDIR/test_multi4.py
    sed -e 's|http://slashdot.org|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_multi4.py

    sed -e 's|http://www.python.org|localhost/README.html|g' -i $TESTDIR/test_multi5.py
    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/learnHTML.html|g' -i $TESTDIR/test_multi5.py
    sed -e 's|http://slashdot.org|http://'$HTTP_SERVER'/python-pycurl/cag.html|g' -i $TESTDIR/test_multi5.py

    sed -e 's|http://www.python.org|localhost/top.html|g' -i $TESTDIR/test_multi6.py
    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_multi6.py
    sed -e 's|http://slashdot.org|http://'$HTTP_SERVER'/python-pycurl/multiple_links.net|g' -i $TESTDIR/test_multi6.py

    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/HTML_Tutorial.html|g' -i $TESTDIR/test_multi.py
    sed -e 's|http://cnn.com|http://'$HTTP_SERVER'/python-pycurl/cag.html|g' -i $TESTDIR/test_multi.py

    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/cag.html|g' -i $TESTDIR/test_multi_socket.py
    sed -e 's|http://www.python.org|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_multi_socket.py
    sed -e 's|http://pycurl.sourceforge.net|http://'$HTTP_SERVER'/python-pycurl/learnHTML.html|g' -i $TESTDIR/test_multi_socket.py

    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/top.html|g' -i $TESTDIR/test_multi_socket_select.py
    sed "/http:\/\/www\.python.\org/d" -i $TESTDIR/test_multi_socket_select.py
    sed -e 's|http://pycurl.sourceforge.net|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_multi_socket_select.py

    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/top.html|g' -i $TESTDIR/test_multi_timer.py
    sed -e 's|http://www.python.org|http://'$HTTP_SERVER'/python-pycurl/noindex.html|g' -i  $TESTDIR/test_multi_timer.py
    sed -e 's|http://pycurl.sourceforge.net|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_multi_timer.py

    sed -e 's|http://pycurl.sourceforge.net/tests/teststaticpage.html|http://'$HTTP_SERVER'/python-pycurl/teststaticpage.html|g' -i $TESTDIR/test_multi_vs_thread.py

    sed -e 's|http://www.contactor.se/~dast/postit.cgi|http://'$HTTP_SERVER'/python-pycurl/cag.html|g' -i $TESTDIR/test_post2.py

    sed -e 's|http://pycurl.sourceforge.net/tests/testpostvars.php|http://'$HTTP_SERVER'/python-pycurl/testpostvars.php|g' -i $TESTDIR/test_post3.py

    sed -e 's|http://pycurl.sourceforge.net/tests/testpostvars.php|http://'$HTTP_SERVER'/python-pycurl/testpostvars.php|g' -i $TESTDIR/test_post.py

    sed -e 's|http://curl.haxx.se|http://'$HTTP_SERVER'/python-pycurl/noindex.html|g' -i $TESTDIR/test_share.py

    sed -e 's|http://camvine.com|http://'$HTTP_SERVER'/python-pycurl/learnHTML.html|g' -i $TESTDIR/test_socketopen.py
    
    sed -e 's|http://curl.haxx.se/dev/|http://'$HTTP_SERVER'/python-pycurl/README.html|g' -i $TESTDIR/test_stringio.py

    sed -e 's|http://betty.userland.com/RPC2|http://'$HTTP_SERVER'/python-pycurl/bettyuserland.com|g' -i $TESTDIR/test_xmlrpc.py

}

function runtests()
{
    pushd $TESTDIR>$stdout 2>$stderr
    TESTS=`ls *.py`
    TST_TOTAL=`echo $TESTS | wc -w`
   for test in $TESTS; do
        tc_register "Test $test"
        if [ "$test" == "test_reset.py" ]
        then
             #Newly addedd testcase (https://bugzilla.redhat.com/show_bug.cgi?id=896025)
             python $test http://$HTTP_SERVER/python-pycurl/html_files/noindex.html &>$stdout
        else
             python $test &>$stdout
        fi
        tc_pass_or_fail $? "$test failed"
    done
    popd >$stdout 2>$stderr
}

#
#MAIN
#
tc_setup
install_check &&
runtests

