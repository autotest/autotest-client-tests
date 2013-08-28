import os, tempfile, signal, time, threading, stat, logging
from autotest.client.shared import error, utils_cgroup, utils, pexpect

def cpu_use_flle(shell_file):
    """
    Make a shell file to get high load cpu
    @param: file_path: Shell file path
    @param: file_name: Shell file name
    """
    if os.path.isfile(shell_file):
        os.remove(shell_file)
    shell_detail = """
while true
do
    j==\${j:+1}
    j==\${j:-1}
done
EOF"""
    sh_file = open(shell_file, 'w')
    sh_file.write(shell_detail)
    sh_file.close()
    os.chmod(shell_file, stat.S_IRWXU|stat.S_IRGRP|stat.S_IROTH)


def get_cpu_rate(pid_list):
    """
    Get pid's cpu rate

    @return dict: {pid1:rate1, pid2:rate2}
    """
    try:
        dic_pid = {}
        for pid in pid_list:
            cmd = ("ps aux|grep %d|grep -v 'grep'|awk '{print $3}'" %
                   int(pid.strip()))
            result = utils.run(cmd, ignore_status=False)
            cpu_rate = result.stdout.strip()
            dic_pid[pid] = cpu_rate.split('\n')[-1]
        return dic_pid
    except Exception, detail:
        raise error.TestFail("Get pid cpu rate failed!\n%s" % detail)


def kill_pids(pid):
    """
    Kill pid in cgroup
    """
    try:
        if isinstance(pid, int):
            os.kill(pid, signal.SIGUSR1)
        elif isinstance(pid, list):
            for sub_pid in pid:
                os.kill(int(sub_pid), signal.SIGUSR1)
    except Exception, detail:
        logging.info("Kill process failed!\n%s" % detail)


def mk_dic_property(controller_list, property_value):
    """
    Get controller dict
    return: dict: {controller1:{controller1.pro1:value, controller1.pro2:value},
                   controller2:{controller2.pro1:value, controller2.pro2:value}}
    """
    dic_controller_property = {}
    for controller in controller_list:
        dic_controller_property[controller] = ""
        dict_property_value = {}
        for key in property_value:
            if key.split(".")[0] == controller:
                dict_property_value[key] = property_value[key]
        dic_controller_property[controller] = dict_property_value
    return dic_controller_property


def cgconfig_file_modify(cgconfig_file, controller_list,
                         dic_cgroup_property, cgroup_cls):
    """
    Modify /etc/cgconfig.conf file to control cgroup configuration
    """
    controllers = ','.join(controller_list)
    cmd = "vi %s" % cgconfig_file
    try:
        session = pexpect.spawn(cmd)
        time.sleep(1)
        session.send('i')
        time.sleep(1)
        # hierarchy part
        session.sendline('mount {')
        for controller in controller_list:
            session.sendline("""%s = "%s";""" %
                             (controller, cgroup_cls.root))
            time.sleep(1)
        session.sendline('}')
        time.sleep(1)
        session.send('\x1b')
        time.sleep(1)
        session.send('o')
        time.sleep(1)
        # cgroup part
        for cgroup in dic_cgroup_property:
            session.sendline('group %s {' % cgroup)
            time.sleep(1)
            dic_controller_property = dic_cgroup_property.get(cgroup)
            for controller in dic_controller_property:
                session.sendline('%s {' %  controller)
                time.sleep(1)
                dic_property = dic_controller_property.get(controller)
                if dic_property is None or dic_property == '':
                    session.sendline('}')
                    time.sleep(1)
                    continue
                for property in dic_property:
                    session.sendline("""%s = "%s";""" % (property,
                                     dic_property.get(property)))
                    time.sleep(1)
                session.sendline('}')
                time.sleep(1)
            session.sendline('}')
        session.send('\x1b')
        time.sleep(1)
        session.send('ZZ')
        time.sleep(1)
        session.close()
    except Exception, detail:
        raise error.TestFail("Edit cgconfig file failed!\n%s" % detail)


