import os

from autotest.client import test, utils


class fio(test.test):

    """
    fio is an I/O tool mean for benchmark and stress/hardware verification.

    @see: http://freecode.com/projects/fio
    """
    version = 3

    def initialize(self):
        self.job.require_gcc()

    def setup(self, tarball='fio-2.1.10.tar.bz2'):
        """
        Compiles and installs fio.

        @see: http://brick.kernel.dk/snaps/fio-2.0.5.tar.bz2
        """
        tarball = utils.unmap_url(self.bindir, tarball, self.tmpdir)
        utils.extract_tarball_to_dir(tarball, self.srcdir)

        self.job.setup_dep(['libaio'])
        ldflags = '-L' + self.autodir + '/deps/libaio/lib'
        cflags = '-I' + self.autodir + '/deps/libaio/include'
        var_ldflags = 'LDFLAGS="' + ldflags + '"'
        var_cflags = 'CFLAGS="' + cflags + '"'

        os.chdir(self.srcdir)
        utils.system('%s %s make' % (var_ldflags, var_cflags))

    def run_once(self, opts=None, job=None, user='root'):
        log = os.path.join(self.resultsdir, 'fio-mixed.log')
        _opts = '--output %s ' % (log)

        if opts:
            _opts += opts

        if job is None:
            job = os.path.join(self.bindir, 'fio-mixed.job')
        else:
            if not os.path.isabs(job):
                job = os.path.join(self.bindir, job)
        _opts += ' %s' % (job)

        os.chdir(self.srcdir)
        ##vars = 'TMPDIR=\"%s\" RESULTDIR=\"%s\"' % (self.tmpdir, self.resultsdir)
        env_vars = 'LD_LIBRARY_PATH="' + self.autodir + '/deps/libaio/lib"'
        ##opts = '-m -o ' + self.resultsdir + '/fio-tio.log ' + self.srcdir + '/examples/tiobench-example'
        utils.system(env_vars + ' ./fio ' + _opts)
