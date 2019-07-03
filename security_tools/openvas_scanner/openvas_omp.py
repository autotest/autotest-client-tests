#!/usr/bin/env python

"""
The contents of this file are classes and functions to automate OPENVAS.
The automation script will be used to setup target, create task, launch scan,
monitor scan from callback function and generate the report in human readable
format on local system. on localhost.Scan will take around 30-45 min
once openvas related setup will be done. scan will be triggered from autotest as well.

Author: Anup Kumar <anupkumk@linux.vnet.ibm.com>

"""


import re
import sys
import os
import time
import csv
from functools import partial
from threading import Event, Timer, Semaphore
from openvas_setup_cli import *


def set_interval(interval, times=-1):
    """
    Decorator to execute a function periodically using a timer
    The function will be executed in a background thread
    """

    def outer_wrap(function):
        if not callable(function):
            raise TypeError(
                "Expected function, got %r instead" %
                type(function))

        # This will be the function to be called
        def wrap(*args, **kwargs):

            stop = Event()

            # This is another function to be executed
            # in a different thread to simulate set_interval
            def inner_wrap():
                i = 0
                while i != times and not stop.isSet():
                    stop.wait(interval)
                    function(*args, **kwargs)
                    i += 1

            t = Timer(0, inner_wrap)
            t.daemon = True
            t.start()

            return stop

        return wrap

    return outer_wrap


def my_print_status(i):
    """
    This function will be used in callback function
    """
    print(str(i))
    sys.stdout.flush


