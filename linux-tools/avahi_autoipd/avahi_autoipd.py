#!/bin/python
import commands
import aexpect
import logging
import time
import subprocess
from distutils.spawn import find_executable
from autotest.client import test, utils
from autotest.client.shared import error


class avahi_autoipd(test.test):

    """
    avahi-autoipd - IPv4LL network address configuration daemon

    avahi-autoipd implements IPv4LL, "Dynamic Configuration of IPv4 Link-Local Addresses" (IETF RFC3927),
    a protocol for automatic IP address configuration from the link-local 169.254.0.0/16 range
    without the need for a central server. It is primarily intended to be used in ad-hoc networks which lack a DHCP server

    The package provides avahi-autoipd binary

    @author Athira Rajeev<atrajeev@linux.vnet.ibm.com>

    """
    version = 2
    nfail = 0
    ip_addr = None
    log_messages = "/var/log/messages"
    cleanup_iface = 0

    def install_check(self):
        """
        Install check for avahi-autoipd
        """
        avahi_autoipd_exe = find_executable('avahi-autoipd')
        if avahi_autoipd_exe is None:
            raise error.TestError('\n avahi-autoipd not found')

    def start_avahi_autoipd(self):
        """
        Start avahi-autoipd on veth0
        verify ip by logging in with the ip
        and check using ip command
        """

        subprocess.Popen("avahi-autoipd veth0 1>%s/out 2>%s/err &" % (self.tmpdir,
                                                                      self.tmpdir), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(15)
        result = open("%s/err" % self.tmpdir, "r").readlines()
        for line in result:
            if "Successfully claimed IP address" in line:
                self.ip_addr = line.split()[-1]

        if self.ip_addr is None:
            self.nfail += 1
            raise error.TestError('\n avahi-autoipd failed to assign veth0 ip')
        else:
            logging.info('\nIP assigned is %s' % self.ip_addr)

        pass_word = utils.system_output("openssl passwd -crypt password")
        utils.system("useradd testuser -p %s" % pass_word)

        p = aexpect.ShellSession("ssh testuser@%s" % self.ip_addr)
        time.sleep(5)

        if "Are you sure you want to continue connecting" in p.get_output():
            p.sendline("yes")
            time.sleep(5)
            if "password:" in p.get_output():
                p.sendline("password")
            else:
                raise error.TestError(
                    '\n Failed to login giving password to avahi-autoipd ip')
        elif "password:" in p.get_output():
            p.sendline("password")
        else:
            print p.get_output()
            raise error.TestError('\n Failed to login to avahi-autoipd ip')

        print p.get_output()
        status, output = p.get_command_status_output(
            "ip addr show veth0|grep -w inet")
        if self.ip_addr not in output:
            self.nfail += 1
            raise error.TestError('\n avahi-autoipd failed to assign valid ip')
        p.close()

    def stop_avahi(self):
        """
        stop avahi using -k option
        """

        utils.system("avahi-autoipd -k veth0")
        status, ip_out = commands.getstatusoutput(
            "ip addr show veth0 | grep -w inet")
        if self.ip_addr in ip_out:
            self.nfail += 1
            raise error.TestError('\n avahi-autoipd -k failed')

    def create_interface(self):
        """
        Create virtual interface
        Create interface veth0, veth1
        Verify if interface is created using ip link
        """

        utils.system("ip link add veth0 type veth peer name veth1")

        interface_out = utils.system_output("ip link")
        if not all(x in interface_out for x in ['veth0', 'veth1']):
            self.nfail += 1
            raise error.TestError('\nSetup failed to create virtual interface')
        else:
            self.cleanup_iface = 1

    def avahi_syslog(self):
        """
        clear /var/log/messages
        Start avahi-autoipd using -s
        Verify /var/log/messages is populated with the data
        """

        utils.system("echo > %s" % self.log_messages)
        utils.system("avahi-autoipd -s veth0 &")
        time.sleep(15)

        self.ip_addr = None
        result = open(self.log_messages, "r").readlines()
        for i in result:
            if "Successfully claimed IP address" in i:
                self.ip_addr = i.split()[-1]
        if self.ip_addr is None:
            self.nfail += 1
            raise error.TestError('\n avahi-autopid -s failed')
        else:
            logging.info(
                '\n ip address using avahi-autoipd -s is %s' % self.ip_addr)

        self.stop_avahi()

    def avahi_daemon(self):
        """
        Start avahi-autoipd with -D option
        Check if the daemon is already running using -c
        Request daemon refresh IP address using -r
        start avahi-autoipd using -S and address option
        """

        utils.system("avahi-autoipd -D veth0")
        time.sleep(10)

        status, output = commands.getstatusoutput("avahi-autoipd -c veth0")
        if status != 0:
            self.nfail += 1
            raise error.TestError('\n avahi-autoipd -c failed')

        utils.system("echo > %s" % self.log_messages)

        reannounce_status = None
        utils.system("avahi-autoipd -r veth0")
        time.sleep(10)

        result = open(self.log_messages, "r").readlines()
        for line in result:
            if "Reannouncing address" in line:
                reannounce_status = 1
        if reannounce_status is None:
            self.nfail += 1
            raise error.TestError('\n avahi-autopid -r failed')
        else:
            logging.info('\n avahi-autoipd -r passed')

        self.stop_avahi()

    def assign_address(self):
        """
        start avahi-autoipd using -S and address option
        """

        utils.system_output("avahi-autoipd -S 169.254.8.224 veth0 &")
        time.sleep(10)

        status, ip_out = commands.getstatusoutput(
            "ip addr show veth0 | grep -w inet")
        if "169.254.8.224" not in ip_out:
            self.nfail += 1
            raise error.TestError('\n avahi-autopid -S failed')
        else:
            logging.info('\n avahi-autoipd -S passed')

        self.stop_avahi()

    def force_bind(self):
        """
        Force bind
        Assign a routable address to the interface.
        Run avahi-autoipd which should not assign IP as already address is configured on the interface
        force-bind will assign the IP.
        Verify using ip command
        """

        utils.system("ip addr add 192.168.122.2 dev veth0")

        utils.system("echo > %s" % self.log_messages)
        utils.system("avahi-autoipd -s veth0 &")

        time.sleep(10)

        force_bind_fail = None
        result = open(self.log_messages, "r").readlines()
        for i in result:
            if "Routable address already assigned, sleeping" in i:
                force_bind_fail = 1

        if force_bind_fail is None:
            self.nfail += 1
            raise error.TestError(
                '\n avahi-autopid assigned ip evenif routable address was configured')

        self.stop_avahi()

        utils.system_output(
            "avahi-autoipd -S 169.254.8.224 --force-bind veth0 &")
        time.sleep(10)

        status, ip_out = commands.getstatusoutput(
            "ip addr show veth0 | grep -w inet")
        if "169.254.8.224" not in ip_out:
            self.nfail += 1
            raise error.TestError('\n avahi-autopid --force-bind failed')
        else:
            logging.info('\n avahi-autoipd --force-bind passed')

        self.stop_avahi()

    def run_once(self):
        """
        Runs the test.
        """
        try:
            self.install_check()
            self.create_interface()
            self.start_avahi_autoipd()
            self.stop_avahi()
            self.avahi_syslog()
            self.avahi_daemon()
            self.assign_address()
            self.force_bind()

        finally:
            self.cleanup()

    def cleanup(self):
        """
        cleanup
        """

        rc, status = commands.getstatusoutput("id -u testuser")
        if rc == 0:
            utils.system("userdel -r testuser")
        if self.cleanup_iface != 0:
            self.cleanup_iface = 0
            utils.system("ip link del veth0 type veth peer name veth1")

    def postprocess(self):
        if self.nfail != 0:
            logging.info('\n nfails is non-zero')
            raise error.TestError('\nTest failed')
        else:
            logging.info('\n Test completed successfully')
