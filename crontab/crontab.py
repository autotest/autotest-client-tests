#!/usr/bin/python
import os, shutil, glob, logging
from autotest.client import test, utils
from autotest.client.shared import error
from time import sleep


class crontab(test.test):
    '''
    Autotest module for crontab.

    Creates a new cron job that creates a log entry in log.The count of
    log entry is compared before and after a period of 80 sec.Difference decide
    s whether the cron executed
    successfully.

    @author :Rajeev S <rajeevs1992@gmail.com>
    '''
    version = 1
    initial_count = 0
    log = ''
    nfail = 0

    def count_log(self, string):
        '''returns count of the 'string' in log'''
        count = 0
        try:
            f = open(self.log)
        except IOError:
            utils.open_write_close(self.log, 'Cron automation\n')
            f = open(self.log)
        for i in f.readlines():
            if string in i:
                count = count + 1
        f.close()
        return count

    def initialize(self, test, log):
        '''Does the init part of the test
        1.Finds initial count of entry in log
        2.Creates a file 'cron' under cron.d
        3.Backs up /etc/crontab
        4.Modifies /etc/crontab    '''
        self.log = log

        self.initial_count = self.count_log('Cron automation')
        f = open('/etc/cron.d/cron', 'w')
        f.write('''#!/bin/bash
touch  %s
echo 'Cron automation' >>  %s
        ''' % (self.log, self.log))
        f.close()
        utils.system('chmod +x /etc/cron.d/cron')
        shutil.copyfile('/etc/crontab', '/tmp/backup')
        f = open('/etc/crontab', 'w')
        f.write('* * * * * root run-parts /etc/cron.d/\n')
        f.close()
        if test == 'deny_cron':
            if os.path.exists('/etc/cron.d/jobs.deny'):
                shutil.move('/etc/cron.d/jobs.deny', '/tmp/jobs.deny')
            f = open('/etc/cron.d/jobs.deny', 'w')
            f.write('cron')
            f.close()
        elif test == 'allow_cron' :
            os.remove('/etc/cron.d/jobs.deny')
            if os.path.exists('/etc/cron.d/jobs.allow'):
                shutil.move('/etc/cron.d/jobs.allow', '/tmp/jobs.allow')
            f = open('/etc/cron.d/jobs.allow', 'w')
            f.write('cron')
            f.close()

    def allow_cron(self, wait_time):
        logging.info('Starting test Crontab with jobs.allow ')
        if self.count_log('Cron automation') > self.initial_count:
            logging.info('''Test:run-parts with jobs.allow
            Test Successful.
            Test time: %s''' % (wait_time))
        else:
            raise error.TestError('''Test:run-parts with jobs.allow
            There were no new entries in log.
            Job not executed inspite of jobs.allow entry.
            Test time: %s''' % (wait_time))


    def normal_cron(self, wait_time):
        logging.info('Starting test normal Crontab')
        if self.count_log('Cron automation') > self.initial_count:
            logging.info('''Test:normal test for run-parts
            Test successful.
            Test time: %s''' % (wait_time))
        else:
            raise error.TestError('''Test:normal test for run-parts
            There were no new entries in log.
            Test time: %s''' % (wait_time))


    def deny_cron(self, wait_time):
        logging.info('Starting test Crontab with jobs.deny ')
        if self.count_log('Cron automation') > self.initial_count:
            raise error.TestError('''Test:run-parts with jobs.deny
            run-parts overrides jobs.deny.
            Test time: %s''' % (wait_time))
        else:
            logging.info('''Test:run-parts with jobs.deny
            Test Successful.
            There were no new entries in log.
            Test time: %s''' % (wait_time))

    def run_once(self, test, wait_time):
        '''Runs the test, writes test success if cron successfully executes, else
           writes test failed.
           Resets /etc/crontab
           Pass 0:Normal operation of run-parts
           Pass 1:run-parts with jobs.deny
           Pass 2:run-parts with jobs.allow
        '''
        self.test = test
        sleep(wait_time)
        test = getattr(self, test)
        try:
            test(wait_time)
        except Exception as e:
            self.nfail = self.nfail + 1
            logging.error(e)

    def cleanup(self):
        shutil.move('/tmp/backup', '/etc/crontab')
        if os.path.exists('/etc/cron.d/jobs.allow'):
            os.remove('/etc/cron.d/jobs.allow')
            os.remove('/etc/cron.d/cron')
        else:
            os.remove('/etc/cron.d/cron')
        if os.path.exists('/tmp/jobs.allow'):
            shutil.move('/tmp/jobs.allow', '/etc/cron.d/jobs.allow')
        if os.path.exists('/tmp/jobs.deny'):
            shutil.move('/tmp/jobs.allow', '/etc/cron.d/jobs.allow')
    def postprocess(self):
        if self.nfail != 0:
            raise error.TestError('\nTest failed : %s ' % self.test)
        else:
            logging.info('\nTest completed successfully : %s' % self.test)