class CpuHighLoad(object):
    """
    Test cpu sub system.
    Use it to control cpu rate.

    1. Clear all cgroups and init modules and parent cgroup.
    2. Create 2 sub cgroups.
    3. Set property values into desired cgroups.
    4. Execute process in each cgroup and get cpu rate
    5. Confirm result.
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
        controller_name = 'cpu,cpuset'
        controller_list = controller_name.split(",")
        cgroup_name1 = "test1"
        cgroup_name2 = "test2"
        cgconfig_file = "/etc/cgconfig.conf"
        property_value1 = {"cpu.shares":"500",
                           "cpuset.cpus":"1",
                           "cpuset.mems":"0"}
        property_value2 = {"cpu.shares":"1000",
                           "cpuset.cpus":"1",
                           "cpuset.mems":"0"}
        tmp_file1 = tempfile.NamedTemporaryFile(dir=self.tmpdir).name + ".sh"
        tmp_file2 = tempfile.NamedTemporaryFile(dir=self.tmpdir).name + ".sh"
        cpu_use_flle(tmp_file1)
        cpu_use_flle(tmp_file2)
        backup_cmd = "mv -f %s %s.bak" % (cgconfig_file, cgconfig_file)
        recover_cmd = "mv -f %s.bak %s" % (cgconfig_file, cgconfig_file)
        if utils.run(backup_cmd, ignore_status=True).exit_status != 0:
            raise error.TestNAError("Backup cgconfig file failed!")
        try:
            utils_cgroup.all_cgroup_delete()
            modules = utils_cgroup.CgroupModules(self.cgroup_dir)
            modules.init([controller_name])
            cgroup = utils_cgroup.Cgroup(controller_name, None)
            cgroup.initialize(modules)
            cgroup.cgdelete_all_cgroups()

            dic_cgroup_property = {}
            dic_cgroup_property[cgroup_name1] = mk_dic_property(controller_list,
                                                                property_value1)
            dic_cgroup_property[cgroup_name2] = mk_dic_property(controller_list,
                                                                property_value2)
            cgconfig_file_modify(cgconfig_file, controller_list,
                                 dic_cgroup_property, cgroup)

            utils_cgroup.cgconfig_restart()
            # After cgconfig restart, there are some cgroups created automatically
            cgroup.refresh_cgroups()
            cgroup_index1 = cgroup.get_cgroup_index(cgroup=cgroup_name1)
            cgroup_index2 = cgroup.get_cgroup_index(cgroup=cgroup_name2)
            threads = []
            cgroup_name = []
            cgroup_name.append(cgroup_name1)
            cgroup_name.append(cgroup_name2)
            sh_path = []
            sh_path.append(tmp_file1)
            sh_path.append(tmp_file2)
            for i in range(0, 2):
                thd = threading.Thread(
                    target=cgroup.cgexec,
                    args=(cgroup_name[i], sh_path[i]))
                threads.append(thd)
            # Start process
            for i in range(0, 2):
                threads[i].start()
            time.sleep(3)
            pid_list1 = cgroup.get_pids(cgroup_index1)
            pid_list2 = cgroup.get_pids(cgroup_index2)
            pid_rate1 = get_cpu_rate(pid_list1)
            pid_rate2 = get_cpu_rate(pid_list2)
            kill_pids(pid_list1)
            kill_pids(pid_list2)
            del cgroup
            del modules
            if pid_rate1.get(pid_list1[-1]) <= pid_rate2.get(pid_list1[-1]):
                raise error.TestFail("cpu rate test pid rate failed!")
        finally:
            # Recover environment
            utils.run(recover_cmd)
            utils_cgroup.cgconfig_restart()


def execute(cgroup_cls):
    """
    Execute cpu test.

    @param: cgroup_cls: Cgroup class
    """
    if cgroup_cls is None:
        raise error.TestNAError("Got a none cgroup class")
    cpu_test = CpuHighLoad(cgroup_cls._cgroup_dir, cgroup_cls.tmpdir)
    cpu_test.test()
