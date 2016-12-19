#!/bin/python
import os, subprocess
import logging

from autotest.client import test
from autotest.client.shared import error

class perl_XML_NamespaceSupport(test.test):

    """
    Autotest module for testing basic functionality
    of perl_XML_NamespaceSupport

    @author Basheer Khadarsabgari <bkhadars@in.ibm.com>                               ##
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
            ret_val = subprocess.Popen(['./perl-XML-NamespaceSupport.sh'], cwd="%s/perl_XML_NamespaceSupport" %(test_path))
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

