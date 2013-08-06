import os, shutil
from autotest.client import test, utils
from autotest.client.shared import utils_memory


class linus_stress(test.test):
    version = 1

    def setup(self):
        shutil.copyfile(os.path.join(self.bindir, 'linus_stress.c'),
                        os.path.join(self.srcdir, 'linus_stress.c'))
        os.chdir(self.srcdir)
        utils.system(utils.get_cc() + ' linus_stress.c -D_POSIX_C_SOURCE=200112 -o linus_stress')


    def initialize(self):
        self.job.require_gcc()


    def run_the_test(self, iterations):
        utils.write_one_line('/proc/sys/vm/dirty_ratio', '4')
        utils.write_one_line('/proc/sys/vm/dirty_background_ratio', '2')

        cmd = os.path.join(self.srcdir, 'linus_stress')
        args = "%d" % (utils_memory.memtotal() / 32)

        profilers = self.job.profilers
        if profilers.present():
            profilers.start(self)

        for i in range(iterations):
            utils.system(cmd + ' ' + args)

        if profilers.present():
            profilers.stop(self)
            profilers.report(self)


    def execute(self, iterations = 1):
        dirty_ratio = utils.read_one_line('/proc/sys/vm/dirty_ratio')
        dirty_background_ratio = utils.read_one_line('/proc/sys/vm/dirty_background_ratio')
        try:
            self.run_the_test(iterations)
        finally:
            utils.write_one_line('/proc/sys/vm/dirty_ratio', dirty_ratio)
            utils.write_one_line('/proc/sys/vm/dirty_background_ratio', dirty_background_ratio)
