import os

from autotest.client import test, utils



class aio_dio_bugs(test.test):
    version = 5
    preserve_srcdir = True

    def initialize(self):
        self.job.require_gcc()
        self.job.setup_dep(['libaio'])
        ldflags = '-L ' + self.autodir + '/deps/libaio/lib'
        cflags = '-I ' + self.autodir + '/deps/libaio/include'
        self.gcc_flags = ldflags + ' ' + cflags

    def setup(self):
        os.chdir(self.srcdir)
        utils.make('"CFLAGS=' + self.gcc_flags + '"')

    def run_once(self, test_name, args=''):
        os.chdir(self.tmpdir)
        libs = self.autodir + '/deps/libaio/lib/'
        ld_path = utils.prepend_path(libs,
                                     utils.environ('LD_LIBRARY_PATH'))
        var_ld_path = 'LD_LIBRARY_PATH=' + ld_path
        cmd = self.srcdir + '/' + test_name + ' ' + args
        utils.system(var_ld_path + ' ' + cmd)
