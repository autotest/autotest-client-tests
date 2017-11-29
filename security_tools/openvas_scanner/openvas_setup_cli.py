#!/usr/bin/env python

"""
The contents of this file are classes and functions for OPENVAS cli setup.
The automation script will be used to setup repo, install the required package,
download and setup the vulnerability database from openvas server, certificate setup and
prechecks before the actual scan on local system..
setup script will take around 40-50 min to complete all processes.
Scan will be triggered from autotest as well
Author: Anup Kumar <anupkumk@linux.vnet.ibm.com>

"""
import re
import sys
import os
import time
import logging
import pexpect
from time import sleep
from ConfigParser import SafeConfigParser


#######################################
#    OPENVAS EXCEPTION CLASSES        #
#######################################


class Error(Exception):

    """Base class for OMP errors."""

    def __str__(self):
        return repr(self)


class ErrorResponse(Error):

    def __init__(self, msg="", *args):
        self.message = msg
        Error.__init__(*args)

    def __str__(self):
        return self.message


class ClientError(ErrorResponse):
    """command execution error,made by the client"""


class ServerError(ErrorResponse):
    """command processing error by manager"""


class ResultError(Error):
    """Get invalid answer from Server"""

    def __str__(self):
        return 'Result Error: answer from command %s is invalid' % self.args


class NvtError(ErrorResponse):
    """command processing error by scanner"""


class CertError(ErrorResponse):
    """command processing error by scanner"""


######################################
#     HIGH LEVEL EXCEPTION CLASSES    #
######################################


class OpenVasException(Exception):
    """Base class for OpenVAS exceptions."""


class OpenVasServerError(OpenVasException):
    """Error message from the OpenVAS server."""


class OpenVasClientError(OpenVasException):
    """Error message from the OpenVAS client."""


class OpenVasProfileError(OpenVasException):
    """Profile error."""


class OpenVasTargetError(OpenVasException):
    """Target related errors."""


class OpenVasScanError(OpenVasException):
    """Task related errors."""


class OpenVasTaskNotFinishedError(OpenVasException):
    """Task not finished"""


class OpenVasNvtDownloadError(OpenVasException):
    """Nvt Downloading error"""


class OpenVasCertDownloadError(OpenVasException):
    """Certificate Downloading error"""


##########################################
# OPENVAS SETUP FOR ALL ARCH             #
##########################################

