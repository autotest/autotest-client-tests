#!/bin/python
import aexpect
import os
import time
import subprocess
import re
import logging
import glob
from distutils.spawn import find_executable
from autotest.client import test
from autotest.client.shared import error


class libndp(test.test):

    """
    libndp-Library for Neighbor Discovery Protocol,it is a part of
    the Internet Protocol suite used with IPv6.
    NDP Protocol make use of ICMPv6 messages and solicited-node
    multicast addresses for operating its core function, which is
    tracking and discovering other IPv6 hosts that are present on
    the other side of connected interfaces.

    libndp package contains a library and binary,
    libndp.so: provides a wrapper for IPv6 Neighbor Discovery Protocol.
    ndptool : Tool for sending and receiving NDP messages.

    @author Ramya BS <ramya@linux.vnet.ibm.com>

    """
    version = 2
    nfail = 0
    interface = subprocess.Popen(
        ["ip", "-6", "route", "show", "default"], stdout=subprocess.PIPE)
    interface_out = interface.stdout.read()
    get_active_interface = re.search(
        "default via\s+\S+\s+dev\s+(\w+)\s+proto", interface_out)
    iface = get_active_interface.group(1)
    get_ipv6_addr = subprocess.Popen(
        ["ip", "addr", "show", "dev", "%s" % iface], stdout=subprocess.PIPE)
    get_ipv6_addr_out = get_ipv6_addr.stdout.read()
    ipv6_addr = re.search(
        "inet6\s+(fe80.*)\s+scope",
        get_ipv6_addr_out).group(1).strip("/64")
    ns = "Type: NS"
    rs = "Type: RA"

    def install_check(self):
        """
        install check for libndp library and ndptool binary
        check for ip ,route ,tcpdump
        """

        if self.iface is None:
            raise error.TestError('\n ipv6 is not configured on this system')
        lib_files = glob.glob('/usr/lib*/libndp.so*')
        if not lib_files:
            raise error.TestError(
                '\n Install check for library libndp.so failed')
        else:
            for file in lib_files:
                if not os.path.exists(file):
                    raise error.TestError(
                        '\n Failed to find libndp.so library')
        executable_files = ['ndptool', 'route', 'tcpdump', 'ip']
        for exe in executable_files:
            if find_executable(exe) is None:
                raise error.TestError('%s not found' % exe)

    def monitor_ndp_messages(self):
        """
        Monitors incoming NDP messages(RS and NS) on specified interface
        and cross verify received messages using tcpdump output.
        """
        tcpdump = aexpect.Spawn("tcpdump -n -i %s icmp6" % self.iface)
        monitor_ndp = aexpect.Spawn("ndptool monitor -i %s" % self.iface)
        os.system("ndptool send -t ns -i %s" % self.iface)
        os.system("ndptool send -t rs -i %s" % self.iface)
        time.sleep(5)
        tcpdump_output = tcpdump.get_output()
        tcpdump.close()
        monitor_ndp_output = monitor_ndp.get_output()
        monitor_ndp.close()
        if self.ipv6_addr not in tcpdump_output and monitor_ndp_output:
            self.nfail += 1
            raise error.TestError(
                '\n ndptool failed to monitor NDP messages')
        else:
            logging.info(
                '\n ndptool successfully monitored NDP messages')

    def Monitor_only_ns_messages(self):
        """
        Filtering incoming NDP messages to monitor only messages
        of type Neighbor Solicitation (NS).
        """
        monitor_ndp = aexpect.Spawn(
            "ndptool monitor -i %s -t ns " %
            self.iface)
        os.system("ndptool send -t ns -i %s" % self.iface)
        os.system("ndptool send -t rs -i %s" % self.iface)
        time.sleep(5)
        monitor_ndp_output = monitor_ndp.get_output()
        monitor_ndp.close()
        if self.ns in monitor_ndp_output and self.rs not in monitor_ndp_output:
            logging.info(
                '\n ndptool successfully captured only messages of type Neighbor Solicitation')
        else:
            self.nfail += 1
            raise error.TestError(
                '\n ndptool failed to capture only  messages of type Neighbor Solicitation')

    def send_mess_type_rs(self):
        """
        Sending message of type RS and monitor it using ndptool
        """
        monitor_ndp = aexpect.Spawn("ndptool monitor -i %s" % self.iface)
        os.system("ndptool send -t rs -i %s" % self.iface)
        time.sleep(5)
        monitor_ndp_output = monitor_ndp.get_output()
        monitor_ndp.close()
        if self.rs in monitor_ndp_output:
            logging.info(
                '\n ndptool successfully sent message of type RS')
        else:
            self.nfail += 1
            raise error.TestError(
                '\n ndptool failed to send message of type RS')

    def send_mess_type_ns(self):
        """
        Sending message of type NS and monitor it using ndptool.
        """
        monitor_ndp = aexpect.Spawn("ndptool monitor -i %s" % self.iface)
        os.system("ndptool send -t ns -i %s" % self.iface)
        time.sleep(5)
        monitor_ndp_output = monitor_ndp.get_output()
        monitor_ndp.close()
        if self.ns in monitor_ndp_output:
            logging.info(
                '\n ndptool successfully sent message of type NS')
        else:
            self.nfail += 1
            raise error.TestError(
                '\n ndptool failed to send message of type NS')

    def run_once(self):
        """
        Runs the test.
        """
        try:
            self.install_check()
            self.monitor_ndp_messages()
            self.Monitor_only_ns_messages()
            self.send_mess_type_rs()
            self.send_mess_type_ns()
        finally:
            self.cleanup()

    def cleanup(self):
        """
        cleanup
        """
        pass

    def postprocess(self):
        if self.nfail != 0:
            logging.info('\n nfails is non-zero')
            raise error.TestError('\nTest failed')
        else:
            logging.info('\n Test completed successfully')
