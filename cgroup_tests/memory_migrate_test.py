import os
import itertools
import tempfile
import subprocess
import signal
import time
from autotest.client.shared import error, utils_cgroup


class MemoryMigrate(object):

    """
    Test memory sub system.
    Use it to control file write/read rate.

    1. Clear all cgroups and init modules and parent cgroup.
    2. Create a sub cgroup.
    3. Set property values into desired cgroup.
    4. Apply for memory and get process id.
    5. Classify pid to each cgroup and get memory use
    6. Confirm result.
    7. Recover environment.
    """

    def __init__(self, cgroup_dir=None, tmpdir="/tmp"):
        """
        Get cgroup default mountdir
        """
        self.cgroup_dir = cgroup_dir
        self.tmpdir = tmpdir

    def memory_use_flle(self, memory, memory_file, binary_file):
        """
        Make a C file and compile it

        @param: memory: used memroy
        """
        cfile_detail = """
#include <malloc.h>
#define MAX 1024*1024*%d
int main(void) {
    malloc(MAX);
    while(1);
    return 0;
}
""" % memory
        memory_c_file = open(memory_file, 'w')
        memory_c_file.write(cfile_detail)
        memory_c_file.close()
        if os.system("gcc %s -o %s" % (memory_file, binary_file)):
            raise error.TestError("Compile C file failed!")

        try:
            process = subprocess.Popen(binary_file, shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE)
            return process.pid
        except Exception, err:
            raise error.TestError("Execute malloc process failed!\n"
                                  "%s", err)

    def test(self):
        """
        Start testing
        """
        controller_name = 'memory'
        controller_list = []
        controller_list.append(controller_name)
        # cmd: cgcreate. dir: mkdir
        create_mode_list = ["cmd", "dir"]
        # file: file write directly. cgset: cgset command
        set_mode_list = ["file", "cgset"]
        cgroup_name1 = "test1"
        cgroup_name2 = "test2"
        property_value1 = {'memory.move_charge_at_immigrate': '0'}
        property_value2 = {'memory.move_charge_at_immigrate': '1'}
        get_property = "memory.usage_in_bytes"
        memory_use = 10  # M
        tmp_file = tempfile.NamedTemporaryFile(dir=self.tmpdir).name
        memory_file = tmp_file + ".c"
        binary_file = tmp_file + ".o"
        # Apply for memory
        pid = self.memory_use_flle(memory_use, memory_file, binary_file)
        try:
            for item in itertools.product(create_mode_list, set_mode_list):
                if os.path.exists(tmp_file):
                    os.remove(tmp_file)
                utils_cgroup.all_cgroup_delete()
                modules = utils_cgroup.CgroupModules(self.cgroup_dir)
                modules.init(controller_list)
                cgroup = utils_cgroup.Cgroup(controller_name, None)
                cgroup.initialize(modules)
                cgroup.cgdelete_all_cgroups()

                cgroup_create_mode = item[0]
                property_set_mode = item[1]
                # Create cgroup
                if cgroup_create_mode == "dir":
                    cgroup_index1 = cgroup.mk_cgroup(cgroup=cgroup_name1)
                    cgroup_index2 = cgroup.mk_cgroup(cgroup=cgroup_name2)
                elif cgroup_create_mode == "cmd":
                    cgroup_index1 = cgroup.mk_cgroup_cgcreate(cgroup=
                                                              cgroup_name1)
                    cgroup_index2 = cgroup.mk_cgroup_cgcreate(cgroup=
                                                              cgroup_name2)

                # Set property value
                if property_set_mode == "cgset":
                    for pro in property_value1:
                        cgroup.cgset_property(pro, property_value1.get(pro),
                                              cgroup_index1, check=False)
                    for pro in property_value2:
                        cgroup.cgset_property(pro, property_value2.get(pro),
                                              cgroup_index2, check=False)
                elif property_set_mode == "file":
                    for pro in property_value1:
                        cgroup.set_property(pro, property_value1.get(pro),
                                            cgroup_index1, check=False)
                    for pro in property_value2:
                        cgroup.set_property(pro, property_value2.get(pro),
                                            cgroup_index2, check=False)

                # Classify pid to cgroup_name1
                cgroup.cgclassify_cgroup(pid, cgroup_name1)
                if str(pid) not in cgroup.get_pids(cgroup_index1):
                    raise error.TestFail("Classify pid '%d' into %s failed" %
                                         (pid, cgroup_name1))
                # Apply enough time to get memory use
                time.sleep(3)
                output1 = cgroup.get_property(get_property, cgroup_index1)

                # Classify pid to cgroup_name2
                cgroup.cgclassify_cgroup(pid, cgroup_name2)
                if str(pid) not in cgroup.get_pids(cgroup_index2):
                    raise error.TestFail("Classify pid '%d' into %s failed" %
                                         (pid, cgroup_name2))
                # Apply enough time to get memory use
                time.sleep(3)
                output2 = cgroup.get_property(get_property, cgroup_index2)
                del cgroup
                del modules
                if output1[0] != '0':
                    raise error.TestFail("move_charge_at_immigrate doesn't work"
                                         " in %s" % cgroup_name1)
                if output2[0] == '0':
                    raise error.TestFail("move_charge_at_immigrate doesn't work"
                                         " in %s" % cgroup_name2)
        finally:
            # Recover environment
            os.kill(pid, signal.SIGUSR1)
            utils_cgroup.cgconfig_restart()


def execute(cgroup_cls):
    """
    Execute memory test.

    @param: cgroup_cls: Cgroup class
    """
    if cgroup_cls is None:
        raise error.TestNAError("Got a none cgroup class")
    memory_test = MemoryMigrate(cgroup_cls._cgroup_dir, cgroup_cls.tmpdir)
    memory_test.test()
