import os
import time
import subprocess
import sys
import logging

from autotest.client import test, utils
from autotest.client.shared import error


class parallel_dd(test.test):
    version = 2

    def initialize(self, fs, fstype='', megabytes=1000, streams=2,
                   seq_read=True, dd_woptions='', dd_roptions='',
                   fs_dd_woptions='', fs_dd_roptions=''):
        self.megabytes = megabytes
        self.blocks = megabytes * 256
        self.blocks_per_file = self.blocks / streams
        self.fs = fs
        self.streams = streams
        self.seq_read = seq_read
        self.dd_woptions = dd_woptions
        self.dd_roptions = dd_roptions
        self.fs_dd_woptions = fs_dd_woptions
        self.fs_dd_roptions = fs_dd_roptions

        root_fs_device_cmd = "df | egrep /$ | awk '{print $1}'"
        root_fs_device = utils.system_output(root_fs_device_cmd)
        self.root_fstype = self._device_to_fstype('/etc/fstab', root_fs_device)

        self.fstype = fstype
        if not self.fstype and self.root_fstype:
            self.fstype = self.root_fstype

        self.old_fstype = self._device_to_fstype('/etc/mtab')
        if not self.old_fstype:
            self.old_fstpye = self._device_to_fstype('/etc/fstab')
        if not self.old_fstype:
            self.old_fstype = self.fstype

        logging.info('Dumping %d megabytes across %d streams', megabytes,
                     streams)

    def raw_write(self):
        logging.info("Timing raw write of %d megabytes" % self.megabytes)
        sys.stdout.flush()
        dd = 'dd if=/dev/zero of=%s bs=4k count=%d' % (self.fs.device,
                                                       self.blocks)

        for option in self.dd_woptions.split():
            dd += " %s=%s" % (option.split(":")[0], option.split(":")[1])
        utils.system(dd + ' > /dev/null')

    def raw_read(self):
        logging.info("Timing raw read of %d megabytes", self.megabytes)
        sys.stdout.flush()
        dd = 'dd if=%s of=/dev/null bs=4k count=%d' % (self.fs.device,
                                                       self.blocks)
        for option in self.dd_roptions.split():
            dd += " %s=%s" % (option.split(":")[0], option.split(":")[1])
        utils.system(dd + ' > /dev/null')

    def fs_write(self):
        p = []
        # Write out 'streams' files in parallel background tasks
        for i in range(self.streams):
            file = os.path.join(self.job.tmpdir, 'poo%d' % (i + 1))
            dd = 'dd if=/dev/zero of=%s bs=4k count=%d' % \
                (file, self.blocks_per_file)
            for option in self.fs_dd_woptions.split():
                dd += " %s=%s" % (option.split(":")[0], option.split(":")[1])
            p.append(subprocess.Popen(dd + ' > /dev/null', shell=True))
        logging.info("Waiting for %d streams", self.streams)
        # Wait for everyone to complete
        for i in range(self.streams):
            logging.info("Waiting for %d", p[i].pid)
            sys.stdout.flush()
            os.waitpid(p[i].pid, 0)
        sys.stdout.flush()
        sys.stderr.flush()

    def fs_read(self):
        p = []
        # Read in 'streams' files in parallel background tasks
        for i in range(self.streams):
            file = os.path.join(self.job.tmpdir, 'poo%d' % (i + 1))
            dd = 'dd if=%s of=/dev/null bs=4k count=%d' % \
                (file, self.blocks_per_file)
            for option in self.fs_dd_roptions.split():
                dd += " %s=%s" % (option.split(":")[0], option.split(":")[1])
            if self.seq_read:
                utils.system(dd + ' > /dev/null')
            else:
                p.append(subprocess.Popen(dd + ' > /dev/null', shell=True))
        if self.seq_read:
            return
        logging.info("Waiting for %d streams", self.streams)
        # Wait for everyone to complete
        for i in range(self.streams):
            logging.info("Waiting for %d", p[i].pid)
            sys.stdout.flush()
            os.waitpid(p[i].pid, 0)

    def _device_to_fstype(self, file, device=None):
        if not device:
            device = self.fs.device
        try:
            line = utils.system_output('egrep ^%s %s' % (device, file))
            logging.debug(line)
            fstype = line.split()[2]
            logging.debug('Found %s is type %s from %s', device, fstype, file)
            return fstype
        except error.CmdError, e:
            logging.error('No %s found in %s', device, file)
            return None

    def run_once(self):
        try:
            self.fs.unmount()
        except error.CmdError, e:
            pass

        logging.info('------------- Timing raw operations ------------------')
        start = time.time()
        self.raw_write()
        self.raw_write_rate = self.megabytes / (time.time() - start)

        start = time.time()
        self.raw_read()
        self.raw_read_rate = self.megabytes / (time.time() - start)

        # Set up the filesystem
        self.fs.mkfs(self.fstype)
        self.fs.mount(None)

        logging.info('------------- Timing fs operations ------------------')
        start = time.time()
        self.fs_write()
        self.fs_write_rate = self.megabytes / (time.time() - start)
        self.fs.unmount()

        self.fs.mount(None)
        start = time.time()
        self.fs_read()
        self.fs_read_rate = self.megabytes / (time.time() - start)

        self.write_perf_keyval({
            'raw_write': self.raw_write_rate,
            'raw_read': self.raw_read_rate,
            'fs_write': self.fs_write_rate,
            'fs_read': self.fs_read_rate})

    def cleanup(self):
        try:
            self.fs.unmount()
        except error.CmdError, e:
            pass
        logging.debug('\nFormatting %s back to type %s\n', self.fs,
                      self.old_fstype)
        self.fs.mkfs(self.old_fstype)
        self.fs.mount(None)
