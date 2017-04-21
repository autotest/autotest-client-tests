import os
from autotest.client import test, utils


__author__ = '''support@versity.com (Versity, Inc.)'''


class vsm_smoke(test.test):
    version = 1

    def execute(self):
        os.chdir(self.bindir)
        utils.system('./vsm_smoke.sh')
