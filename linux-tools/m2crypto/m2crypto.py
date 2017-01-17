#!/bin/python
import os, subprocess
import logging

from autotest.client import test
from autotest.client.shared import error

class m2crypto(test.test):

    """
    Autotest module for testing basic functionality
    of m2crypto

    @author Kingsuk Deb, kingsdeb@linux.vnet.ibm.com                           ##
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
            os.environ["LTPBIN"] = "%s/shared" %(test_path)
            cwd = os.getcwd()
            os.chdir("%s/m2crypto" %(test_path))
            os.system("patch -p0 < bug81712-fix-test_pgp-test-rc.diff")
            os.system("patch -p0 < bug85378-fix-test-with-exp-values.diff")
            os.chdir(cwd)
            ret_val = subprocess.Popen(['./m2crypto.sh'], cwd="%s/m2crypto" %(test_path))
            ret_val.communicate()
            if ret_val.returncode != 0:
                self.nfail += 1

        except error.CmdError, e:
            self.nfail += 1
            logging.error("Test Failed: %s", e)

    def postprocess(self):
        if self.nfail != 0:
            logging.info('\n nfails is non-zero')
            raise error.TestError('\nTest failed')
        else:
            logging.info('\n Test completed successfully ')


