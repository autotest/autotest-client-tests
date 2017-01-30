#!/bin/python
import os, subprocess
import logging

from autotest.client import test
from autotest.client.shared import error

class python_urlgrabber(test.test):

    """
    Autotest module for testing basic functionality
    of python_urlgrabber

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
            os.chdir("%s/python_urlgrabber" %(test_path))
            os.system("patch -p0 < ibmbug81490-exclude-test_byterange.diff")
            os.system("patch -p0 < ibmbug78855-fix-test_url-fix-pycurl_error.diff")
            os.system("patch -p0 < ibmbug78855-print_to_stderr_in_interrupt_callback_tests.diff")
            os.chdir(cwd)
            ret_val = subprocess.call(test_path + '/python_urlgrabber' + '/python-urlgrabber.sh', shell=True)
            if ret_val != 0:
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

