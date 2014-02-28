import os
import tempfile
import subprocess
import signal
import stat
from autotest.client.shared import error, utils_cgroup, utils


def stress_process(shell_file):
    """
    Make a shell file to execute
    @param: shell_file: Shell file path
    @return: pid
    """
    if os.path.isfile(shell_file):
        os.remove(shell_file)
    shell_detail = """
while true
do
    j==\${j:+1}
    j==\${j:-1}
done
"""
    sh_file = open(shell_file, 'w')
    sh_file.write(shell_detail)
    sh_file.close()
    os.chmod(shell_file, stat.S_IRWXU | stat.S_IRGRP | stat.S_IROTH)
    try:
        process = subprocess.Popen(shell_file, shell=True,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        return process.pid
    except Exception, err:
        raise error.TestError("Execute process failed!\n"
                              "%s", err)


def get_pid_state(pid_list):
    """
    Get pid's state

    @param: pid_list: pid list
    @return dict: {pid1:state1, pid2:state2}
    """
    try:
        dic_pid = {}
        for pid in pid_list:
            if isinstance(pid, str):
                pid = int(pid.strip())
            proc_file = open("/proc/%d/stat" % pid, "r")
            proc_stats = proc_file.read()
            proc_file.close()
            dic_pid[pid] = proc_stats.split()[2]
        return dic_pid
    except Exception, detail:
        raise error.TestFail("Get pid state failed!\n%s" % detail)


RUNNING = "R"
SLEEPING = "D"


class FreezerProcess(object):

    """
    Test freezer sub system.
    Use it to control process state in cgroup.

    1. Clear all cgroups and init modules and parent cgroup.
    2. Create a sub cgroup, and classify a pid into cgroup.
    3. Get pid state and confirm it's right.
    4. Set property values(FROZEN) into desired cgroup and
       confirm pid state
    5. Set property values(THAWED) into desired cgroup and
       confirm pid state
    6. Recover environment.
    """

    def __init__(self, cgroup_dir=None, tmpdir="/tmp"):
        """
        Get cgroup default mountdir
        """
        self.cgroup_dir = cgroup_dir
        self.tmpdir = tmpdir

    def test(self):
        """
        Start testing
        """
        controller_name = 'freezer'
        cgroup_name = "test"
        property_value_frozen = {'freezer.state': 'FROZEN'}
        property_value_thawed = {'freezer.state': 'THAWED'}
        tmp_file = tempfile.NamedTemporaryFile(dir=self.tmpdir).name
        shell_file = tmp_file + ".sh"
        pid = stress_process(shell_file)
        try:
            if os.path.exists(tmp_file):
                os.remove(tmp_file)
            utils_cgroup.all_cgroup_delete()
            modules = utils_cgroup.CgroupModules(self.cgroup_dir)
            modules.init([controller_name])
            cgroup = utils_cgroup.Cgroup(controller_name, None)
            cgroup.initialize(modules)
            cgroup.cgdelete_all_cgroups()

            # Create cgroup
            cgroup_index = cgroup.mk_cgroup_cgcreate(cgroup=cgroup_name)

            # Classify pid to cgroup_name
            cgroup.cgclassify_cgroup(pid, cgroup_name)
            if str(pid) not in cgroup.get_pids(cgroup_index):
                raise error.TestFail("Classify pid '%d' into %s failed" %
                                     (pid, cgroup_name))
            pid_state = get_pid_state([pid])
            # Defaultly freezer.state is "THAWED",
            # process should be running normally
            if pid_state.get(pid).strip() != RUNNING:
                raise error.TestFail("It should be running!")

            # Set property value to frozen process
            for pro in property_value_frozen:
                cgroup.cgset_property(pro, property_value_frozen.get(pro),
                                      cgroup_index, check=False)
            pid_state_frozen = get_pid_state([pid])
            if pid_state_frozen.get(pid).strip() != SLEEPING:
                # If freezer.state isn't set to 'THAWED',
                # pid cannot be killed.
                for pro in property_value_thawed:
                    cgroup.cgset_property(pro, property_value_thawed.get(pro),
                                          cgroup_index, check=False)
                raise error.TestFail("It should be sleeping!")

            # Set property value to thawed process
            for pro in property_value_thawed:
                cgroup.cgset_property(pro,
                                      property_value_thawed.get(pro),
                                      cgroup_index, check=False)
            pid_state_thawed = get_pid_state([pid])
            if pid_state_thawed.get(pid).strip() != RUNNING:
                raise error.TestFail("It should be running!")
        finally:
            # Recover environment
            if "cgroup" in dir():
                del cgroup
            if "modules" in dir():
                del modules
            os.kill(pid, signal.SIGUSR1)
            utils_cgroup.cgconfig_restart()


def execute(cgroup_cls):
    """
    Execute freezer test.

    @param: cgroup_cls: Cgroup class
    """
    if cgroup_cls is None:
        raise error.TestNAError("Got a none cgroup class")
    freezer_test = FreezerProcess(cgroup_cls._cgroup_dir, cgroup_cls.tmpdir)
    freezer_test.test()
