#!/bin/python
import os, subprocess
import logging

from autotest.client import test
from autotest.client.shared import error

class pexpect_test(test.test):

    """
    Autotest module for testing basic functionality
    of pexpect_test

    @author Athira Rajeev<atrajeev@in.ibm.com>
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
            pexpect_test_path = os.path.join(test_path, "pexpect_test")
            os.chdir(pexpect_test_path)
            subprocess.call("make uninstall", shell=True)
            return_val = subprocess.call("patch -p0 < pexpect-pxssh-scripts.diff", shell=True)
            if return_val == 0:
                ret_val = subprocess.call(os.path.join(pexpect_test_path, 'pexpect.sh'), shell=True)
                if ret_val != 0:
                    self.nfail += 1
            else:
                logging.info('Applying Patch failed ')
                raise error.TestError('\nPatch "pexpect-pxssh-scripts.diff" failed to apply')

        except error.CmdError, e:
            self.nfail += 1
            logging.error("Test Failed: %s", e)

    def postprocess(self):
        if self.nfail != 0:
            logging.info('\n nfails is non-zero')
            raise error.TestError('\nTest failed')
        else:
            logging.info('\n Test completed successfully ')

