#!/usr/bin/env python

"""
The contents of this file are classes and functions to automate opescap
from the source and scan the target system for predefined security compliance
Author: Anup Kumar <anupkumk@linux.vnet.ibm.com>
"""
import re
import sys
import os
import time
import csv
import logging


class openscap(object):

    def __init__(self):

        self.output_file = 'output_file'
        self.openscap_dir = 'openscap'
        self.oval_eval_file = 'ssg-centos7-ds.xml'

    def openscap_setup(self, reinstall=0):
        """
        Function will install the Build dependencies
        """
        build_cmd = "autogen.sh"
        config_cmd = "configure"
        mk_cmd = "make"
        install_log = "openscap_setup_log"
        logging.info("Installing the build related package")

        pkg_list = (
            "dbus-devel",
            "GConf2-devel",
            "libacl-devel",
            "libblkid-devel",
            "libcap-devel",
            "libcurl-devel",
            "libgcrypt-devel",
            "libselinux-devel",
            "python-devel",
            "libxml2-devel",
            "git",
            "libxslt-devel",
            "make",
            "openldap-devel",
            "perl-devel",
            "pcre-devel",
            "rpm-devel",
            "perl-XML-Parser",
            "perl-XML-XPath",
            "swig",
            "bzip2-devel")

        for pkg in pkg_list:
            os.system(
                "yum %s -y %s >%s" %
                (('install', 'reinstall')[reinstall], pkg, self.output_file))

        # install openvas from source
        check_oscap = os.system("which oscap > %s" % self.output_file)
        if check_oscap != 0:
            try:
                mycwd = os.getcwd()
                logging.info("installing the oscap tools from  git source")
                os.system("git clone https://github.com/OpenSCAP/openscap.git")
                os.chdir(self.openscap_dir)
                os.system("/bin/bash %s > %s" % (build_cmd, install_log))
                os.system("/bin/bash %s > %s" % (config_cmd, install_log))
                os.system("%s > %s" % (mk_cmd, install_log))
                os.system("%s install > %s" % (mk_cmd, install_log))
                logging.debug("oscap tools Installed successfully")
                os.chdir(mycwd)

            except OSError as err:
                logging.info("OPENSCAP Failed to Install")
                logging.debug(err)
                sys.exit()
        else:
            logging.debug("oscap tools are available to scan")

    def openscap_oval_scan(self):
        """
        Function will Used to Scan the Target Based on OVAL definition
        """
        f1 = os.popen("cat /etc/os-release").read()
        d_name = re.search('ID="(\S+)"', f1).group(1)
        v_id = re.search('VERSION_ID="(\S+)"', f1).group(1)
        arch_os_ver = os.popen(
            "uname -r").read().rstrip('\n').split('.')[-1]
        full_name = "".join([d_name, v_id])
        self.full_project = "-".join([full_name, arch_os_ver])

        self.cmd_output = "openscap_output-%s-%s" % (
            self.full_project, time.strftime('%Y-%m-%d'))
        self.xml_result = "openscap_results-%s-%s.xml" % (
            self.full_project, time.strftime('%Y-%m-%d'))
        self.html_report = "openscap_report-%s-%s.html" % (
            self.full_project, time.strftime('%Y-%m-%d'))
        try:
            logging.info("Check the system compliance based on oval file")
            os.popen(
                "oscap oval eval --results %s --report %s %s > %s" %
                (self.xml_result, self.html_report, self.oval_eval_file, self.cmd_output))

        except IOError as err:
            logging.info("Openscap Failed to Scan the Target")
            logging.debug(err)
            sys.exit()
        logging.debug(
            "OSCAP Scan result generated in  %s xml file" %
            self.xml_result)
        logging.debug(
            "OSCAP Scan report available in  %s html file" %
            self.html_report)

    def result_parsing(self):
        """
        Function will generate the pass and failed compliance result
        """
        tool_name = 'openscap'
        os_ref = self.full_project.split('-')[0]
        arch = self.full_project.split('-')[-1]
        result_dir = '/root/Security_Results'
        reg_report = "reg_%s-%s-%s.csv" % (tool_name,
                                           self.full_project,
                                           time.strftime('%Y-%m-%d'))
        pass_report = "pass_%s-%s-%s.csv" % (tool_name,
                                             self.full_project,
                                             time.strftime('%Y-%m-%d'))
        logging.info("Generating pass/fail result")

        with open(reg_report, 'w') as fl, open(pass_report, 'w') as ps, open(self.cmd_output, 'r') as fh:
            stripped = (line.strip() for line in fh)
            reg_writer = csv.writer(fl)
            pass_writer = csv.writer(ps)
            reg_writer.writerow(
                ('Tools', 'OS_Name', 'Arch', 'Compliance_Type', 'Severity'))
            pass_writer.writerow(
                ('Tools', 'OS_Name', 'Arch', 'Compliance_Type', 'Severity'))

            for line in stripped:
                if "Evaluation" not in line:
                    t_flag = line.split(":")[4].strip('\n')
                    ucase_flag = line.split(":")[1].split("-")[1].strip('\n')
                    data = [tool_name, os_ref, arch, ucase_flag, t_flag]
                    if t_flag.lstrip() == 'true':
                        pass_writer.writerow(data)
                    else:
                        reg_writer.writerow(data)
        fh.close()
        ps.close()
        fl.close()
        no_of_failed_comp = os.popen("cat %s | wc -l" % reg_report).read()
        no_of_passed_comp = os.popen("cat %s | wc -l" % pass_report).read()
        #logging.info("TOTAL FAILED COMPLIANCE:%s\nCheck \"%s\" for failed details\n" %(no_of_failed_comp, compl_fail))
        #logging.info("TOTAL PASSED COMPLIANCE:%s\nCheck \"%s\" for passed details\n" %(no_of_passed_comp, compl_pass))
        logging.debug(
            "Open %s html file from browser for detail analysis" %
            self.html_report)
        logging.info("Copying the Result Common directory")
        logging.info("Result path is %s" % result_dir)
        if not os.path.exists(result_dir):
            os.makedirs(result_dir)
        os.system(
            "cp %s %s %s %s" %
            (reg_report,
             pass_report,
             self.html_report,
             result_dir))

    def cleanup(self):
        """
        Cleanup function for unused file, data
        """
        try:
            logging.debug("Deleting Unused file")
            os.system("rm  %s" % self.output_file)
            os.system("rm  openscap_setup_log")
            os.system("rm  %s" % self.cmd_output)
            logging.info("Cleanup Done")

        except IOError as err:
            logging.debug(err)


if __name__ == "__main__":

    try:
        obj = openscap()
        obj.openscap_setup()
        obj.openscap_oval_scan()
        obj.result_parsing()

    finally:
        obj.cleanup()
