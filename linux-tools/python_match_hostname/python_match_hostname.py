#!/bin/python
import os
import logging
import socket
import ssl
import threading
from backports.ssl_match_hostname import match_hostname, CertificateError
from autotest.client import test
from autotest.client.shared import error


class python_match_hostname(test.test):

    """
    Secure Socket Layer is secure when the hostname in the certificate returned
    by the server matches to hostname thats being trying to be reached.
    match_hostname() in ssl package in the Standard Library of Python 3.2 performs this check
    instead of requiring every application to implement the check separately.

    backport brings match_hostname() to users of earlier versions of Python.
    @author Athira Rajeev<atrajeev@linux.vnet.ibm.com>

    """
    version = 2
    nfail = 0
    httpd_conf = "/etc/httpd/conf/httpd.conf"
    ssl_conf = "/etc/httpd/conf.d/ssl.conf"
    key_dir = "/etc/pki/tls/private"
    cert_dir = "/etc/pki/tls/certs"

    def server_soc(self):
        """
        Server socket
        Create a socket
        Bind the socket to a port
        """

        bindsocket = socket.socket()
        bindsocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        bindsocket.bind(('', 1002))
        bindsocket.listen(5)
        newsocket, fromaddr = bindsocket.accept()
        connstream = ssl.wrap_socket(newsocket, server_side=True,
                                     certfile="%s/server.crt" % self.tmpdir, keyfile="%s/server.key" % self.tmpdir)
        bindsocket.close()

    def create_ssl_cert(self):
        """
        Create openssl certificate
        Create server-wget.crt and server-wget.key for verification
        of hostname while using wget
        Fail the test if certificate creation fails using openssl
        Certificate creation can fail due to any reason, so using generic exception
        """

        try:
            utils.system("openssl req -new -newkey rsa:4096 -days 1 -nodes -x509 -subj \"/C=US/ST=BAN/L=field/O=XX/CN=www.example.com\" -keyout %s/server.key -out %s/server.crt" % (self.tmpdir, self.tmpdir))

            logging.info('Created openssl certificate server.crt\n')
        except Exception as e:
            logging.error(e)
            raise error.TestError('\n Creating openssl certificate failed')

        try:
            utils.system("openssl req -new -newkey rsa:4096 -days 1 -nodes -x509 -subj \"/C=US/ST=BAN/L=field/O=XX/CN=localhost-wget\" -keyout %s/server-wget.key -out %s/server-wget.crt" % (self.tmpdir, self.tmpdir))

            logging.info('Created openssl certificate server-wget.crt\n')

        except Exception as e:
            logging.error(e)
            raise error.TestError(' Creating openssl certificate failed')

    def https_setup(self):
        """
        setup https server
        Backup ssl.conf and httpd.conf
        Add Certificate information in ssl.conf
        and httpd.conf files
        Create a test file to download
        Start httpd server
        If any of the above steps fails, setup fails. So using generic Exception
        """

        try:
            utils.system("cp %s/server-wget.crt %s/" %
                         (self.tmpdir, self.cert_dir))
            utils.system("cp %s/server-wget.key %s/" %
                         (self.tmpdir, self.key_dir))
            if os.path.exists("%s" % self.ssl_conf):
                utils.system("cp %s %s.org" % (self.ssl_conf, self.ssl_conf))
            else:
                raise error.TestError(
                    '\nTest failed to find ssl conf for https. Install mod_ssl')

            os.system("sed -i \"s:^SSLCertificateFile.*:SSLCertificateFile %s/server-wget.crt:g\" %s" %
                      (self.cert_dir, self.ssl_conf))
            os.system("sed -i \"s:^SSLCertificateKeyFile.*:SSLCertificateKeyFile %s/server-wget.key:g\" %s" %
                      (self.key_dir, self.ssl_conf))

            if os.path.exists("%s" % self.httpd_conf):
                utils.system("cp %s %s.org" %
                             (self.httpd_conf, self.httpd_conf))
            else:
                raise error.TestError('\nTest failed to find httpd conf file')

            f = open('/etc/httpd/conf/httpd.conf', 'a')
            f.writelines("""
NameVirtualHost *:443

<VirtualHost *:443>
        SSLEngine on
        SSLCertificateFile /etc/pki/tls/certs/server-wget.crt
        SSLCertificateKeyFile /etc/pki/tls/private/server-wget.key
        <Directory /var/www/html/Test>
                AllowOverride All
        </Directory>
DocumentRoot /var/www/html/Test
</VirtualHost>""")

            f.close()

            os.mkdir("/var/www/html/Test")
            os.system("echo \"testing\" >> /var/www/html/Test/file")

            utils.system("service httpd restart")

        except Exception as e:
            logging.error(e)
            raise error.TestError('\nhttps setup failed')

    def hostname_check_wget(self):
        """
        1. server-wget.crt has wrong hostname as localhost-wget
        2. Connect to https with localhost
        3. match_hostname from backports.ssl_match_hostname should identify the mismatch
        4. Create certificate with correct hostname as localhost
        5. Use wget and verify file is downloaded
        """
        try:
            utils.system(
                "wget --ca-certificate=%s/server-wget.crt https://localhost/Test/file" % self.cert_dir)
            logging.info(
                '\nwget succeeded inspite of wrong hostname. Incrementing nfail')
            self.nfail += 1
        except Exception as e:
            logging.info('\nIdentified wrong hostname while connecting')

        try:
            utils.system("openssl req -new -newkey rsa:4096 -days 1 -nodes -x509 -subj \"/C=US/ST=BAN/L=field/O=XX/CN=localhost\" -keyout %s/server-wget.key -out %s/server-wget.crt" % (self.tmpdir, self.tmpdir))
            logging.info('Created openssl certificate server-wget.crt\n')
        except Exception as e:
            logging.error(e)
            raise error.TestError('\n Creating openssl certificate failed')

        os.system("cp %s/server-wget.key %s/" % (self.tmpdir, self.key_dir))
        os.system("cp %s/server-wget.crt %s/" % (self.tmpdir, self.cert_dir))

        utils.system("service httpd restart")

        try:
            utils.system("wget --ca-certificate=%s/server-wget.crt -O %s/file https://localhost/Test/file" %
                         (self.cert_dir, self.tmpdir))
            logging.info('\nIdentified correct hostname')

            if os.path.exists("%s/file" % self.tmpdir):
                logging.info('\nSuccessfully downloaded file')
            else:
                self.nfail += 1
                raise error.TestError('\n Test failed to download file')

        except Exception as e:
            logging.error(
                'match_hostname failed to identify correct hostname. \n')
            self.nfail += 1
            raise error.TestError('\nTest failed to match hostname')

    def hostname_match(self, ssl_sock):
        """
        Check if hostname is matching
        get the server's certificate using getpeercert()
        Verify the cert matches the hostname
        """

        try:
            match_hostname(ssl_sock.getpeercert(), "www.example.com")
        except CertificateError:
            logging.error('hostname doesnt match. \n')
            self.nfail += 1
            raise error.TestError('\nTest failed to match hostname')

    def hostname_mismatch(self, ssl_sock):
        """
        Check if wrong hostname is identified
        get the server's certificate using getpeercert()
        match_hostname should mismatch for wrong hostname
        """
        try:
            match_hostname(ssl_sock.getpeercert(), "www.example-wrong.com")
            self.nfail += 1
            logging.info('\n match_hostname failed to identify wrong hostname')
        except CertificateError:
            logging.info('\nIdentified mismatch in hostname')

    def run_once(self):
        """
        Runs the test.
        1. Creates openssl certificate
        2. start server thread
        3. Connect as client to the server
        4. Check for hostname match and mismatch
        """

        self.create_ssl_cert()
        server_thread = threading.Thread(target=self.server_soc)
        server_thread.start()
        # client socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssl_sock = ssl.wrap_socket(
            s, ca_certs="%s/server.crt" % self.tmpdir, cert_reqs=ssl.CERT_REQUIRED)
        ssl_sock.connect(('localhost', 1002))
        self.hostname_match(ssl_sock)
        self.hostname_mismatch(ssl_sock)
        self.https_setup()
        self.hostname_check_wget()

        ssl_sock.close()

        server_thread.join()

    def cleanup(self):

        if os.path.exists("%s" % self.ssl_conf):
            os.system("mv %s.org %s" % (self.ssl_conf, self.ssl_conf))

        if os.path.exists("/var/www/html/Test"):
            shutil.rmtree("/var/www/html/Test")
        if os.path.exists("%s" % self.httpd_conf):
            os.system("mv %s.org %s" % (self.httpd_conf, self.httpd_conf))
        try:
            utils.system("service httpd restart")
        except Exception as e:
            logging.error('\nhttpd failed to start')

    def postprocess(self):
        if self.nfail != 0:
            raise error.TestError('\nTest failed')
        else:
            logging.info('\nTest completed successfully')
