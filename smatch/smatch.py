import os, logging, commands, re, shutil
from autotest.client import kernel, test, utils
from autotest.client.shared import software_manager, error

class smatch(test.test):
    version = 1

    def initialize(self):
        self.job.require_gcc()

    def setup(self, tarball='smatch-b0e645.tar.bz2'):
        self.tarball = utils.unmap_url(self.bindir, tarball, self.tmpdir)
        utils.extract_tarball_to_dir(self.tarball, self.srcdir)

        sm = software_manager.SoftwareManager()
        for header in ['/usr/include/sqlite3.h', '/usr/include/llvm']:
            if not os.access(header, os.X_OK):
                logging.debug("%s missing - trying to install", header)
                pkg = sm.provides(header)
                if pkg is None:
                    raise error.TestError(
                        "Unable to find header %s to satisfy 'smatch' dependence" %
                        header)
                else:
                    sm.install(pkg)

        os.chdir(self.srcdir)
        utils.make()

    def execute(self, kernel=None, build_target=None, base_tree=None,
                patch=None, config=None):
        """
        Arguments:
                {kernel | base_tree} [build_target]
                kernel: kernel object
                base_tree [patch, config] : kernel's base tree
        """
        own_kernel = False
        if (kernel is None) and (base_tree is None):
            raise error.TestError("Test requires at least one parameter {kernel | base_tree}")


        if not kernel:
            kernel = self.job.kernel(base_tree)
            own_kernel = True
            if patch:
                kernel.patch(patch)
            if not config:
                kernel.config()
            else:
                kernel.config(config)

        os.chdir(kernel.build_dir)
        kernel.set_cross_cc()
        # It is important to clean kernel before the check in order
        # generate comparable results
        kernel.clean()
        # Problem: smatch works badly with CONFIG_DYNAMIC_DEBUG=y, so we have to
        # disable it which require changes of original config
        # Solution: save original .config and restore after test
        if not own_kernel:
            orig_config = os.path.join(self.tmpdir, 'kernel-config.orig')
            logging.info('Saving original kernel config at %s', orig_config)
            shutil.copyfile('.config', orig_config)

        override = os.path.join(self.bindir, 'config.override')
        kernel.config(orig_config, override)

        logfile = os.path.join(self.resultsdir, 'smatch.log')
        errlog = os.path.join(self.resultsdir, 'smatch.log.error')


        if not build_target:
            build_target =  self.build_target

        # TODO Add more debug defines
        debug_def='CF="-D__CHECK_ENDIAN__"'
        make_opts = 'C=2 %s CHECK="%s -p=kernel"' % \
            (debug_def, os.path.join(self.srcdir, 'smatch'))

        make_cmd = " %s %s 2> %s | tee %s" %(make_opts, build_target, errlog, logfile)
        utils.make(make_cmd)

        # Account errors and warnings and save it in key-value
        lf = open(logfile, 'r')
        ef = open(errlog, 'r')
        warn_cnt = len(re.findall(r'(warn:|warning:) ', lf.read(), re.MULTILINE))
        warn_cnt += len(re.findall(r'(warn:|warning:) ', ef.read(), re.MULTILINE))
        lf.seek(0)
        ef.seek(0)
        err_cnt = len(re.findall(r'error: ', lf.read(), re.MULTILINE))
        err_cnt += len(re.findall(r'error: ', ef.read(), re.MULTILINE))
        ef.close()
        lf.close()
        self.write_test_keyval({'warnings': warn_cnt,
                                'errors': err_cnt})

        if not own_kernel:
            logging.info('Restoring original kernel config')
            kernel.config(orig_config)
