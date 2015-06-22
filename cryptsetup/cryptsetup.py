#!/bin/python
from autotest.client import test, utils
import hashlib
import os
import logging
from autotest.client.shared import error


class cryptsetup(test.test):

    '''
    Autotest module for Cryptsetup.

    Cryptsetup is a utility used to setup cryptographic volumes for dm-crypt,
    a disk encryption subsystem in the linux kernel.
    It can be used to encrypt partitions, loop devices and even entire systems.

    @author Abhilash B <abhilashb1289 gmail com>, Abhay Krishnan P K <abhayk44 gmail com>
    '''

    md5old = ''
    md5new = ''
    failcount = 0
    version = 1
    test = ''

    def findhash(self):
        try:
            hasher = hashlib.md5()
            with open('/mnt/autotest_test_cryptsetup/sample.txt', 'rb') as f:
                buf = f.read()
                hasher.update(buf)
                f.close()
            return hasher.hexdigest()
        except Exception as e:
            logging.error(e)
            self.failcount += 1

    def checkhash(self):
        if self.md5old != self.md5new:
            self.failcount += 1
            raise error.TestError('Hashes do not match')
        else:
            logging.info('Hashes match')

    def luks(self):
        try:
            utils.system('fallocate -l 5M container1')
            if not os.path.exists("/mnt/autotest_test_cryptsetup"):
                os.mkdir("/mnt/autotest_test_cryptsetup")
        except Exception as e:
            logging.error(e)
            self.failcount += 1

        utils.system('printf 12345|cryptsetup luksFormat container1 -')
        utils.system('printf 12345|cryptsetup luksOpen container1 volume1 -')

        try:
            utils.system('mkfs.ext3 /dev/mapper/volume1')
            utils.system(
                'mount /dev/mapper/volume1 /mnt/autotest_test_cryptsetup')
            f = open('/mnt/autotest_test_cryptsetup/sample.txt', 'wb')

            f.write('_test_string_')
            f.close()
            self.md5old = self.findhash()
            utils.system('umount -f /mnt/autotest_test_cryptsetup')
            utils.system('cryptsetup luksClose volume1')
            utils.system(
                'printf 12345|cryptsetup luksOpen container1 volume1 -')
            utils.system(
                'mount /dev/mapper/volume1 /mnt/autotest_test_cryptsetup')
            self.md5new = self.findhash()

            utils.system('umount -f /mnt/autotest_test_cryptsetup')
            utils.system('cryptsetup luksClose volume1')
            utils.system('rm container1')
            self.checkhash()
        except Exception as e:
            logging.error(e)
            self.failcount = +1

    def plain(self):
        try:
            utils.system('fallocate -l 5M container2')
            if not os.path.exists("/mnt/autotest_test_cryptsetup"):
                os.mkdir("/mnt/autotest_test_cryptsetup")
        except Exception as e:
            logging.error(e)
            self.failcount += 1
        try:
            utils.system('printf 12345|cryptsetup create volume2 container2 -')
        except Exception as e:
            logging.error(e)
            self.failcount += 1
        if os.path.exists('/dev/mapper/volume2'):

            try:
                utils.system('mkfs.ext3 /dev/mapper/volume2')
                utils.system(
                    'mount /dev/mapper/volume2 /mnt/autotest_test_cryptsetup')
                f = open('/mnt/autotest_test_cryptsetup/sample.txt', 'wb')
                f.write('_test_string_')
                f.close()
                self.md5old = self.findhash()

                utils.system('umount -f /mnt/autotest_test_cryptsetup')
                utils.system('cryptsetup remove volume2')
                utils.system(
                    'printf 12345|cryptsetup create volume2 container2 -')

                utils.system(
                    'mount /dev/mapper/volume2 /mnt/autotest_test_cryptsetup')

                self.md5new = self.findhash()

                utils.system('umount -f /mnt/autotest_test_cryptsetup')
                utils.system('cryptsetup remove volume2')
                utils.system('rm container2')
                self.checkhash()
            except Exception as e:

                self.failcount += 1
                logging.error(e)

    def run_once(self, test):

        self.test = test
        test = getattr(self, test)
        try:
            test()
        except Exception as e:
            self.failcount += 1
            logging.error(e)

    def postprocess(self):

        if self.failcount != 0:
            raise error.TestError('\nTest failed : %s ' % self.test)
        else:
            logging.info('\nTest completed successfully : %s' % self.test)

    def cleanup(self):
        try:
            os.rmdir("/mnt/autotest_test_cryptsetup")

        except Exception as e:
            pass
