#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Autotest test for testing cgroup functionalities

@copyright: 2011 Red Hat Inc.
@author: Lukas Doktor <ldoktor@redhat.com>
"""
import os
import sys
import logging
import time
from tempfile import NamedTemporaryFile
from subprocess import Popen

from autotest.client import test, utils
from autotest.client.shared import error
try:
    from autotest.client.shared.utils_cgroup import Cgroup, CgroupModules
    from autotest.client.shared.utils_cgroup import get_load_per_cpu
except ImportError:
    # TODO: Obsoleted path used prior autotest-0.15.2
    # pylint: disable=E0611
    from autotest.client.cgroup_utils import Cgroup, CgroupModules
    from autotest.client.cgroup_utils import get_load_per_cpu


class cgroup(test.test):

    """
    Tests the cgroup functionalities. It works by creating a process (which is
    also a python application) that will try to use CPU and memory. We will
    then verify whether the cgroups rules are obeyed.
    """
    version = 1
    _client = ""
    modules = None

    def run_once(self):
        """
            Try to access different resources which are restricted by cgroup.
        """
        logging.info('Starting cgroup testing')
        err = ""
        # Run available tests
        for subtest in ['memory', 'cpuset', 'cpu']:
            logging.info("---< 'test_%s' START >---", subtest)
            try:
                if not self.modules.get_pwd(subtest):
                    raise error.TestFail("module not available/mounted")
                t_function = getattr(self, "test_%s" % subtest)
                t_function()
                logging.info("---< 'test_%s' PASSED >---", subtest)
            except AttributeError, details:
                if str(details) == ("'cgroup' object has no attribute"
                                    " 'test_%s'" % subtest):
                    err += "%s, " % subtest
                    logging.error("test_%s: Test doesn't exist", subtest)
                    logging.info("---< 'test_%s' FAILED >---", subtest)
                else:
                    err += "%s, " % subtest
                    tb = utils.etraceback("test_%s" % subtest, sys.exc_info())
                    logging.error("test_%s: FAILED%s", subtest, tb)
                    logging.info("---< 'test_%s' FAILED >---", subtest)
            except Exception:
                err += "%s, " % subtest
                tb = utils.etraceback("test_%s" % subtest, sys.exc_info())
                logging.error("test_%s: FAILED%s", subtest, tb)
                logging.info("---< 'test_%s' FAILED >---", subtest)

        if err:
            logging.error('Some subtests failed (%s)', err[:-2])
            raise error.TestFail('Some subtests failed (%s)' % err[:-2])

    def initialize(self):
        """
        Test initialization, Init and prepares listed cgroups for use. Not all
        of them have to pass the initialization.
        """
        logging.debug('Setting up cgroups modules')

        self._client = os.path.join(self.bindir, "cgroup_client.py")

        _modules = ['cpuset', 'ns', 'cpu', 'cpuacct', 'memory', 'devices',
                    'freezer', 'net_cls', 'blkio']
        self.modules = CgroupModules()
        if (self.modules.init(_modules) <= 0):
            raise error.TestFail('Can\'t mount any cgroup modules')

    def cleanup(self):
        """ Cleanup """
        logging.debug('cgroup_test cleanup')
        del (self.modules)

    #
    # TESTS
    #
    def test_memory(self):
        """
        Memory test
        """
        def cleanup(suppress=False):
            """ cleanup """
            logging.debug("test_memory: Cleanup")
            err = ""
            if item.rm_cgroup(pwd):
                err += "\nCan't remove cgroup directory"

            utils.system("swapon -a")

            if err:
                if suppress:
                    logging.warn("Some parts of cleanup failed%s", err)
                else:
                    raise error.TestFail("Some parts of cleanup failed%s" %
                                         err)

        # Preparation
        item = Cgroup('memory', self._client)
        item.initialize(self.modules)
        item.smoke_test()
        pwd = item.mk_cgroup()

        logging.debug("test_memory: Memory filling test")
        meminfo = open('/proc/meminfo', 'r')
        mem = meminfo.readline()
        while not mem.startswith("MemFree"):
            mem = meminfo.readline()
        # Use only 1G or max of the free memory
        mem = min(int(mem.split()[1]) / 1024, 1024)
        mem = max(mem, 100)     # at least 100M
        try:
            item.get_property("memory.memsw.limit_in_bytes")
        except error.TestError:
            # Doesn't support memsw limitation -> disabling
            logging.info("System does not support 'memsw'")
            utils.system("swapoff -a")
            memsw = False
        else:
            # Supports memsw
            memsw = True
            # Clear swap
            utils.system("swapoff -a")
            utils.system("swapon -a")
            meminfo.seek(0)
            swap = meminfo.readline()
            while not swap.startswith("SwapTotal"):
                swap = meminfo.readline()
            swap = int(swap.split()[1]) / 1024
            if swap < mem / 2:
                logging.error("Not enough swap memory to test 'memsw'")
                memsw = False
        meminfo.close()
        outf = NamedTemporaryFile('w+', prefix="cgroup_client-",
                                  dir="/tmp")
        logging.debug("test_memory: Initializition passed")

        #
        # Fill the memory without cgroup limitation
        # Should pass
        #
        logging.debug("test_memory: Memfill WO cgroup")
        ps = item.test("memfill %d %s" % (mem, outf.name))
        ps.stdin.write('\n')
        i = 0
        while ps.poll() is not None:
            if i > 60:
                break
            i += 1
            time.sleep(1)
        if i > 60:
            ps.terminate()
            raise error.TestFail("Memory filling failed (WO cgroup)")
        outf.seek(0)
        outf.flush()
        out = outf.readlines()
        if (len(out) < 2) or (ps.poll() != 0):
            raise error.TestFail("Process failed (WO cgroup); output:\n%s"
                                 "\nReturn: %d" % (out, ps.poll()))
        if not out[-1].startswith("PASS"):
            raise error.TestFail("Unsuccessful memory filling "
                                 "(WO cgroup)")
        logging.debug("test_memory: Memfill WO cgroup passed")

        #
        # Fill the memory with 1/2 memory limit
        # memsw: should swap out part of the process and pass
        # WO memsw: should fail (SIGKILL)
        #
        logging.debug("test_memory: Memfill mem only limit")
        ps = item.test("memfill %d %s" % (mem, outf.name))
        item.set_cgroup(ps.pid, pwd)
        item.set_property_h("memory.limit_in_bytes", ("%dM" % (mem / 2)), pwd)
        ps.stdin.write('\n')
        i = 0
        while ps.poll() is not None:
            if i > 120:
                break
            i += 1
            time.sleep(1)
        if i > 120:
            ps.terminate()
            raise error.TestFail("Memory filling failed (mem)")
        outf.seek(0)
        outf.flush()
        out = outf.readlines()
        if (len(out) < 2):
            raise error.TestFail("Process failed (mem); output:\n%s"
                                 "\nReturn: %d" % (out, ps.poll()))
        if memsw:
            if not out[-1].startswith("PASS"):
                logging.error("test_memory: cgroup_client.py returned %d; "
                              "output:\n%s", ps.poll(), out)
                raise error.TestFail("Unsuccessful memory filling (mem)")
        else:
            if out[-1].startswith("PASS"):
                raise error.TestFail("Unexpected memory filling (mem)")
            else:
                filled = int(out[-2].split()[1][:-1])
                if mem / 2 > 1.5 * filled:
                    logging.error("test_memory: Limit = %dM, Filled = %dM (+ "
                                  "python overhead up to 1/3 (mem))", mem / 2,
                                  filled)
                else:
                    logging.debug("test_memory: Limit = %dM, Filled = %dM (+ "
                                  "python overhead up to 1/3 (mem))", mem / 2,
                                  filled)
        logging.debug("test_memory: Memfill mem only cgroup passed")

        #
        # Fill the memory with 1/2 memory+swap limit
        # Should fail
        # (memory.limit_in_bytes have to be set prior to this test)
        #
        if memsw:
            logging.debug("test_memory: Memfill mem + swap limit")
            ps = item.test("memfill %d %s" % (mem, outf.name))
            item.set_cgroup(ps.pid, pwd)
            item.set_property_h("memory.memsw.limit_in_bytes", "%dM"
                                % (mem / 2), pwd)
            ps.stdin.write('\n')
            i = 0
            while ps.poll() is not None:
                if i > 120:
                    break
                i += 1
                time.sleep(1)
            if i > 120:
                ps.terminate()
                raise error.TestFail("Memory filling failed (mem)")
            outf.seek(0)
            outf.flush()
            out = outf.readlines()
            if (len(out) < 2):
                raise error.TestFail("Process failed (memsw); output:\n%s"
                                     "\nReturn: %d" % (out, ps.poll()))
            if out[-1].startswith("PASS"):
                raise error.TestFail("Unexpected memory filling (memsw)",
                                     mem)
            else:
                filled = int(out[-2].split()[1][:-1])
                if mem / 2 > 1.5 * filled:
                    logging.error("test_memory: Limit = %dM, Filled = %dM (+ "
                                  "python overhead up to 1/3 (memsw))", mem / 2,
                                  filled)
                else:
                    logging.debug("test_memory: Limit = %dM, Filled = %dM (+ "
                                  "python overhead up to 1/3 (memsw))", mem / 2,
                                  filled)
            logging.debug("test_memory: Memfill mem + swap cgroup passed")

        #
        # CLEANUP
        #
        cleanup()

    def test_cpuset(self):
        """
        Cpuset test
        1) Initiate CPU load on CPU0, than spread into CPU* - CPU0
        """
        def cleanup(suppress=False):
            """ cleanup """
            logging.debug("test_cpuset: Cleanup")
            err = ""
            try:
                for task in tasks:
                    i = 0
                    for i in range(10):
                        task.terminate()
                        if task.poll() is not None:
                            break
                        time.sleep(1)
                    if i >= 9:
                        logging.error("test_cpuset: Subprocess didn't finish")
            except Exception, inst:
                err += "\nCan't terminate tasks: %s" % inst
            if item.rm_cgroup(pwd):
                err += "\nCan't remove cgroup direcotry"
            if err:
                if suppress:
                    logging.warn("Some parts of cleanup failed%s", err)
                else:
                    raise error.TestFail("Some parts of cleanup failed%s"
                                         % err)

        # Preparation
        item = Cgroup('cpuset', self._client)
        if item.initialize(self.modules):
            raise error.TestFail("cgroup init failed")

        # in cpuset cgroup it's necessarily to set certain values before
        # usage. Thus smoke_test will fail.
        # if item.smoke_test():
        #    raise error.TestFail("smoke_test failed")

        try:
            # Available cpus: cpuset.cpus = "0-$CPUS\n"
            no_cpus = int(item.get_property("cpuset.cpus")[0].split('-')[1])
            no_cpus += 1
        except Exception:
            raise error.TestFail("Failed to get no_cpus or no_cpus = 1")

        pwd = item.mk_cgroup()
        try:
            tmp = item.get_property("cpuset.cpus")[0]
            item.set_property("cpuset.cpus", tmp, pwd)
            tmp = item.get_property("cpuset.mems")[0]
            item.set_property("cpuset.mems", tmp, pwd)
        except Exception:
            cleanup(True)
            raise error.TestFail("Failed to set cpus and mems of"
                                 "a new cgroup")

        #
        # Cpu allocation test
        # Use cpu0 and verify, than all cpu* - cpu0 and verify
        #
        logging.debug("test_cpuset: Cpu allocation test")

        tasks = []
        # Run no_cpus + 1 jobs
        for i in range(no_cpus + 1):
            tasks.append(item.test("cpu"))
            try:
                item.set_cgroup(tasks[i].pid, pwd)
            except error.TestError, inst:
                cleanup(True)
                raise error.TestFail("Failed to set cgroup: %s" % inst)
            tasks[i].stdin.write('\n')
        # Use only the first CPU
        item.set_property("cpuset.cpus", 0, pwd)
        stats = get_load_per_cpu()
        time.sleep(10)
        # [0] = all cpus
        stat1 = get_load_per_cpu(stats)[1:]
        stat2 = stat1[1:]
        stat1 = stat1[0]
        for _stat in stat2:
            if stat1 < _stat:
                cleanup(True)
                raise error.TestFail("Unused processor had higher utilization"
                                     "\nused cpu: %s, remaining cpus: %s"
                                     % (stat1, stat2))

        if no_cpus == 2:
            item.set_property("cpuset.cpus", "1", pwd)
        else:
            item.set_property("cpuset.cpus", "1-%d" % (no_cpus - 1), pwd)
        stats = get_load_per_cpu()
        time.sleep(10)
        stat1 = get_load_per_cpu(stats)[1:]
        stat2 = stat1[0]
        stat1 = stat1[1:]
        for _stat in stat1:
            if stat2 > _stat:
                cleanup(True)
                raise error.TestFail("Unused processor had higher utilization"
                                     "\nused cpus: %s, remaining cpu: %s"
                                     % (stat1, stat2))
        logging.debug("test_cpuset: Cpu allocation test passed")

        #
        # CLEANUP
        #
        cleanup()

    def test_cpu(self):
        """
        tests cpu subsystem.
        Currently only smoke and many_cgroups test is written
        """
        def cleanup(suppress=False):
            """ cleanup """
            logging.debug("test_cpu: Cleanup")
            err = []
            if hasattr(self, 'item'):
                while self.item.cgroups:
                    for _ in range(10):
                        try:
                            self.item.rm_cgroup(0)
                            break
                        except ValueError:
                            break
                        except Exception:
                            pass
                    else:
                        logging.error("Can't remove cgroup %s",
                                      self.item.cgroups[0])
                        del(self.item.cgroups[0])
                try:
                    del(self.item)
                except Exception, failure_detail:
                    err += "\nCan't remove Cgroup: %s" % failure_detail

            if err:
                if suppress:
                    logging.warn("Some parts of cleanup failed%s", err)
                else:
                    raise error.TestFail("Some parts of cleanup failed%s"
                                         % err)

        def _stress_find(cmd):
            """ returns the time of cmd execution """
            duration = time.time()
            err = utils.system(cmd, ignore_status=True)
            duration = time.time() - duration
            if err not in [0, 1]:
                cleanup()
                raise error.TestFail("test cmd failed, ret = %s" % err)
            return duration

        def _stress_cpu(no_cpus):
            """ returns the time of all cpu stress execution """
            stress_cmd = ("for i in `seq 1 128`; do for i in `seq 1 128`;"
                          "do A=$((1024/34)); done; done")
            print "Running %d*'%s'" % (no_cpus, stress_cmd)
            threads = []
            start = time.time()
            for _ in xrange(80):
                threads.append(Popen(stress_cmd, shell=True))
            while threads:
                thread = threads.pop()
                thread.wait()
            return time.time() - start

        # Preparation
        self.item = Cgroup('cpu', self._client)
        self.item.initialize(self.modules)
        self.item.smoke_test()
        logging.info("test_cpu: smoke_test passed")

        #
        # test_cpu_many_cgroups
        # Tests known issue with lots of cgroups in cpu subsystem defined on
        # large SMP host.
        # The test creates 10 cgroups, measure go-throught time, than the same
        # with 110 and 1110 cgroups.
        # IMPORTANT: Is reproducible only on large SMP > 64 cpus
        #
        no_cpus = utils.count_cpus()
        if no_cpus < 64:
            logging.warn("test_cpu_many_cgroups: SKIPPED as it needs >64 "
                         "CPUs on the tested machine.")
            return
        find_cmd = ('find %s -type f -exec cat {} + &>/dev/null' %
                    self.modules.get_pwd('cpu'))
        results_find = []
        results_cpu = []
        # dry run
        _stress_find(find_cmd)
        _stress_cpu(no_cpus)

        logging.debug("test_cpu_many_cgroups: 10 cgroups")
        for i in range(10):
            self.item.mk_cgroup()
        results_find.append(_stress_find(find_cmd))
        results_cpu.append(_stress_cpu(no_cpus))

        logging.debug("test_cpu_many_cgroups: 110 cgroups")
        for i in range(100):
            self.item.mk_cgroup()
        results_find.append(_stress_find(find_cmd))
        results_cpu.append(_stress_cpu(no_cpus))

        logging.debug("test_cpu_many_cgroups: 1110 cgroups")
        for i in range(1000):
            self.item.mk_cgroup()
        results_find.append(_stress_find(find_cmd))
        results_cpu.append(_stress_cpu(no_cpus))

        table = utils.matrix_to_string([['results_cpu'] + results_cpu,
                                       ['results_find'] + results_find],
                                       ['test', '10cgroups', '110cgroups',
                                        '1110cgroups'])
        logging.debug("Results matrix for n-cgroups:\n %s" % table)

        # Those limits are nonlinear and set empirically (based on 80CPUs)
        # Usual ratios on broken kernels:
        # [1, 13, 190] [1, 3, 120]
        # Usual ratios on current kernels:
        # [1, 1, 1.4] [1, 2, 9]
        limits = [None, 3, 15]
        for i in xrange(1, len(results_find)):
            if results_find[i] > (results_find[0] * limits[i]):
                cleanup()
                raise error.TestFail("Find %d took over %s-times longer than "
                                     "find with 10 cgroups" % (i, limits[i]))
        limits = [None, 1.2, 1.5]
        for i in xrange(1, len(results_cpu)):
            if results_cpu[i] > (results_cpu[0] * limits[i]):
                cleanup()
                raise error.TestFail("CPU stress %d took over %s-times longer"
                                     " than with 10 cgroups" % (i, limits[i]))
        #
        # CLEANUP
        #
        cleanup()