class openvas_setup_cli(object):

    def __init__(self):

        self.output_file = 'output_file'
        self.u_name = 'admin'
        self.u_pass = 'man@twork17'

    def client_omp_config(self):
        """
        File will use to setup the scan on localhost target
        """
        user_check = os.popen("whoami").read().rstrip('\n')
        if user_check == "root":
            omp_config = 'Connection'
            logging.info("Creating omp config file")
            with open('omp.config', 'wb') as config_fh:
                pr1 = SafeConfigParser()
                pr1.add_section(omp_config)
                pr1.set(omp_config, 'host', "localhost")
                pr1.set(omp_config, 'port', "9390")
                pr1.set(omp_config, 'username', self.u_name)
                pr1.set(omp_config, 'password', self.u_pass)
                pr1.write(config_fh)
                config_fh.close()

            if not os.path.exists("/root/omp.config"):
                logging.debug("Copy omp configuration to root")
                os.system("cp omp.config /root/")

        else:
            logging.debug(
                "Aborting the scan due to unavailability of root user")
            sys.exit()

    def get_arch_os_version(self):
        """
        Function will return the os version wrt to centos and arch

        """
        self.check_sepolicy = os.popen("getenforce").read().rstrip('\n')
        if self.check_sepolicy == "Enforcing":
            os.system("setenforce 0")
            logging.info(
                "Selinux policy turning to Permissive for openvas scan")
        try:
            self.arch_os_ver = []
            f1 = os.popen("cat /etc/os-release").read()
            d_name = re.search('ID="(\S+)"', f1).group(1)
            v_id = re.search('VERSION_ID="(\S+)"', f1).group(1)
            check_arch = os.popen(
                "uname -r").read().rstrip('\n').split('.')[-1]
            ref_vid = str(float(v_id) + 1)
            ref_full_name = "".join([d_name, ref_vid])
            arch_os_ver = [ref_full_name, check_arch]
            full_name = "".join([d_name, v_id])
            self.full_project = "-".join([full_name, check_arch])
            return arch_os_ver

        except (TypeError, ValueError) as e:
            self.logging.warning("Invalid Project configuration file")
            self.logging.debug(e)

    def openvas_repo_setup(self):
        """
        Function will setup the repo for openvas8 (epel repo)
        and openvas 9 (atomic)

        """
        key_dir = os.getcwd()
        self.arch_os_ver = self.get_arch_os_version()
        system_os = self.arch_os_ver[0]
        distro_os_ref = int(re.search(r'\d+', system_os).group()) - 1
        arch = self.arch_os_ver[1]

        # setting centos repo for openvas 9, it install openvas realted
        # dependency

        if arch in ("x86_64", "ia32", "ppc64le", "ppc64"):
            cust_repo = 'CentOS'
            set_arch = ' '
            logging.info("Setting the centos repo")
            if os.path.isfile("/etc/yum.repos.d/centos.repo"):
                os.system(
                    "mv /etc/yum.repos.d/centos.repo /etc/yum.repos.d/centos.repo_org")
            fh = open('/etc/yum.repos.d/centos.repo', 'w')
            cent_par = SafeConfigParser()
            cent_par.add_section(cust_repo)
            cent_par.set(cust_repo, 'name', 'centos')
            if arch == 'x86_64':
                cent_par.set(
                    cust_repo, 'baseurl', 'http://mirror.centos.org/centos/%s/os/%s/' %
                    (distro_os_ref, arch))
            else:
                if arch == 'ia32':
                    set_arch = 'i386'
                else:
                    set_arch = arch
                cent_par.set(
                    cust_repo, 'baseurl', 'http://mirror.centos.org/altarch/%s/os/%s/' %
                    (distro_os_ref, set_arch))
            cent_par.set(cust_repo, 'enabled', '1')
            cent_par.set(cust_repo, 'gpgcheck', '0')
            cent_par.write(fh)
            fh.close()

        # setting openvas repo
        try:

            # setting repo for
            if arch is None:
                logging.debug(err)("Arch not listing")

            elif arch in ("x86_64", "ia32"):
                # setting the atomic repo
                cust_repo = 'atomic'
                logging.info("Setting the atomic repo")
                if os.path.isfile("/etc/yum.repos.d/atomic.repo"):
                    os.system(
                        "mv /etc/yum.repos.d/atomic.repo /etc/yum.repos.d/atomic.repo_org")

                if arch == 'ia32':
                    arch_flag = 'i386'
                    set_distro_os_ref = 6.5
                else:
                    arch_flag = 'x86_64'
                    set_distro_os_ref = distro_os_ref
                # Now setting the atomic repo
                fp = open('/etc/yum.repos.d/atomic.repo', 'w')
                parser = SafeConfigParser()
                parser.add_section(cust_repo)
                parser.set(
                    cust_repo,
                    'name',
                    'CentOS / Red Hat Enterprise Linux $releasever - atomic')
                parser.set(
                    cust_repo,
                    'mirrorlist',
                    'http://updates.atomicorp.com/channels/mirrorlist/atomic/centos-%s-%s' %
                    (set_distro_os_ref, arch_flag))

                parser.set(cust_repo, 'enabled', '1')
                parser.set(cust_repo, 'protect', '0')
                parser.set(
                    cust_repo, 'gpgkey', 'file:%s/RPM-GPG-KEY.art.txt'
                    '  file:%s/RPM-GPG-KEY.atomicorp.txt' %
                    (key_dir, key_dir))

                parser.set(cust_repo, 'gpgcheck', '1')
                parser.write(fp)
                fp.close()
                logging.info("Installing the Atomic GPG keys")
                if not os.path.isfile("RPM-GPG-KEY.art.txt"):
                    try:
                        os.system(
                            "wget -q https://www.atomicorp.com/RPM-GPG-KEY.art.txt")
                    except IOError as err:
                        logging.debug(err)

                if not os.path.isfile("RPM-GPG-KEY.atomicorp.txt"):
                    try:
                        os.system(
                            "wget -q https://www.atomicorp.com/RPM-GPG-KEY.atomicorp.txt")
                    except IOError as err:
                        logging.debug(err)

                logging.info("Initiating the atomic Repo")

            elif arch in ("ppc64le", "ppc64", "ppc"):
                # setting the epel repo
                logging.info("Setting the epel repo")
                cust1_repo = 'epel'
                if os.path.isfile("/etc/yum.repos.d/epel.repo"):
                    os.system(
                        "mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo_org")

                fp1 = open('/etc/yum.repos.d/epel.repo', 'w')
                parser1 = SafeConfigParser()
                parser1.add_section(cust1_repo)
                parser1.set(
                    cust1_repo,
                    'name',
                    'Extra Packages for Enterprise Linux %s - $basearch' %
                    (distro_os_ref))
                parser1.set(
                    cust1_repo,
                    'mirrorlist',
                    'https://mirrors.fedoraproject.org/metalink?repo=epel-%s&arch=$basearch' %
                    (distro_os_ref))

                parser1.set(cust1_repo, 'failovermethod', 'priority')
                parser1.set(cust1_repo, 'enabled', '1')
                parser1.set(
                    cust1_repo,
                    'gpgkey',
                    'file:%s/RPM-GPG-KEY-EPEL' %
                    key_dir)
                parser1.set(cust1_repo, 'gpgcheck', '1')
                parser1.write(fp1)
                fp1.close()
                logging.info("Initiating the epel Repo")

            elif arch in "s390x":
                # setting the fedora repo
                logging.info("Setting the fedora 24 repo")
                cust2_repo = 'fedora'
                if os.path.isfile("/etc/yum.repos.d/fedora.repo"):
                    os.system(
                        "mv /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora.repo_org")

                fp2 = open('/etc/yum.repos.d/fedora.repo', 'w')
                parser2 = SafeConfigParser()
                parser2.add_section(cust2_repo)
                parser2.set(cust2_repo, 'name', 'Fedora 22 - $basearch')
                parser2.set(
                    cust2_repo,
                    '#baseurl',
                    'http://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/')
                parser2.set(
                    cust2_repo,
                    'metalink',
                    'https://mirrors.fedoraproject.org/metalink?repo=fedora-22&arch=$basearch')
                parser2.set(cust2_repo, 'failovermethod', 'priority')
                parser2.set(cust2_repo, 'enabled', '1')
                parser2.set(
                    cust2_repo, 'gpgkey', 'file:%s/RPM-GPG-KEY-fedora-22'
                    '      file:%s/RPM-GPG-KEY-fedora-22_sec' %
                    (key_dir, key_dir))
                parser2.set(cust2_repo, 'gpgcheck', '1')
                parser2.set(cust2_repo, 'skip_if_unavailable', 'False')
                parser2.write(fp2)
                fp2.close()
                logging.info("Initiating the Fedora Repo")

            os.system("yum clean all > %s" % self.output_file)
            os.system("yum repolist > %s" % self.output_file)
            time.sleep(10)

        except IOError as err:
            logging.info("Repo failed to setup")
            logging.debug(err)
            sys.exit()

    def install_openvas_pkg(self, reinstall=0):
        """
        Function will install openvas related packages
        """
        check_arch = self.arch_os_ver[1]
        logging.info("Installing the required package")

        pkg_list = (
            "sqlite3",
            "redis",
            "gnutls",
            "libksba",
            "libssh",
            "curl",
            "rsync",
            "nmap",
            "openvas-cli",
            "greenbone-security-assistant",
            "pexpect",
            "openvas-libraries",
            "openvas-smb",
            "openvas-manager",
            "openvas-scanner",
            "openvas-gsa")

        for pkg in pkg_list:
            os.system(
                "yum %s -y %s >%s" %
                (('install', 'reinstall')[reinstall], pkg, self.output_file))

        if check_arch in "x86_64":
            # Libssh issue with openvas 9
            #b_dir = os.getcwd()
            #os.system("cp %s/libssh/libssh.so.4.5.0 /usr/lib/" % b_dir)
            #os.system("ln -s /usr/lib/libssh.so.4.5.0 /usr/lib/libssh.so.4")
            v9_pkg = (
                "openvas-libraries",
                "openvas-cli",
                "openvas-manager",
                "openvas-scanner",
                "greenbone-security-assistant")
            for pkg in v9_pkg:
                os.system("yum reinstall -y %s >%s" % (pkg, self.output_file))

        elif check_arch in "ia32":
            os.system("yumdownloader openvas-cli")
            full_name = os.popen("ls openvas-cli*").read().rstrip('\n')
            os.system("rpm -ivh %s --nodeps" % full_name)
            # private directory should be available to download nvt
            if not os.path.isdir("/var/lib/openvas/plugins/private"):
                os.system("mkdir /var/lib/openvas/plugins/private")

        elif check_arch in "s390x":

            local_pkgs = (
                "libgcrypt",
                "libksba",
                "openvas-cli",
                "openvas-libraries",
                "openvas-manager",
                "openvas-scanner",
                "openvas-gsa")
            for rpm_pkg in local_pkgs:
                os.system("yumdownloader %s" % rpm_pkg)
                full_name = os.popen(
                    "ls %s*| grep -i s390x" %
                    rpm_pkg).read().rstrip('\n')
                os.system("rpm -ivh %s --nodeps" % full_name)
                os.system("rm %s" % full_name)

            if not os.path.isdir("/private"):
                os.system("mkdir /private")
            if not os.path.isdir("/var/lib/openvas/plugins/private"):
                os.system("mkdir /var/lib/openvas/plugins/private")

        time.sleep(10)

    def check_openvas_services(self, restart=0):
        """
        check redis, openvas-scanner,openvas-manager and running on proper port
        if not restart this
        """
        openvas_services = (
            "redis",
            "openvas-scanner",
            "openvas-manager",
            "gsad",
            "openvas-gsa")
        logging.info("check the openvas related services on correct port")
        for ov_service in openvas_services:
            #os.system("systemctl enable %s" %ov_service)
            cmd_service = os.system(
                "systemctl %s %s >%s" %
                (("start", "restart")[restart], ov_service, self.output_file))

            if cmd_service == 0:
                logging.info("Service %s in stated state" % ov_service)
                if ov_service == "openvas-manager":
                    md_port_check = os.system(
                        "netstat -npl | grep -i openvasmd | grep -i 9390")
                    if md_port_check == 0:
                        logging.info("%s is running on port 9390" % ov_service)
                    else:
                        logging.debug(
                            "restarting %s on correct port" %
                            ov_service)
                        os.popen("openvasmd -p 9390 -a 127.0.0.1")

    def openvas_data_setup(self, restart=0):

        try:
            if os.path.exists("/etc/redis.conf"):
                os.system("cp /etc/redis.conf /etc/redis.conf_org")
                with open("/etc/redis.conf", "a") as file:
                    file.writelines("unixsocket /tmp/redis.sock \n")
                    file.close()

        except FileNotFoundError:
            logging.debug(err)

        logging.info("Downloading/Updating NVT, CERT, and SCAP data")
        default_downloader = 'rsync'
        check_greenbone = os.system(
            "rpm -qa | grep -i greenbone >%s" %
            self.output_file)

        if check_greenbone == 0:
            g_nvt_sync = os.popen("which greenbone-nvt-sync").read()
            g_cert_sync = os.popen("which greenbone-certdata-sync").read()
            g_scap_sync = os.popen("which greenbone-scapdata-sync").read()
            v9_scan_sync_data = (g_nvt_sync, g_cert_sync, g_scap_sync)

            for sync_data in v9_scan_sync_data:
                logging.info("Downloading Data from %s script" % sync_data)

                try:
                    rsync_cert_sync = os.system(
                        "%s --%s" %
                        (sync_data, default_downloader))
                    if rsync_cert_sync is not None:
                        default_downloader = 'wget'
                        wget_cert_sync = os.system(
                            "%s --%s" %
                            (sync_data, default_downloader))
                        if wget_cert_sync is not None:
                            default_downloader = 'http'
                            os.system(
                                "%s --%s" %
                                (sync_data, default_downloader))
                    time.sleep(10)

                except NvtError as e:
                    raise OpenVasNvtDownloadError(
                        "Can't download the Nvt form %s sync. Error: %s" %
                        (sync_data, e.message))

            if not os.path.exists('/var/lib/openvas/CA/cacert.pem'):
                logging.info("Managing Certificate")
                try:
                    os.system("openvas-manage-certs -a")
                    time.sleep(120)
                except CertError as e:
                    raise OpenVasCertDownloadError("Error: %s" % e.message)
            os.system(
                "systemctl %s %s >%s" %
                (("start", "restart")[restart], 'redis', self.output_file))
            os.system(
                "systemctl %s %s >%s" %
                (("start", "restart")[restart], 'openvas-scanner', self.output_file))
            logging.info("Pausing while openvas-scanner loads NVTs...")
            time.sleep(20)
            os.system("openvasmd --migrate")
            os.system(
                "systemctl %s %s >%s" %
                (("start", "restart")[restart], 'openvas-manager', self.output_file))
            time.sleep(20)
            os.system("openvasmd --update --progress")

        else:
            o_nvt_sync = os.popen("which openvas-nvt-sync").read()
            o_cert_sync = os.popen("which openvas-certdata-sync").read()
            o_scap_sync = os.popen("which openvas-scapdata-sync").read()
            v8_scan_sync_data = (o_nvt_sync, o_cert_sync, o_scap_sync)
            for sync_data in v8_scan_sync_data:
                logging.info("Downloading Data from %s script" % sync_data)

                try:
                    rsync_cert_sync = os.system(
                        "%s --%s" %
                        (sync_data, default_downloader))
                    if rsync_cert_sync is not None:
                        default_downloader = 'wget'
                        wget_cert_sync = os.system(
                            "%s --%s" %
                            (sync_data, default_downloader))
                        if wget_cert_sync is not None:
                            default_downloader = 'http'
                            os.system(
                                "%s --%s" %
                                (sync_data, default_downloader))
                    time.sleep(10)

                except NvtError as e:
                    raise OpenVasNvtDownloadError(
                        "Can't download the Nvt form %s sync. Error: %s" %
                        (sync_data, e.message))

            # download certificate
            logging.info("Creating the Scanner Certificate")
            try:

                if not (os.path.exists('/etc/pki/openvas/CA/cacert.pem')
                        or os.path.exists('/var/lib/openvas/CA/cacert.pem')):
                    child = pexpect.spawn('openvas-mkcert')
                    child.expect('CA certificate .*: ')
                    child.sendline('1000')
                    child.expect('Server certificate life .*: ')
                    child.sendline('365')
                    child.expect('Your country .*: ')
                    child.sendline('IN')
                    child.expect('Your state .*: ')
                    child.sendline('none')
                    child.expect('Your location .*: ')
                    child.sendline('bang')
                    child.expect('Your organization .*: ')
                    child.sendline('ibm')
                    child.expect('Press .* ')
                    child.sendline(' ')

                logging.info("Creating Client Certificate")
                os.system("openvas-mkcert-client -n -i")
                time.sleep(120)

            except CertError as e:
                raise OpenVasCertDownloadError("Error: %s" % e.message)
            os.system(
                "systemctl %s %s >%s" %
                (("start", "restart")[restart], 'redis', self.output_file))
            os.system(
                "systemctl %s %s >%s" %
                (("start", "restart")[restart], 'openvas-scanner', self.output_file))
            logging.info("Pausing while openvas-scanner loads NVTs...")
            time.sleep(20)
            os.system("openvasmd --rebuild --progress -v")
            os.system(
                "systemctl %s %s >%s" %
                (("start", "restart")[restart], 'openvas-manager', self.output_file))
        time.sleep(20)
        os.system(
            "openvasmd  --create-user='%s' >%s" %
            (self.u_name, self.output_file))
        os.system("openvasmd  --user='%s' --new-password='%s' >%s" %
                  (self.u_name, self.u_pass, self.output_file))

    def verify_setup(self):
        """
        Check the installation setup
        """
        ch_arch = self.arch_os_ver[1]
        if ch_arch not in ("ia32", "s390x"):
            install_log = "setup_log"
            error_file = "setup_error_log"
            str1 = "Greenbone Security Assistant"
            str2 = "ERROR: Your OpenVAS-"
            str3 = "ERROR: No OpenVAS SCAP database"
            str4 = "ERROR: The number of NVTs"
            str5 = "ERROR: SELinux is enabled"
            match = 0

            setup_check = os.system(
                "rpm -qa | grep -i greenbone >%s" %
                self.output_file)
            if setup_check == 0:
                command = "openvas-check-setup --v9"
            else:
                command = "openvas-check-setup"

            os.system("/bin/bash %s > %s" % (command, install_log))
            os.system("cat %s | grep 'ERROR' >%s" % (install_log, error_file))
            with open(error_file) as fh:

                for line in fh:
                    if str1 in line or str2 in line or str5 in line:
                        continue
                    elif str3 in line:
                        check_scap = os.system(
                            "which openvas-scapdata-sync >%s" %
                            self.output_file)
                        if check_scap == 0:
                            os.system("openvas-scapdata-sync")
                        else:
                            os.system("greenbone-scapdata-sync")
                    elif str4 in line:
                        os.system("openvasmd --rebuild")
                    else:
                        match += 1
                    time.sleep(10)
            if match >= 1:
                logging.debug("openvas setup is not completed")
                sys.exit()
