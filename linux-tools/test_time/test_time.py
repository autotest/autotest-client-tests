#!/bin/python
import re
import commands
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
        (iii) The system CPU time .

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
            raise error.TestError('\n time utility not found')

    def test_portability_option(self):
        """
        This method will verify the time utility output Format
        Ex: "/usr/bin/time -p sleep 2"
        """
        cmd = "%s -p sleep %s" % (self.time_exe, self.seconds)
        time_output = commands.getoutput(cmd)
        if re.search(
                "(real\s+%s.\d+)\nuser\s+\d+.\d+\nsys\s+\d.\d+" %
                self.seconds,
                time_output):
            logging.info(
                "\n Verified '--portability' option successfuly.")
        else:
            self.nfail += 1
            raise error.TestError(
                "\n Failed to verify --portability option of time utility")

    def test_exit_status_of_cmd(self, cmd, expected_status):
        """
        This method will verify the exit status of the command invoked
        using time utility.
        Ex:/usr/bin/time -f "%x is Exit status of the cmd %C" <cmd>
        """
        cmd_to_execute = "%s " % self.time_exe + \
            " -f '%x is the Exit status of the cmd %C' " + cmd
        search_pattren = "%s is the Exit status of the cmd %s" % (
            expected_status, cmd)
        time_output = commands.getoutput(cmd_to_execute)
        if re.search("%s" % search_pattren, time_output):
            logging.info(
                "\n Verified Exit status using of the command '%s'" % cmd +
                " using time utility successfuly.")
        else:
            self.nfail += 1
            raise error.TestError(
                "\n Failed to verify Exit status of the command %s" % cmd)

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
        if (os.system(cmd) != 0):
            self.nfail += 1
            raise error.TestError(
                '\n Time command with -o option failed to execute')
        else:
            if os.path.exists(self.output_file) and \
               utils.file_contains_pattern(self.output_file, cmd_invoked):
                logging.info(
                    "\n Output file is created successfully using -o option " +
                    "of time utility")
            else:
                self.nfail += 1
                raise error.TestError(
                    "\n Failed to create output file using -o option")

    def test_append_option(self):
        """
        This method will verify the --append option of time utility
        Ex:/usr/bin/time -v -a -o time_out.txt <cmd>
        """
        cmd_invoked = "pwd"
        cmd = "%s -v -a -o %s %s" % (self.time_exe,
                                     self.output_file, cmd_invoked)
        if (os.system(cmd) != 0):
            self.nfail += 1
            raise error.TestError(
                '\n time command with -a option failed to execute')
        else:
            if os.path.exists(self.output_file) and \
               utils.file_contains_pattern(self.output_file, cmd_invoked):
                logging.info(
                    "\n Output is appended to the output file successfully" +
                    " using -a option of time utility")
            else:
                self.nfail += 1
                raise error.TestError(
                    "\n Failed to append the output to a file using -a option")

    def test_format_option(self):
        """
        This method will verify the --format option of time utility
        Ex:/usr/bin/time -f"<format>" <cmd>
        """
        cmd_invoked = "sleep %s" % self.seconds
        cmd = "%s " % self.time_exe + \
            "-f \"%E real,\t%U user,\t%S system,\t%x status\" " + cmd_invoked
        cmd_output = commands.getoutput(cmd)
        if re.search(
                "%s.00 real,\t\S+ user,\t\S+ system,\t\d+ status" %
                self.seconds,
                cmd_output):
            logging.info(
                "\n --format option of time utility is verified succesfully")
        else:
            self.nfail += 1
            raise error.TestError(
                "\n Failed to verify --format option of time utility")

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
echo "Current direcotry `pwd`"
""")
        fobj.close()
        cmd = "%s -v bash %s" % (self.time_exe, custom_script)
        status, cmd_output = commands.getstatusoutput(cmd)
        if (status == 0 and re.search("Current date", cmd_output)):
            logging.info(
                "\n verified execution of custom script using " +
                "time utility successfully")
        else:
            self.nfail += 1
            raise error.TestError(
                "\n Failed to execute custom script using time utility")

    def run_once(self):
        """
        Runs the test.
        """
        try:
            self.install_check()
            self.test_portability_option()
            self.test_exit_status_of_cmd("pwd", "0")
            self.test_exit_status_of_cmd("pwd1", "127")
            self.test_exit_status_of_cmd("host", "1")
            self.test_output_option()
            self.test_append_option()
            self.test_format_option()
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
            logging.info('\n nfails is non-zero')
            raise error.TestError('\nTest failed')
        else:
            logging.info('\n Test completed successfully')
