#!/bin/python
import os, subprocess
import logging

from autotest.client import test
from autotest.client.shared import error, software_manager
sm = software_manager.SoftwareManager()

class gnupg2(test.test):

    """
    Autotest module for testing basic functionality
    of gnupg2

    @author Robb Romans <robb@austin.ibm.com>
    """
    version = 1
    nfail = 0
    path = ''

    def initialize(self, test_path=''):
        """
        Sets the overall failure counter for the test.
        """
        self.nfail = 0
        if not sm.check_installed('gcc'):
            logging.debug("gcc missing - trying to install")
            sm.install('gcc')
	ret_val = subprocess.Popen(['make', 'all'], cwd="%s/gnupg2" %(test_path))
	ret_val.communicate()
	if ret_val.returncode != 0:
	    self.nfail += 1
        logging.info('\n Test initialize successfully')

    def run_once(self, test_path=''):
        """
        Trigger test run
        """
        try:
            os.environ["LTPBIN"] = "%s/shared" %(test_path)
            ret_val = subprocess.Popen(['./gnupg2.sh'], cwd="%s/gnupg2" %(test_path))
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

