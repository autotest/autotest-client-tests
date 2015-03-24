import os
import subprocess
import time
import logging

from autotest.client import utils
from autotest.client.shared import error, utils_cgroup


class MemoryLimit(object):

    """
    Test memory sub system.
    Use it to control memory resource.

    1. Clear all cgroups and init modules and parent cgroup.
    2. Create 2 sub cgroups.
    3. Set property values into desired cgroup.
    4. Apply for memory and get process id.
    5. Classify pid to each cgroup and get memory information
    6. Confirm result.
    7. Recover environment.
    """

    def __init__(self, cgroup_dir=None, tmpdir="/tmp", bindir="/tmp"):
        """
        Get cgroup default mountdir
        """
        self.cgroup_dir = cgroup_dir
        self.tmpdir = tmpdir
        self.bindir = bindir

    def test(self):
        """
        Start testing
        """
        controller_name = 'memory'
        controller_list = [controller_name]
        cgroup_name1 = "test1"
        cgroup_name2 = "test2"
        memory_use = 60  # M
        test_memory1 = memory_use + 10  # M
        test_memory2 = memory_use - 10  # M
        property_values1 = {'memory.move_charge_at_immigrate': '1',
                            'memory.limit_in_bytes': '%dM' % test_memory1,
                            'memory.memsw.limit_in_bytes': '%dM' % test_memory1,
                            'memory.swappiness': '0'}
        property_values2 = {'memory.move_charge_at_immigrate': '1',
                            'memory.limit_in_bytes': '%dM' % test_memory2,
                            'memory.memsw.limit_in_bytes': '%dM' % test_memory2,
                            'memory.swappiness': '0'}
        get_property_list = ['memory.limit_in_bytes',
                             'memory.max_usage_in_bytes',
                             'memory.memsw.usage_in_bytes',
                             'memory.memsw.max_usage_in_bytes']
        memory_file = os.path.join(self.bindir, "memory_use.c")
        binary_file = os.path.join(self.tmpdir, "memory_use.o")

        def get_property_dict(cgroup_index, get_property_list):
            """
            Get all property value in desired cgroup

            @param: cgroup_index: Desired cgroup index
            @param: get_property_list: Property list
            @return property dict:{property1:value1, property2,value2}
            """
            output_property_dic = {}
            for pro in get_property_list:
                output = cgroup.get_property(pro, cgroup_index)
                output_property_dic[pro] = output[0]
            return output_property_dic

        try:
            # Apply for memory
            pid = execute_stresser(memory_use, memory_file, binary_file)
            utils_cgroup.all_cgroup_delete()
            modules = utils_cgroup.CgroupModules(self.cgroup_dir)
            modules.init(controller_list)
            cgroup = utils_cgroup.Cgroup(controller_name, None)
            cgroup.initialize(modules)
            cgroup.cgdelete_all_cgroups()

            # Create cgroup
            cgroup_index1 = cgroup.mk_cgroup(cgroup=cgroup_name1)
            cgroup_index2 = cgroup.mk_cgroup(cgroup=cgroup_name2)

            # Set property value
            # 'memory.limit_in_bytes' must be set first, if not,
            # 'memory.memsw.limit_in_bytes' will fail
            _pro = 'memory.limit_in_bytes'
            cgroup.cgset_property(_pro, property_values1.get(_pro),
                                  cgroup_index1, check=False)
            for property, value in property_values1.iteritems():
                cgroup.cgset_property(property, value,
                                      cgroup_index1, check=False)
            cgroup.cgset_property(_pro, property_values2.get(_pro),
                                  cgroup_index2, check=False)
            for property, value in property_values2.iteritems():
                cgroup.cgset_property(property, value,
                                      cgroup_index2, check=False)

            # Classify pid to cgroup_name1
            cgroup.cgclassify_cgroup(pid, cgroup_name1)

            # Apply enough time to get memory use
            time.sleep(3)
            all_property_dict = {}
            property_dict1 = get_property_dict(cgroup_index1,
                                               get_property_list)
            all_property_dict[cgroup_name1] = property_dict1
            # Kill process to free memory
            if os.path.exists("/proc/%d/stat" % pid):
                logging.debug("Kill process %d to free memory" % pid)
                os.kill(pid, 9)
            pid = execute_stresser(memory_use, memory_file, binary_file)
            # Classify pid to cgroup_name2
            cgroup.cgclassify_cgroup(pid, cgroup_name2)

            # Apply enough time to get memory use
            time.sleep(3)
            property_dict2 = get_property_dict(cgroup_index2,
                                               get_property_list)
            all_property_dict[cgroup_name2] = property_dict2
            if os.path.exists("/proc/%d/stat" % pid):
                logging.debug("Kill process %d to free memory" % pid)
                os.kill(pid, 0)
            # Check output
            for sub_pro in all_property_dict:
                property_check(all_property_dict.get(sub_pro), memory_use)
        finally:
            # Recover environment
            if "modules" in dir():
                del modules
            if "pid" in dir():
                if os.path.exists("/proc/%d/stat" % pid):
                    os.kill(pid, 9)
            utils_cgroup.cgconfig_restart()


def execute_stresser(memory, memory_file, binary_file):
    """
    Make a C file and compile it

    @param: memory: used memroy
    @param: memory_file: C file to malloce memory
    @param: binary_file: binary file
    """
    if os.system("%s %s -o %s" % (utils.get_cc(), memory_file, binary_file)):
        raise error.TestNAError("Compile C file failed!")
    try:
        memory_use_cmd = "%s %d" % (binary_file, memory)
        process = subprocess.Popen(memory_use_cmd, shell=True,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        return process.pid
    except Exception, err:
        raise error.TestNAError("Execute malloc process failed!\n"
                                "%s", err)


def property_check(property_dict, memory):
    """
    Check property value is right or not

    @param: property_dict: Checked property dict
    @param: memory: Memory process used, for example:10M
    """
    logging.debug(property_dict)
    memory_limit = int(property_dict.get('memory.limit_in_bytes'))
    max_usage = int(property_dict.get('memory.max_usage_in_bytes'))
    memsw_usage = int(property_dict.get('memory.memsw.usage_in_bytes'))
    memsw_max = int(property_dict.get('memory.memsw.max_usage_in_bytes'))
    if (memory * 1024 * 1024) > memory_limit:
        # process will be killed in this switch
        if max_usage != memory_limit:
            raise error.TestFail("max_usage should equal with memory_limit")
        if memsw_usage:
            raise error.TestFail("memsw_usage should be 0!")
        if memsw_max != memory_limit:
            raise error.TestFail("memsw_max should equal with memory_limit")
    else:
        if max_usage / 1024 / 1024 != memory:
            raise error.TestFail("max_usage should equal with memory use")
        if not memsw_usage:
            raise error.TestFail("memsw_usage should not be 0!")
        if memsw_max / 1024 / 1024 != memory:
            raise error.TestFail("memsw_max should equal with memory use")


def execute(cgroup_cls):
    """
    Execute memory test.

    :param cgroup_cls: Cgroup class
    """
    if cgroup_cls is None:
        raise error.TestNAError("Got a none cgroup class")
    memory_limit_test = MemoryLimit(cgroup_cls._cgroup_dir, cgroup_cls.tmpdir,
                                    cgroup_cls.bindir)
    memory_limit_test.test()