class openvas_cli(openvas_setup_cli):

    def __init__(self, **kwargs):
        """
        """
        openvas_setup_cli.__init__(self)
        # Error counter
        self.error_counter = 0
        # Old progress
        self.old_progress = 0.0
        # Init various vars
        self.function_handle = None
        self.task_report_id = None

    def cleanup(self):
        """
        Remove the unused file after scan completion
        """
        try:
            logging.debug("Restoring the changes")
            os.system("rm  omp.config")
            os.system("rm  target_file")
            os.system("rm  config_file")
            os.system("rm  check_task_init")
            os.system("rm  setup_error_log")
            os.system("rm  setup_log")
            os.system("rm  task_progress")
            os.system("rm  task_file")
            os.system("rm  output_file")
            os.system(
                "mv /etc/yum.repos.d/atomic.repo_org /etc/yum.repos.d/atomic.repo")
            os.system(
                "mv /etc/yum.repos.d/epel.repo_org /etc/yum.repos.d/epel.repo")
            os.system("mv /etc/redis.conf_org /etc/redis.conf")
            if self.check_sepolicy == "Enforcing":
                os.system("setenforce 1")
                logging.info(
                    "Restoring Selinux policy to Enforcing after scan")
            logging.info("Cleanup Done")

        except IOError as err:
            logging.debug(err)

    def check_return_status(self, status):
        """
        Vaildate the submitted  job for target,task, scan and report
        """
        self.status = status
        return_status = {
            '200': 'OK',
            '201': 'OK resource created',
            '202': 'OK request submitted',
            '400': 'Syntax error',
            '401': 'Authenticate first',
            '403': 'Access to resource forbidden',
            '404': 'Resource missing',
            '409': 'Resource busy',
            '500': 'Internal error',
            '503': 'Service temporarily down'
        }

        for key_code, value in return_status.iteritems():
            if key_code == status:
                return value

    def get_configs(self):
        """
        Function will return the config key use to setup the target
        """
        scan_config_file = "config_file"
        os.popen("omp --get-configs >%s" % scan_config_file)

        try:
            full_deep_ulti = os.popen(
                "cat %s | grep  ultimate | grep deep | awk '{print $1}'" %
                (scan_config_file)).read()
            full_deep = os.popen(
                "cat %s | grep  -v ultimate | grep deep | awk '{print $1}'" %
                (scan_config_file)).read()
            full_fast_ulti = os.popen(
                "cat %s | grep  ultimate | grep fast | awk '{print $1}'" %
                (scan_config_file)).read()
            full_fast = os.popen(
                "cat %s | grep  -v ultimate | grep fast | awk '{print $1}'" %
                (scan_config_file)).read()

            if(full_deep_ulti):
                return full_deep_ulti
            elif(full_deep):
                return full_deep
            elif(full_fast_ulti):
                return full_deep
            elif(full_deep):
                return full_deep

        except ResultError as e:
            raise OpenVasServerError(
                "Unable to find configuration id Error: %s" %
                e.message)

    def create_target(self, target_name, host):

        cmd_target = "<create_target><name>%s_%s</name><hosts>%s</hosts></create_target>" % (
            target_name, host, host)
        # checking existing target
        check_target_name = target_name + '_' + host

        logging.info("Target name is: %s" % check_target_name)
        list_target = "target_file"
        os.popen("omp --get-targets >%s" % list_target)
        cmd_target_check = os.system(
            "cat %s | grep  -i %s" %
            (list_target, check_target_name))

        if cmd_target_check == 0:
            target_id = os.popen("cat %s | grep  -i %s | awk '{print $1}'" % (
                list_target, check_target_name)).read()
            logging.debug("Target ID is: %s" % target_id)
            return target_id

        else:
            tg_output = os.popen("omp -X '%s'" % (cmd_target)).read()
            target_code = re.search('status="(\d+)"', tg_output).group(1)
            status_string = self.check_return_status(target_code)
            try:
                if status_string.find("OK") == 0:
                    target_id = re.search(
                        'id="(\w+-\w+-\w+-\w+-\w+)"', tg_output).group(1)
                    logging.debug("Target ID is: %s" % target_id)
                    return target_id

            except ClientError as e:
                raise OpenVasTargetError(
                    "Unable to create the target %s, Error: %s" %
                    (target_name, e.message))

    def create_task(self, config_id, target_id, task_name, host):

        config_id = self.get_configs()
        logging.info("Creating Task")
        t_c1 = "<create_task><name>%s_%s</name><config" % (task_name, host)
        t_c2 = "id=\"%s\"/><target" % (config_id).rstrip('\n')
        t_c3 = "id=\"%s\"/></create_task>" % (target_id).rstrip('\n')
        task_command = " ".join([t_c1, t_c2, t_c3])

        # checking existing task
        check_task_name = task_name + '_' + host
        logging.debug("Task name is: %s" % check_task_name)
        list_task = "task_file"
        os.popen("omp --get-tasks >%s" % list_task)
        cmd_task_check = os.system(
            "cat %s | grep  -i %s" %
            (list_task, check_task_name))

        if cmd_task_check == 0:
            task_id = os.popen("cat %s | grep  -i %s | awk '{print $1}'" % (
                list_task, check_task_name)).read()
            logging.debug("Task ID is:%s" % task_id)
            return task_id

        else:
            task_output = os.popen("omp -X '%s'" % (task_command)).read()
            status_code = re.search('status="(\d+)"', task_output).group(1)
            status_string = self.check_return_status(status_code)
            try:
                if status_string.find("OK") == 0:
                    task_id = re.search(
                        'id="(\w+-\w+-\w+-\w+-\w+)"',
                        task_output).group(1)
                    logging.debug("Task ID is:%s" % task_id)
                    return task_id

            except ClientError as e:
                raise OpenVasProfileError(
                    "Unable to create task %s, Error: %s" %
                    (check_task_name, e.message))

    def start_scan(self, task_id):
        self.task_id = task_id
        s_s1 = "<start_task"
        s_s2 = "task_id=\"%s\"/>" % (self.task_id).rstrip('\n')

        scan_command = " ".join([s_s1, s_s2])
        logging.info("Starting the OPENVAS System  Scan in few Sec")
        scan_output = os.popen("omp -X '%s'" % (scan_command)).read()
        scan_code = re.search('status="(\d+)"', scan_output).group(1)
        status_string = self.check_return_status(scan_code)

        try:
            if status_string.find("OK") == 0:
                task_report_id = re.search(
                    '>(\w+-\w+-\w+-\w+-\w+)<', scan_output).group(1)
                logging.debug("Report id is %s" % task_report_id)
                return task_report_id

        except ClientError as e:
            raise OpenVasClientError(
                "Scan failed to start Error: %s" %
                e.message)
            sys.exit()

    def delete_task(self, task_id):
        """
        Delete the Schedule task for cleanup
        """
        self.task_id = task_id
        logging.info("Deleting the Task %s" % self.task_id)
        try:
            os.system("omp -D %s" % self.task_id)

        except ServerError as e:
            raise OpenVasServerError(
                "Unable to delete the task %s, Error: %s" %
                (task_id, e.message))

    def monitor_scan(self):

        semp = Semaphore(0)
        self.call_back_end = partial(lambda x: x.release(), semp)
        self.call_back_progress = my_print_status

        # print "call back_end is %s" %self.callback_end
        # print "call back_progress is %s" %self.callback_progress
        logging.info("Scan in progress\n")

        # Callback is set?
        if self.call_back_end or self.call_back_progress:
            # schedule a function to run in 15 seconds to Monitor the Callback
            logging.debug(
                "Wait to Finish the Scan, Monitoring job in every 15 sec")
            self.function_handle = self.callback(
                self.call_back_end, self.call_back_progress)

        semp.acquire()

    def is_task_running(self, task_id):
        """
        task will run in either "Running" or "Requested"
        """
        # Get status of task
        self.task_id = task_id
        status_task_file = "check_task_init"
        os.popen("omp --get-tasks >%s" % status_task_file)
        task_status = os.popen(
            "cat %s | grep  -i \"%s\" | awk '{print $2}'" %
            (status_task_file, self.task_id)).read().rstrip('\n')

        if task_status is None:
            logging.debug("Task not found")
        else:
            return task_status in ("Running", "Requested")

    def get_tasks_progress(self, task_id):
        """
        Get the progress of the task.

        """
        if not isinstance(task_id, str):
            raise TypeError("Expected string, got %r instead" % type(task_id))

        t_progress = 0.0  # Task Progress Statics

        # Get task progress status

        status_task_file = "task_progress"
        os.popen("omp --get-tasks >%s" % status_task_file)
        task_status = os.popen(
            "cat %s | grep  -i \"%s\" | awk '{print $2}'" %
            (status_task_file, self.task_id)).read().rstrip('\n')
        if task_status is None:
            logging.debug("Task not found")

        elif task_status in ("Running", "Pause Requested", "Paused"):
            h1 = os.popen("cat %s | grep  -i \"%s\" | awk '{print $3}'" % (
                status_task_file, self.task_id)).read().rstrip('\n')

            h = h1.rstrip('%')
            if h is not None:
                t_progress += float(h)

        elif task_status in ("Delete Requested", "Done", "Stop Requested", "Stopped", "Internal Error"):
            return 100.0  # Task finished

        logging.debug("Monitoring Scan,Wait to complete")
        return t_progress

    @set_interval(15.0)
    def callback(self, func_end, func_status):
        """
        This callback function is called periodically from a timer.

        :func_end: Function called when task end.
        :type func_end: funtion pointer
        :param func_status: Function called for update task status.
        :type func_status: funtion pointer

        """
        # Check if audit was finished
        try:
            if not self.is_task_running(self.task_id):
                # Task is finished. Stop the callback interval
                self.function_handle.set()

                # Call the callback function
                if func_end:
                    func_end()

                    # Reset error counter
                    self.error_counter = 0

        except ServerError as e:
            raise OpenVasTaskNotFinishedError(
                "Task is not running Error: %s" % e.message)

            self.error_counter += 1

            # Checks for error number
            if self.error_counter >= 5:
                # Stop the callback interval
                self.function_handle.set()
                func_end()

        if func_status:
            try:
                t = self.get_tasks_progress(self.task_id)

                # Save old progress
                self.old_progress = t
                func_status(1.0 if t == 0.0 else t)

            except ServerError as e:
                raise OpenVasScanError(
                    "Unable to find the running Task Progress Error: %s" %
                    e.message)

                func_status(self.old_progress)

    def create_report(self, report_id):
        '''
        Function will generate the report in csv and html format. it will also
        parse the output for regression dashboard
        '''
        self.report_id = report_id
        tool_name = 'openvas'
        os_ref = self.full_project.split('-')[0]
        arch = self.full_project.split('-')[-1]
        result_dir = '/root/Security_Results'
        scan_report_csv = "%s-%s-%s.csv" % (tool_name,
                                            self.full_project,
                                            time.strftime('%Y-%m-%d'))
        scan_report_html = "%s-%s-%s.html" % (tool_name,
                                              self.full_project,
                                              time.strftime('%Y-%m-%d'))
        reg_report = "reg_%s-%s-%s.csv" % (tool_name,
                                           self.full_project,
                                           time.strftime('%Y-%m-%d'))
        logging.info("Report ID is:%s" % self.report_id)

        csv_report_id = os.popen(
            "omp --get-report-formats | grep 'CSV'| grep 'Results'| awk '{print $1}'").read().rstrip('\n')

        #text_report_id = os.popen("omp --get-report-formats |grep 'TXT'| awk '{print $1}'").read().rstrip('\n')
        #xml_report_id = os.popen("omp --get-report-formats|grep 'XML'| grep -v 'Anonymous'|awk '{print $1}'").read().rstrip('\n')
        html_report_id = os.popen(
            "omp --get-report-formats | grep 'HTML'| awk '{print $1}'").read().rstrip('\n')

        # create report in different format
        logging.info("Generating Report in CSV and HTML")
        try:
            os.system(
                "omp --get-report %s --format %s > %s" %
                (self.report_id, csv_report_id, scan_report_csv))
            os.system("omp --get-report %s --format %s > %s" %
                      (self.report_id, html_report_id, scan_report_html))
            if os.stat(scan_report_csv).st_size > 0:
                with open(scan_report_csv, 'r') as ar, open(reg_report, 'w') as rr:
                    data = csv.reader(ar)
                    reg_data = [[tool_name, os_ref, arch, row[7], row[5]]
                                for row in data]
                    output = csv.writer(rr)
                    for row in reg_data:
                        output.writerow(row)
                ar.close()
                rr.close()
                os.system("sed -i '1s/%s/OS_Name/' %s" % (os_ref, reg_report))
                os.system("sed -i '1s/%s/Arch/' %s" % (arch, reg_report))
                os.system("sed -i '1s/%s/Tools/' %s" % (tool_name, reg_report))

                logging.info("Copying the Result Common directory")
                logging.info("Result path is %s" % result_dir)
                if not os.path.exists(result_dir):
                    os.makedirs(result_dir)
                os.system(
                    "cp %s %s %s %s" %
                    (scan_report_csv,
                     scan_report_html,
                     reg_report,
                     result_dir))

            else:
                logging.debug("Report doesn't exist Check Openvas Setup")

        except ResultError as e:
            raise OpenVasTaskNotFinishedError(
                "Unable to Create report Error: %s %s" %
                (self.report_id, e.message))


if __name__ == "__main__":

    try:
        obj = openvas_cli()
        obj.client_omp_config()
        obj.openvas_repo_setup()
        obj.install_openvas_pkg()
        obj.openvas_data_setup()
        obj.check_openvas_services()
        obj.verify_setup()
        config_id = obj.get_configs()
        target_id = obj.create_target('omp_scan', 'localhost')
        task_id = obj.create_task(
            config_id, target_id, 'omp_scan', 'localhost')
        task_report_id = obj.start_scan(task_id)
        obj.monitor_scan()
        obj.create_report(task_report_id)

    finally:
        obj.delete_task(task_id)
        obj.cleanup()
