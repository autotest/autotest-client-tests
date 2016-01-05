#!/bin/python
import os
import time
import commands
import aexpect
import logging
import glob
import subprocess
from distutils.spawn import find_executable
from autotest.client import test, utils
from autotest.client.shared import error


class libteam(test.test):

    """
    libteam - Library for controlling team network device

    The purpose of the Team driver is to provide a mechanism to team multiple NICs (ports) into one logical one (teamdev) at L2 layer.
    The process is called "channel bonding", "Ethernet bonding", "channel teaming", "link aggregation", etc.
    This is already implemented in the Linux kernel by the bonding driver. libteam solve the same problem using a different approach
    @author Athira Rajeev<atrajeev@linux.vnet.ibm.com>

    """
    version = 2
    nfail = 0
    pid_stream = 0
    pid_conf = 0
    cleanup_iface = False
    teamd_p = 0
    teamd_conf_p = 0

    def install_check(self):
        """
        Install check for libteam library
        Check for teamnl and teamdctl
        """
        lib_files = glob.glob('/usr/lib*/libteam.so*')
        if not lib_files:
            raise error.TestError(
                '\nInstall check for library libteam.so failed')
        else:
            for file in lib_files:
                if not os.path.exists(file):
                    raise error.TestError(
                        '\nInstall check for library libteam.so failed')

        teamnl_exe = find_executable('teamnl')
        if teamnl_exe is None:
            raise error.TestError('\nteamnl not found')

        teamdctl_exe = find_executable('teamdctl')
        if teamdctl_exe is None:
            raise error.TestError('\nteamdctl not found')

    def start_teamd(self):
        """
        Start the teamd
        """

        self.teamd_p = subprocess.Popen("teamd")
        time.sleep(5)
        self.pid_stream = self.teamd_p.pid

    def stop_teamd(self):
        """
        stop teamd
                - which was started in start_teamd
                - which was started using specified configuration file
        """
        interface_out = utils.system_output("ip link")
        if "team0" in interface_out:
            utils.system_output("ip link del team0")
            time.sleep(5)
            self.teamd_p.terminate()
            self.teamd_p.wait()
            if os.path.exists("/proc/%d" % (self.pid_stream)):
                raise error.TestError('\n Failed to stop teamd stream process')

        if "team2" in interface_out:
            utils.system_output("ip link del team2")
            time.sleep(5)
            self.teamd_conf_p.wait()
            if os.path.exists("/proc/%d" % (self.pid_conf)):
                raise error.TestError('\n Failed to stop teamd -f process')

    def create_interface(self):
        """
        Create virtual interface
        Create interface veth0, veth1, veth2, veth3
        Verify if interface is created using ip link
        Create teamd conf file
        """

        utils.system("ip link add veth0 type veth peer name veth1")
        utils.system("ip link add veth2 type veth peer name veth3")

        interface_out = utils.system_output("ip link")
        if not all(x in interface_out for x in ['veth0', 'veth1', 'veth2', 'veth3']):
            self.nfail += 1
            raise error.TestError('\nSetup failed to create virtual interface')
        else:
            self.cleanup_iface = True

        f = open('%s/teamd_conf' % self.tmpdir, 'w')
        f.writelines("""
{
"device": "team2",
"runner": {"name": "roundrobin"},
"ports": {"veth1": {}, "veth0": {}}
}
""")

        f.close()

    def start_teamd_with_conf(self):
        """
        Specify configuration file for teamd
        Start teamd with -f option
        Verify team2 is created using ip command
        Verify the same using teamdctl
        Not using teamnl here as its covered in teamnl test
        """

        self.teamd_conf_p = subprocess.Popen(
            ['teamd', '-f' '%s/teamd_conf' % self.tmpdir])
        time.sleep(5)
        self.pid_conf = self.teamd_conf_p.pid
        if self.teamd_conf_p.poll() is not None:
            self.nfail += 1
            raise error.TestError('\nFailed to start teamd using -f option')

        teamd_out = utils.system_output("ip link")
        if "team2:" not in teamd_out:
            self.nfail += 1
            raise error.TestError(
                '\nFailed to start teamd with specified device')

        # verify using teamdctl
        out_state = utils.system_output("teamdctl team2 state")
        expected_out = """
ports:
  veth0
"""

        if (expected_out and "veth1") not in out_state:
            self.nfail += 1
            raise error.TestError(
                '\nteamcdtl failed to display veth0 and veth1 in state output')

    def teamdctl_test(self):
        """
        Testing teamdctl
        Verify teamdctl config dump
        Add ports using teamdctl port add
        Verify using teamdctl state
        verify this using ip command
        Also verify using teamnl
        Remove port and verify using ip command
        Verify ports are removed using teamnl as well
        """

        output = utils.system_output("teamdctl team0 config dump")
        expected_out = """
    "device": "team0",
    "runner": {
        "name": "roundrobin"
    }
"""
        if expected_out not in output:
            self.nfail += 1
            raise error.TestError('\nteamdctl config dump failed for team0')

        utils.system("teamdctl team0 port add veth2")
        out_ip = utils.system_output("ip link")
        for line in out_ip.splitlines():
            if "veth2:" in line:
                if "master team0" not in line:
                    self.nfail += 1
                    raise error.TestError(
                        '\nFailed to add veth2 using teamdctl to team0')

        out_state = utils.system_output("teamdctl team0 state")
        expected_out = """
ports:
  veth2
"""

        if expected_out not in out_state:
            self.nfail += 1
            raise error.TestError(
                '\nteamcdtl failed to display veth2 in state output')

        # Verify using teamnl

        teamnl_out = utils.system_output("teamnl team0 ports")
        if "veth2:" not in teamnl_out:
            self.nfail += 1
            raise error.TestError(
                '\n teamnl failed to display ports info for team0')

        utils.system("teamdctl team0 port remove veth2")

        out_ip = utils.system_output("ip link")
        for line in out_ip.splitlines():
            if "veth2:" in line:
                if "master team0" in line:
                    self.nfail += 1
                    raise error.TestError('\nteamdctl failed to remove veth2')

        teamnl_out = utils.system_output("teamnl team0 ports")
        if "veth2:" in teamnl_out:
            self.nfail += 1
            raise error.TestError(
                '\nteamdctl failed to remove veth2. teamnl still lists the port')

    def teamnl_test(self):
        """
        Test teamnl
        Switches tested:
                ports
                getoption
                item get
                setoption : setoption should fail if ports present
                            remove ports and try setoption
                monitor: change an option using "teamnl setoption" and
                          verify if monitor will report this.
        """
        teamnl_out = utils.system_output("teamnl team2 ports")
        if ("veth0:" and "veth1:") not in teamnl_out:
            self.nfail += 1
            raise error.TestError(
                '\n teamnl failed to display ports veth0 and veth1')

        teamnl_getopt = utils.system_output("teamnl team2 getoption mode")
        if "roundrobin" not in teamnl_getopt:
            self.nfail += 1
            raise error.TestError('\n teamnl getoption failed')

        # Verify this using teamdctl
        team_mode = utils.system_output(
            "teamdctl team0 state item get setup.kernel_team_mode_name")
        if "roundrobin" not in team_mode:
            self.nfail += 1
            raise error.TestError('\n teamdctl state item get failed')

        # Setoption using teamnl
        status, result = commands.getstatusoutput(
            "teamnl team2 setoption mode activebackup")
        if status == 0:
            self.nfail += 1
            raise error.TestError(
                '\n teamnl succeeded to setoption. No ports can be present during mode change')
        else:
            logging.info(
                '\n teamnl succeeded to identify no ports can be present during mode change.')

        # Remove ports and try
        utils.system("teamdctl team2 port remove veth0")
        utils.system("teamdctl team2 port remove veth1")

        # Testing monitor
        p = aexpect.Spawn('teamnl team2 monitor all')
        os.system("teamnl team2 setoption mode activebackup")
        teamnl_getopt = utils.system_output("teamnl team2 getoption mode")
        if "activebackup" not in teamnl_getopt:
            self.nfail += 1
            raise error.TestError('\n teamnl setoption failed')
        output_aexpect = p.get_output()
        p.close()
        if "mode activebackup changed" not in output_aexpect:
            self.nfail += 1
            raise error.TestError(
                '\n teamnl monitor failed to detect mode change')

    def test_usingifcfg(self):
        """
        Test teamd using ifcfg files
        Create ifcfg-team4 and veth3
        Bring up team device using ifup
        Verify this using ip command
        Verify using teamdctl and teamnl as well
        Bring down team device and verify using teamdctl
        """
        f = open('/etc/sysconfig/network-scripts/ifcfg-team4', 'w')
        f.writelines("""
DEVICE="team4"
DEVICETYPE="Team"
ONBOOT="yes"
BOOTPROTO=none
NETMASK=255.255.255.0
IPADDR=10.0.0.1
TEAM_CONFIG='{"runner": {"name": "roundrobin"}}'
NM_CONTROLLED="no"
""")
        f.close()

        f = open('/etc/sysconfig/network-scripts/ifcfg-veth3', 'w')
        f.writelines("""
DEVICE="veth3"
DEVICETYPE="TeamPort"
ONBOOT="yes"
TEAM_MASTER="team4"
NM_CONTROLLED="no"
""")

        f.close()

        utils.system('ifup team4')

        out_ip = utils.system_output("ip link")
        for line in out_ip.splitlines():
            if "veth3:" in line:
                if "master team4" not in line:
                    self.nfail += 1
                    raise error.TestError('\nifup team4 failed')

        out_state = utils.system_output("teamdctl team4 state")

        if "veth3" not in out_state:
            self.nfail += 1
            raise error.TestError(
                '\nteamdctl team4 state failed to show veth3 in output')

        teamnl_out = utils.system_output("teamnl team4 ports")
        if "veth3:" not in teamnl_out:
            self.nfail += 1
            raise error.TestError(
                '\n teamnl failed to display ports info for team4')

        teamnl_getopt = utils.system_output("teamnl team4 getoption mode")
        if "roundrobin" not in teamnl_getopt:
            self.nfail += 1
            raise error.TestError('\n teamnl getoption failed for team4')

        utils.system('ifdown team4')

        status, result = commands.getstatusoutput("teamdctl team4 state")
        if status == 0:
            self.nfail += 1
            raise error.TestError('\n ifdown team4 failed')
        else:
            logging.info('\n ifdown team4 succeeded.')

    def run_once(self):
        """
        Runs the test.
        """
        try:
            self.install_check()
            self.start_teamd()
            self.create_interface()
            self.start_teamd_with_conf()
            self.teamdctl_test()
            self.teamnl_test()
            self.test_usingifcfg()
            self.stop_teamd()
        finally:
            self.cleanup()

    def cleanup(self):
        """
        cleanup
        """

        self.stop_teamd()
        if self.cleanup_iface is True:
            self.cleanup_iface = False
            utils.system("ip link del veth0 type veth peer name veth1")
            utils.system("ip link del veth2 type veth peer name veth3")

    def postprocess(self):
        if self.nfail != 0:
            logging.info('\n nfails is non-zero')
            raise error.TestError('\nTest failed')
        else:
            logging.info('\n Test completed successfully')
