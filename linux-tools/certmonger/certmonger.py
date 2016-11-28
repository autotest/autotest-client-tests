#!/bin/python
import os, subprocess
import shutil
import logging

from autotest.client import test, utils
from autotest.client.shared import error, software_manager

class certmonger(test.test):

    """
    Autotest module for testing basic functionality
    of certmonger

    @author Sohny Thomas <sohthoma@in.ibm.com>
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
            os.chdir("%s/certmonger" %(test_path))
            os.system("patch -p0 -R < change-path.patch")
            os.chdir(cwd)
            ret_val = subprocess.Popen(['./certmonger.sh'], cwd="%s/certmonger" %(test_path))
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

