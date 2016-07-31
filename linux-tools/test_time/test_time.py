#!/bin/python

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See LICENSE for more details.
# Copyright: 2016 IBM
# Author: Basheer K<basheer@linux.vnet.ibm.com>

import re
import logging
import time
import os
from autotest.client import test, utils
from distutils.spawn import find_executable
from autotest.client.shared import error


class test_time(test.test):
    """
    Autotest module for time utility.
    time - time is a simple command,it gives resource usage.
    The time utility runs the specified program/command with the given
    arguments.When program/command finishes,time writes a message
    to standard error giving timing statistics about the command run.
    These statistics consist of
        (i)   The elapsed real time between invocation and termination,
        (ii)  The user CPU time , and
        (iii) The system CPU time.

    @author:Basheer Khadarsabgari <basheer@linux.vnet.ibm.com>
    """
    version = 1
    nfail = 0
    seconds = 2
    time_exe = ''
    output_file = ''

    def install_check(self):
        """
        Install check for time
        """
        self.time_exe = find_executable('time')
        if self.time_exe is None:
            raise error.TestError('time binary not found')

    def test_portability_option(self):
        """
        This method will verify the time portability(-p) option
        Ex: "/usr/bin/time -p sleep 2"
        """
        cmd = "%s -p sleep %s" % (self.time_exe, self.seconds)
        ret = utils.run(cmd)
        if re.search(
                "(real\s+%s.\d+)\nuser\s+\d+.\d+\nsys\s+\d.\d+" %
                self.seconds,
                ret.stderr):
            logging.info(
                "Verified '--portability' option successfully.")
        else:
            self.nfail += 1
            raise error.TestError(
                "Failed to verify --portability option of time utility")

    def test_format_option(self, cmd, expected_status):
        """
        This method will verify the time --format(-f) option
        Ex:/usr/bin/time -f "%x is Exit status of the cmd %C" <cmd>
        """
        cmd_to_execute = self.time_exe + \
            " -f '%x is the exit status of the cmd %C' " + cmd
        search_pattern = "%s is the exit status of the cmd %s" % (
            expected_status, cmd)
        ret = utils.run(cmd_to_execute, ignore_status=True)
        if search_pattern not in ret.stderr or \
           ret.exit_status != expected_status:
            self.nfail += 1
            raise error.TestError(
                "Failed to verify --format option of time, " +
                "exit status of the %s command using time utility."
                % cmd)
        else:
            logging.info(
                "Verified --format option of time, " +
                "exit status of %s command using time utility."
                % cmd)

    def test_output_option(self):
        """
        This method will verify the whether output file is
        created or not using '-o' option
        Ex:/usr/bin/time -o time_out.txt <cmd>
        """
        cmd_invoked = "sleep %s" % self.seconds
        self.output_file = '%s/time-output-%s' % (
            self.tmpdir, time.strftime('%Y-%m-%d-%H.%M.%S'))
        cmd = "%s -v -o %s %s" % (self.time_exe, self.output_file, cmd_invoked)
        utils.system(cmd)
        if os.path.exists(self.output_file) and \
           utils.file_contains_pattern(self.output_file, cmd_invoked):
            logging.info("Output file is created successfully using -o option")
        else:
            self.nfail += 1
            raise error.TestError(
                "Failed to create output file using -o option")

    def test_append_option(self):
        """
        This method will verify the --append option of time utility
        Ex:/usr/bin/time -v -a -o time_out.txt <cmd>
        """
        cmd_invoked = "pwd"
        cmd = "%s -v -a -o %s %s" % (self.time_exe,
                                     self.output_file, cmd_invoked)
        utils.system(cmd)
        if os.path.exists(self.output_file) and \
           utils.file_contains_pattern(self.output_file, cmd_invoked):
            logging.info(
                "Output is appended to the output file successfully" +
                " using -a option of time utility")
        else:
            self.nfail += 1
            raise error.TestError(
                "Failed to append the output to a file using -a option")

    def test_custom_script(self):
        """
        This method will test the custom shell script with the time utility
        create a custom shell script and provide it as input to the time
        Ex: /usr/bin/time -v <custom-script>
        """
        custom_script = "%s/custom_script.sh" % (self.tmpdir)
        fobj = open(custom_script, 'w')
        fobj.writelines("""
#!/bin/bash
echo "Hello, $LOGNAME"
echo "Current date is `date`"
echo "User is `who i am`"
echo "Current directory `pwd`"
""")
        fobj.close()
        cmd = "%s -v bash %s" % (self.time_exe, custom_script)
        ret = utils.run(cmd, ignore_status=True)
        if ret.exit_status and "Current date" not in ret.stdout:
            self.nfail += 1
            raise error.TestError(
                "Failed to execute custom script using time utility")
        else:
            logging.info(
                "verified execution of custom script using " +
                "time utility successfully")

    def run_once(self):
        """
        Runs the test.
        """
        try:
            self.install_check()
            self.test_portability_option()
            self.test_format_option("pwd", 0)
            self.test_format_option("pwd1", 127)
            self.test_format_option("host", 1)
            self.test_output_option()
            self.test_append_option()
            self.test_custom_script()
        finally:
            self.cleanup()

    def cleanup(self):
        """
        cleanup
        """
        pass

    def postprocess(self):
        if self.nfail != 0:
            logging.info('nfail is non-zero')
            raise error.TestError('Test failed')
        else:
            logging.info('Test completed successfully')
