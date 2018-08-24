#!/bin/python
import os
import subprocess
import logging

from autotest.client.shared import error


class ruby(test.test):

    """
    Autotest module for testing basic functionality
    of ruby

    @author Anup Kumar, anupkumk@linux.vnet.ibm.com
    """
    version = 1
    nfail = 0
    path = ''

    def initialize(self):
        """
        Sets the overall failure counter for the test.
        """
        self.nfail = 0
        logging.info('\n Test initialize successfully')

    def run_once(self, test_path=''):
        """
        Trigger test run
        """
        try:
            os.environ["LTPBIN"] = os.path.join(test_path, "shared")
            ret_val = subprocess.Popen(
                ['./ruby.sh'], cwd="%s/ruby" %
                (test_path))
            ret_val.communicate()
            if ret_val.returncode != 0:
                self.nfail += 1

        except error.CmdError as err:
            self.nfail += 1
            logging.error("Test Failed: %s", err)

    def postprocess(self):
        if self.nfail != 0:
            logging.info('\n nfails is non-zero')
            raise error.TestError('\nTest failed')
        else:
            logging.info('\n Test completed successfully ')
