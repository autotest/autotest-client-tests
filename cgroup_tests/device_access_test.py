import os
import tempfile

from autotest.client.shared import error, utils_cgroup


class DeviceAccess(object):

    """
    Test cgroup devices sub system.
    Use it to control device access deny/allow.

    1. Clear all cgroups and init modules and parent cgroup.
    2. Create a sub cgroup.
    3. Set property1 values into desired cgroup.
    4. Create file in desired cgroup and confirm result.
    5. Set property2 values into desired cgroup.
    6. Create file in desired cgroup and confirm result.
    7. Recover environment.
    """

    def __init__(self, cgroup_dir=None):
        """
        Get cgroup default mountdir
        """
        self.cgroup_dir = cgroup_dir

    def test(self):
        """
        Start testing
        """
        controller_name = 'devices'
        controller_list = []
        controller_list.append(controller_name)
        cgroup_name = "test"
        property_value_before = {"devices.deny": "a 8:0 r"}
        property_value_after = {"devices.allow": "a 8:0 r"}
        # Must belong to "8:0"(sda)
        tmp_file = tempfile.NamedTemporaryFile(dir="/").name
        file_size = "20M"
        try:
            if os.path.exists(tmp_file):
                os.remove(tmp_file)
            utils_cgroup.all_cgroup_delete()
            modules = utils_cgroup.CgroupModules(self.cgroup_dir)
            modules.init(controller_list)
            cgroup = utils_cgroup.Cgroup(controller_name, None)
            cgroup.initialize(modules)
            cgroup.cgdelete_all_cgroups()

            # Create cgroup
            cgroup_index = cgroup.mk_cgroup(cgroup=cgroup_name)

            # Set property_before value
            for pro in property_value_before:
                cgroup.set_property(pro, property_value_before.get(pro),
                                    cgroup_index, check=False)

            # Execute dd command
            cmd_args = []
            cmd_args.append("if=/dev/zero")
            cmd_args.append("of=%s" % tmp_file)
            cmd_args.append("bs=%s" % file_size)
            cmd_args.append("count=1")
            status_before, _ = cgroup.cgexec(cgroup_name, "dd", cmd_args)
            if not status_before or os.path.exists(tmp_file):
                raise error.TestFail("File should not be created!")

            # Set property_after value
            for pro in property_value_after:
                cgroup.set_property(pro, property_value_after.get(pro),
                                    cgroup_index, check=False)
            status_after, _ = cgroup.cgexec(cgroup_name, "dd", cmd_args)
            if status_after and not os.path.exists(tmp_file):
                raise error.TestFail("File created failed!")
        finally:
            if "cgroup" in dir():
                del cgroup
            if "modules" in dir():
                del modules
            # Recover environment
            if os.path.exists(tmp_file):
                os.remove(tmp_file)
            utils_cgroup.cgconfig_restart()


def execute(cgroup_cls):
    """
    Execute device test.

    :param cgroup_cls: Cgroup class
    """
    if cgroup_cls is None:
        raise error.TestNAError("Got a none cgroup class")
    device_access_test = DeviceAccess(cgroup_cls._cgroup_dir)
    device_access_test.test()
