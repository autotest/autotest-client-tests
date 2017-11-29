#!/bin/python
import os
import subprocess
import logging
import time
import sys

from autotest.client import test
from autotest.client.shared import error


class openvas_scanner(test.test):

    """
    Autotest module for scanning the system for CVEs by openvas tools

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
            cwd = os.getcwd()
            os.chdir(cwd)
            ret_val = subprocess.Popen(
                ['./openvas_omp.py'],
                cwd="%s/openvas_scanner" %
                (test_path))
            time.sleep(100)
            ret_val.communicate()
            if ret_val.returncode != 0:
                self.nfail += 1

        except error.CmdError as e:
            self.nfail += 1
            logging.error("Test Failed: %s", e)

    def postprocess(self):
        if self.nfail != 0:
            logging.info('\n nfails is non-zero')
            raise error.TestError('\nTest failed')
        else:
            logging.info('\n Test completed successfully ')
        sys.exit()
