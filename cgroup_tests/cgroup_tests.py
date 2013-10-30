import logging
from autotest.client import test
from autotest.client.shared import error, utils


class cgroup_tests(test.test):

    """
    Test cgroup sub systems.
    """
    version = 1
    _cgroup_dir = "/cgroup"

    def run_once(self, item=""):
        """
        Test several subsystems
        """
        if not item:
            raise error.TestNAError('No test item provided')
        # Check if 'item'.py(device_rate_test.py, etc.) exists or not
        try:
            mod = __import__(item)
        except ImportError:
            raise error.TestNAError("%s module doesn't exist!" % item)
        mod.execute(self)

    def initialize(self):
        """
        Initialize environment.
        """
        try:
            utils.run("cgclear", ignore_status=False)
        except error.CmdError:
            try:
                utils.run("which cgclear", ignore_status=False)
                logging.warn("cgclear cmd failed which might affect the "
                             "following test.")
            except error.CmdError:
                raise error.TestNAError("'cgclear' command doesn't exist. "
                                        "Please install libcgroup-tool to "
                                        "execute this test.")
