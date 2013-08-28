from autotest.client import test
from autotest.client.shared import error, utils_cgroup

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
            utils_cgroup.all_cgroup_delete()
        except Exception:
            raise error.TestNAError("'cgclear' command failed. "
                                    "Some subsystems are busy or "
                                    "you don't have libcgroup-tool installed!")
