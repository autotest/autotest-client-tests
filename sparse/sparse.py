import os
import re
from autotest.client.shared import error
from autotest.client import test, utils, kernel


class sparse(test.test):
    version = 2

    def initialize(self):
        self.job.require_gcc()

    # http://www.codemonkey.org.uk/projects/git-snapshots/sparse/sparse-2013-06-26.tar.gz
    def setup(self, tarball='sparse-2013-06-26.tar.gz'):
        tarball = utils.unmap_url(self.bindir, tarball, self.tmpdir)
        utils.extract_tarball_to_dir(tarball, self.srcdir)
        os.chdir(self.srcdir)

        utils.make()

        self.top_dir = self.job.tmpdir + '/sparse'

    def execute(self, kernel=None, patch=None, build_target=None, base_tree=None, config=None):

        if (kernel is None) and (base_tree is None):
            raise error.TestError("Test requires at least kernel or base_tree parameters")

        if not kernel:
            kernel = self.job.kernel(base_tree)
            if patch:
                kernel.patch(patch)
            if not config:
                kernel.config()
            else:
                kernel.config(config)

        logfile = os.path.join(self.resultsdir, 'sparse_log')
        errlog = os.path.join(self.resultsdir, 'sparse_error')

        os.chdir(kernel.build_dir)
        kernel.set_cross_cc()
        # It is important to clean kernel before the check in order
        # generate comparable results
        kernel.clean()

        if not build_target:
            build_target = self.build_target

        # TODO Add more debug defines
        debug_def = 'CF="-D__CHECK_ENDIAN__"'
        make_opts = 'C=2 %s CHECK="%s -p=kernel"' % (debug_def, os.path.join(self.srcdir, 'sparse'))

        make_cmd = " %s %s 2> %s | tee %s" % (make_opts, build_target, errlog, logfile)
        utils.make(make_cmd)

        # Account number of warnings and error and store as key-value
        lf = open(logfile, 'r')
        ef = open(errlog, 'r')
        warn_cnt = len(re.findall(r'warning: ', lf.read(), re.MULTILINE))
        warn_cnt += len(re.findall(r'warning: ', ef.read(), re.MULTILINE))
        lf.seek(0)
        ef.seek(0)
        err_cnt = len(re.findall(r'error: ', lf.read(), re.MULTILINE))
        err_cnt += len(re.findall(r'error: ', ef.read(), re.MULTILINE))
        ef.close()
        lf.close()
        self.write_test_keyval({'warnings': warn_cnt,
                                'errors': err_cnt})
