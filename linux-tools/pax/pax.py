#!/bin/python
import os
import shutil
import logging
from autotest.client.shared  import software_manager
from autotest.client import utils
from autotest.client import test
from autotest.client.shared import error


class pax(test.test):

    '''
    Autotest module for Pax archiving utility.

    Pax is an archiving utility that will read, write, and list the members of
    an archive file and will copy directory hierarchies. pax operation is
    independent of the specific archive format and supports a wide variety of
    different archive formats,like tar,cpio and so on.

    @author :Rajeev S <rajeevs1992 gmail com>
    '''
    version = 2
    nfail = 0
    archive = ''
    test = ''

    def init_create(self):
        try:
            os.mkdir(self.archive)
            os.mkdir(self.archive + '/d_one')
            os.mkdir(self.archive + '/d_two')
            os.mkdir(self.archive + '/d_three')
            utils.open_write_close(self.archive + '/d_one/f_one', 'file 1')
            utils.open_write_close(self.archive + '/d_one/f_two', 'file 2')
            utils.open_write_close(self.archive + '/d_one/f_three', 'file 3')
            os.mkdir(self.archive + '/d_two/d_four')
            utils.open_write_close(self.archive + '/d_one/f_four', 'file 4')
        except Exception as e:
            logging.error(e)
            self.nfail += 1

    def create(self):
        utils.system('pax -w > %s.tar %s' % (self.archive, self.archive))
        if os.path.exists('%s.tar' % (self.archive)):
            logging.info('Archive creation successful.')
        else:
            raise error.TestError('Archive creation failed')

    def init_list(self):
        self.init_create()
        self.create()

    def list(self):
        l = os.popen('pax < %s.tar' % (self.archive)).read()
        expected_output = '''test
test/d_one
test/d_one/f_one
test/d_one/f_four
test/d_one/f_two
test/d_one/f_three
test/d_three
test/d_two
test/d_two/d_four'''
        expected_output = utils.re.sub('test', self.archive, expected_output).split('\n')
        expected_output.sort()
        l = l.split('\n')
        l.remove('')
        l.sort()
        z = zip(l, expected_output)
        for i, j in z:
            if i.strip() != j.strip():
                raise error.TestError('Archive listing doesnt match')
        logging.info('Archive listing matched.')

    def init_extract(self):
        self.init_create()
        self.create()

    def extract(self):
        shutil.rmtree(self.archive)
        os.chdir('/tmp/')
        utils.system('pax -r < %s.tar' % self.archive)
        ls = []
        ls.append(self.archive)
        for subdir, subdirs, filename in os.walk(self.archive):
            for i in subdirs:
                ls.append((subdir + '/' + i + '\n'))
            for i in filename:
                ls.append(subdir + '/' + i + '\n')
        l = os.popen('pax < %s.tar' % (self.archive)).read()
        l = l.split('\n')
        l.remove('')
        l.sort()
        ls.sort()
        z = zip(l, ls)
        for i, j in z:
            if i.strip() != j.strip():
                raise error.TestError('Listing doesnt match.Archive extract failed')
        logging.info('Archive extract successful.')

    def init_copy(self):
        self.init_create()
        os.mkdir('%s-test' % (self.archive))

    def copy(self):
        os.chdir(self.archive)
        utils.system('pax -rw . %s-test' % (self.archive))
        expected_output = '''test
test/d_one
test/d_one/f_one
test/d_one/f_four
test/d_one/f_two
test/d_one/f_three
test/d_three
test/d_two
test/d_two/d_four'''
        expected_output = utils.re.sub('test', self.archive, expected_output).split('\n')
        expected_output.sort()
        os.chdir(self.archive + '-test')
        ls = []
        ls.append(self.archive)
        for subdir, subdirs, filename in os.walk(self.archive):
            for i in subdirs:
                ls.append(utils.re.sub('-test', '', subdir + '/' + i + '\n'))
            for i in filename:
                ls.append(utils.re.sub('-test', '', subdir + '/' + i + '\n'))
        ls.sort()
        z = zip(ls, expected_output)
        for i, j in z:
            if i.strip() != j.strip():
                raise error.TestError('Directory listing doesnt match')
        logging.info('Directory copy success.')

    def setup(self):
        backend = software_manager.SoftwareManager()
        logging.info('Installing pax')
        backend.install('pax')

    def initialize(self, archive, test):
        self.archive = archive
        self.test = test
        func = 'init_' + test
        init = getattr(self, func)
        init()

    def run_once(self):
        test = getattr(self, self.test)
        try:
            test()
        except Exception as e:
            self.nfail += 1
            logging.error(e)

    def cleanup(self):
        try:
            shutil.rmtree(self.archive)
            if os.path.exists(self.archive + '-test'):
                shutil.rmtree(self.archive + '-test')
            os.remove(self.archive + '.tar')
        except Exception:
            pass

    def postprocess(self):
        if self.nfail != 0:
            raise error.TestError('\nTest failed : %s ' % self.test)
        else:
            logging.info('\nTest completed successfully : %s' % self.test)
