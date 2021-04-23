#!/usr/bin/python

#########################################################
#
# THIS IS BUILD CONF FILE , MODIFY BASED ON YOUR NEED
#
#########################################################

class generic_conf:
    build_type = "UBUNTU"                                                       				 # Give CUSTOM/UBUNTU/CENTOS/RHEL for respective build
    basedir = "/var/tmp/ubuntu_build"                                 				         	 # Change this baseed on your requirement
    logdir = "%s/logs" %basedir
    logfile = "%s/final_report.logs" %logdir
    package_list_file = "/home/ubuntu/autotest-build-tools/input_file"   			           	 # This file will contain the package name to be build
    binary_src_dir = "%s/autotest-binaries" %basedir								 # All the compile binaries will be copied in this location, you can change based on your requirement
    sms_notofication = "n"											# 'n' for no, this feature is only available for INDIA
    mobile_number = "" # Only applicable for india number
    python_modules = [ 'pyvirtualdisplay','selenium',]



class ubuntu_conf:
    build_src_distribution = ['xenial']                                        				 # for rhel or suse mentioned the distribution name or distribution version rhel7.4 for building
    #build_src_distribution = ['zesty']                                          				 # for rhel or suse mentioned the distribution name or distribution version rhel7.4 for building
    supported_release = [ 'precise','trusty','xenial','yakkety','zesty' ]
    prerequisite_packages = ['packaging-dev','python-pip']							# If you want to add more packages to be part of your prerequisite add like ['pkg1','pkg2']
    repo_file = "/etc/apt/sources.list"										# Default repo file for ubuntu
    template_repo_file = "FYI/sources.list"									# Update your src repo entries in case default data is not enough to build the packages
    chroot_path = "/var/cache/pbuilder"
    pbuilder_script_file = "/usr/lib/pbuilder/pbuilder-buildpackage"						# Do not change the file or else build is fail for all packages
    pbuilder_build_path = "/var/cache/pbuilder/build/*/build/*"



class rhel_conf:
    build_src_distribution = []                                         				 	 # for rhel or suse mentioned the distribution name or distribution version rhel7.4 for building
    supported_release = [ '7.1','7.2','7.3' ]

class suse_conf:
    build_src_distribution =  []                                      					         # for rhel or suse mentioned the distribution name or distribution version rhel7.4 for building
    supported_release = [ ]


class custom_conf:
    #build_tag = [ 'ALL' ]                                                      # for specific build tag mentioned like mcp8_1-ppc64le
    build_tag = [ '','' ]                            # for specific build tag mentioned like mcp8_1-ppc64le
    input_file = ""                                                             # This file will contain the packges to be build for autotest
    build_supporting_tags = ['','','','ALL']
    sleep_tag = "3600"                                                          # After instance will sleep for these many sec, you can modify based on your requirement
    num_of_build_per_cycle = "14"  
