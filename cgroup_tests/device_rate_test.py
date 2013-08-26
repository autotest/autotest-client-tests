import os, itertools, tempfile
from autotest.client.shared import error, utils_cgroup

class DeviceRate(object):
    """
    Test cgroup blkio sub system.
    Use it to control file write/read rate.

    1. Clear all cgroups and init modules and parent cgroup.
    2. Create a sub cgroup.
    3. Set property values into desired cgroup.
    4. Create file in desired cgroup.
    5. Record file create rate and confirm result.
    6. Recover environment.
    """

    def __init__(self, cgroup_dir=None):
        """
        Get cgroup default mountdir
        """
        self.cgroup_dir = cgroup_dir


    def get_create_rate(self, output):
        """
        Get file create rate by "dd" command output.

        @param: output: "dd" command output
        @return: File create rate.(1.1M: return 1.1, 512Kib: return 512)
        """
        try:
            rate_line = output.splitlines()[-1]
            rate = rate_line.split()[-2]
            return float(rate)
        except (IndexError, ValueError):
            return None


    def test(self):
        """
        Start testing
        """
        controller_name = 'blkio'
        controller_list = []
        controller_list.append(controller_name)
        # cmd: cgcreate. dir: mkdir
        create_mode_list = ["cmd", "dir"]
        # file: file write directly. cgset: cgset command
        set_mode_list = ["file", "cgset"]
        cgroup_name = "test"
        property_value = {'blkio.throttle.read_bps_device':'8:0  1048576',
                          'blkio.throttle.write_bps_device':'8:0  524288'}
        # Must belong to "8:0"(sda)
        tmp_file = tempfile.NamedTemporaryFile(dir="/").name
        file_size = "20M"
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
                    cgroup_index = cgroup.mk_cgroup(cgroup=cgroup_name)
                elif cgroup_create_mode == "cmd":
                    cgroup_index = cgroup.mk_cgroup_cgcreate(cgroup=cgroup_name)

                # Set property value
                if property_set_mode == "cgset":
                    for pro in property_value:
                        cgroup.cgset_property(pro, property_value.get(pro),
                                              cgroup_index, check=False)
                elif property_set_mode == "file":
                    for pro in property_value:
                        cgroup.set_property(pro, property_value.get(pro),
                                            cgroup_index, check=False)

                # Execute dd command
                cmd_args1 = []
                cmd_args1.append("if=/dev/zero")
                cmd_args1.append("of=%s" % tmp_file)
                cmd_args1.append("bs=%s" % file_size)
                cmd_args1.append("count=1")
                cmd_args1.append("oflag=direct")
                cmd_args2 = []
                cmd_args2.append("if=%s" % tmp_file)
                cmd_args2.append("of=/dev/null")
                cmd_args2.append("bs=%s" % file_size)
                cmd_args2.append("count=1")
                cmd_args2.append("iflag=direct")
                status_write, output_write = cgroup.cgexec(cgroup_name, "dd",
                                                           cmd_args1)
                if status_write and not os.path.exists(tmp_file):
                    raise error.TestError("File wirte failed!")
                rate_write = self.get_create_rate(output_write)
                _, output_read = cgroup.cgexec(cgroup_name, "dd",
                                               cmd_args2)
                if status_write:
                    raise error.TestError("File read failed!")
                rate_read = self.get_create_rate(output_read)
                del cgroup
                del modules
                if rate_write is None or rate_read is None:
                    raise error.TestFail("Get file write/read rate failed!")
                if (rate_write < (512.0 - 20)) or (rate_write > (512.0 + 20)):
                    raise error.TestFail("File create rate test failed!"
                                         "\nrate_write = %s" % rate_write)
                if (rate_read < 0.9) or (rate_read > 1.1):
                    raise error.TestFail("File create rate test failed!"
                                         "\nrate_read = %s" % rate_read)
        finally:
            # Recover environment
            if os.path.exists(tmp_file):
                os.remove(tmp_file)
            utils_cgroup.cgconfig_restart()
