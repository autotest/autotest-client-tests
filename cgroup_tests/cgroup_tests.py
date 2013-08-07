import logging, sys
from autotest.client import test
from autotest.client.shared import error, utils, utils_cgroup
try:
    import device_rate_test
    import memory_migrate_test
    # TODO other sub systems test
except ImportError:
    raise error.TestError("Cgroup test module doesn't exist!")

class cgroup_tests(test.test):
    """
    Test cgroup sub systems.
    """
    version = 1
    _cgroup_dir = "/cgroup"
    _test_result = True


    def run_once(self):
        """
        Test several subsystems
        """
        fail_detail = []
        try:
            logging.info("---< 'device rate test' START >---")
            self.device_rate_test()
            logging.info("---< 'device rate test' PASSED >---")
        except Exception:
            logging.info("---< 'device rate test' FAILED >---")
            detail = utils.etraceback("device rate", sys.exc_info())
            logging.error("Failure details:\n%s", detail)
            fail_detail.append(detail)
            self._test_result = False

        try:
            logging.info("---< 'memory migrate test' START >---")
            self.memory_migrate_test()
            logging.info("---< 'memory migrate test' PASSED >---")
        except Exception:
            logging.info("---< 'memory migrate test' FAILED >---")
            detail = utils.etraceback("memory migrate", sys.exc_info())
            logging.error("Failure details:\n%s", detail)
            fail_detail.append(detail)
            self._test_result = False

        # TODO other sub systems test
        if not self._test_result:
            raise error.TestFail("There are fail test cases:\n%s" %
                                 "\n".join(fail_detail))


    def initialize(self):
        """
        Initialize environment.
        """
        try:
            utils_cgroup.all_cgroup_delete()
        except Exception:
            raise error.TestNAError("'cgclear' command failed. "
                                    "Do you have libcgroup-tool installed?")


    def device_rate_test(self):
        """
        Test file create rate in desired device with cgroup
        """
        device_test = device_rate_test.DeviceRate(self._cgroup_dir)
        device_test.test()


    def memory_migrate_test(self):
        """
        Test file create rate in desired device with cgroup
        """
        memory_test = memory_migrate_test.MemoryMigrate(self._cgroup_dir,
                                                        self.tmpdir)
        memory_test.test()
