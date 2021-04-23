#!/usr/bin/python

##############################
# Import global modules
##############################
import os,sys,logging


##################################
# Import local modules
##################################
from build_conf import *
from generic_module import *

#######################################################################
# Initializing the  Global and local variable used in this modules
#######################################################################
SRC_DIST = ubuntu_conf.build_src_distribution
BASEDIR = generic_conf.basedir
LOGDIR = generic_conf.logdir
REPO_FILE = ubuntu_conf.repo_file
PBUILD_SCRIPT = ubuntu_conf.pbuilder_script_file
PBUILD_BUILD_PATH = ubuntu_conf.pbuilder_build_path
NOTIFICATION_ACTION = generic_conf.sms_notofication
MOBILE_NUM = generic_conf.mobile_number
repo_return_code = os.system("ls -ld %s >/dev/null 2>&1" %REPO_FILE)
if repo_return_code != 0:
    print col.red + "\nERROR:  REPO File %s is missing, please check and rerun\n" %REPO_FILE + col.norm
    sys.exit(0)



TEMPLATE_REPO_FILE = ubuntu_conf.template_repo_file
repo_return = os.system("ls -ld %s >/dev/null 2>&1" %TEMPLATE_REPO_FILE)
if repo_return != 0:
    print col.red + "\nERROR:  TEMPLATE REPO File %s is missing, please check and rerun\n" %TEMPLATE_REPO_FILE + col.norm
    sys.exit(0)



BINARY_LOCATION = generic_conf.binary_src_dir
return_code = os.system("ls -ld %s >/dev/null 2>&1" %LOGDIR)
if return_code != 0:
    create_status = os.system("mkdir -p %s >/dev/null 2>&1 " %LOGDIR)
    if create_status != 0:
        print col.red + "\nERROR:  Failed while creating directory %s\n" %LOGDIR + col.norm
        sys.exit(0)

LOGFILE = generic_conf.logfile
logging.basicConfig(filename=LOGFILE,format='%(asctime)s -   [ %(levelname)s ] - %(message)s',level=logging.DEBUG)
PACKAGE_LIST= generic_conf.package_list_file
PREREQUISITE_LIST = ubuntu_conf.prerequisite_packages
SUPPORTED_DIST = ubuntu_conf.supported_release
if PACKAGE_LIST == "":
    display_message_fn("package_list_file variable is epmty, please provide a valid input file","ERROR")
    sys.exit(0)


L_HOSTNAME = os.popen("hostname").read()
for l_name in SRC_DIST:
    input_build_name = l_name


CHROOT_PATH = ubuntu_conf.chroot_path

#############################################
# Check given input is exits or not
#############################################
return_status = os.system("cat %s >/dev/null 2>&1"%PACKAGE_LIST)
if return_status != 0:
    display_message_fn("Given input file %s is not exits, please check your build_conf file and rerun"%PACKAGE_LIST,"ERROR")
    sys.exit(0)

os.system("sudo cp -r %s %s_bkp"%(PBUILD_SCRIPT,PBUILD_SCRIPT))
TOTAL_COUNT = os.popen("cat %s 2>/dev/null |wc -l"%PACKAGE_LIST).read()
SUCCESS_COUNT = 0
FAILED_COUNT = 0
SKIPPED_COUNT = 0
######################################################
# Module to check given release is supported or not
######################################################
def verify_distro_release_fn():
    for input_tag in SRC_DIST:
        if input_tag in SUPPORTED_DIST:  
	    continue
	else:
            display_message_fn("This %s tag is currently Supported" %input_tag,"ERROR")
            sys.exit(0)


#############################################
# Check current destro
#############################################
def check_local_distro_release_fn(args):
    if args == "name":
        output = os.popen("awk  -F\"=\" '$1~/DISTRIB_CODENAME/ {print $2}'  /etc/*-release").read()
    elif args == "version":
        output = os.popen("awk  -F\"=\" '$1~/DISTRIB_RELEASE/ {print $2}'  /etc/*-release").read()

    return output.strip()


####################################################
# Module to build package for same distro
####################################################
def same_distro_build_fn(args):
    local_package_name = args
    RC = os.system("grep \"^deb-src\" %s"%REPO_FILE)
    if RC != 0:
        display_message_fn("please enable deb-src in %s file, and update the repo"%REPO_FILE,"ERROR")
        sys.exit(0)

    display_message_fn("Building package for %s , this might take few minutes..." %local_package_name,"INFO")
    download_status = os.system("sudo apt-get build-dep %s -y >/dev/null 2>&1"%local_package_name)
    if download_status != 0:
        return 1

    compile_status = os.system("sudo apt-get source --compile %s >/dev/null 2>&1 "%local_package_name)
    if compile_status != 0:
        return 1


    return 0


    

#########################################################
# Modify repo based on the required distribution version
#########################################################
def update_source_list_fn(arg1):
    l_distro_type = arg1
    display_message_fn("Updating %s entries on %s file"%(l_distro_type,REPO_FILE),"INFO")
    copy_status = os.system("sudo cp %s %s_bkp "%(REPO_FILE,REPO_FILE))
    if copy_status != 0:
        display_message_fn("Failed wahile taking the backup of %s file"%REPO_FILE,"ERROR")
        sys.exit(0)
    
    
    template_status = os.system("sudo cp %s %s"%(TEMPLATE_REPO_FILE,REPO_FILE))
    if template_status != 0:
        display_message_fn("Failed while uploading the tempate file %s "%TEMPLATE_REPO_FILE,"ERROR")
        sys.exit(0)

    os.system("sudo sed -i 's/CHANGE_ME/%s/g' %s"%(l_distro_type,REPO_FILE))
    display_message_fn("Updating latest repo changes \( sudo apt-get update \) ,this might take few minures","INFO")
    update_status = os.system("sudo apt-get update >/dev/null 2>&1")
    if update_status != 0:
        display_message_fn("Failed while uploading the apt-get repo, please check manualy and rerun the script","ERROR")
	sys.exit(0)









#########################################################################
# Module to revert back all the system changes one the task is finished
#########################################################################
def revert_back_changes_fn():
    display_message_fn("Reverting back all the changes ","INFO")
    os.system("sudo cp %s_bkp %s "%(REPO_FILE,REPO_FILE))
    display_message_fn("Updating old repo changes \( sudo apt-get update \) ,this might take few minures","INFO")
    value = os.system("sudo apt-get update >/dev/null 2>&1")
    if value == 0:
        display_message_fn("Successfully  uploaded the old apt-get repo ","OK")





#################################################
# Module to create chroot env for ubuntu
#################################################
def make_chroot_fn():
    display_message_fn("Creating chroot env for %s , this might take few minutes" %input_build_name,"INFO")
    ls_status = os.system("ls -l %s >/dev/null 2>&1"%CHROOT_FILE)
    if ls_status == 0:
        display_message_fn("Chroot %s is already exits , skipping...."%CHROOT_FILE,"SKIPPED")
    else:
        create_status = os.system("pbuilder-dist %s create --basetgz %s >/dev/null 2>&1" %(input_build_name,CHROOT_FILE))
        if create_status == 0:
            display_message_fn("Successfully created chroot for %s distribution"%input_build_name,"OK")
	else:
	    display_message_fn("Failed while creating the  chroot environment for %s distribution, please check and rerun the script"%input_build_name,"ERROR")
	    sys.exit(0)




####################################################
# Module to build package for different distro
####################################################
def diff_distro_build_fn(arg1):
    l_pkg = arg1
    display_message_fn("Building package for %s , this might take few minutes..." %l_pkg,"INFO")
    skip_output = os.system("ls -ld %s >/dev/null 2>&1"%INPUT_DIR)
    if skip_output == 0:
        return 3
    else:
	os.system("mkdir -p %s"%TEMP_DIR)

    os.chdir(TEMP_DIR)
    download_src = os.system("apt-get source %s >/dev/null 2>&1"%l_pkg)
    if download_src != 0:
	os.chdir(CURRENT_DIR)		
        return 2

    os.chdir(TEMP_DIR)
    build_status = os.system("sudo pbuilder --build --distribution %s --basetgz %s *.dsc >/dev/null 2>&1"%(input_build_name,CHROOT_FILE))
    if build_status != 0:
	os.chdir(CURRENT_DIR)
        return 1

    return 0



#####################################################
# Install package module
#####################################################
def install_package_fn(args):
    l_name = args
    status = os.system("sudo apt-get install -y %s >/dev/null 2>&1" %l_name)
    if status == 0:
        return 0
    else:
        return 1
    




###########################################
# Clean function
###########################################
def clean_fn():
    os.system("sudo rm -rf *.deb *.xz *.bz2 *.dsc *.changes *.gz *.udeb /var/cache/pbuilder/result/ >/dev/null 2>&1")




#####################################################
# Function to check prerequisite
#####################################################
def check_prerequisite_fn():
    for list in PREREQUISITE_LIST:
        status = os.system("dpkg --list|grep %s >/dev/null 2>&1" %list)
        if status != 0:
            display_message_fn("Package %s is not installed, installing it.. please wait." %list,"WARN")
            command_check = install_package_fn(list)
            if command_check == 0:
                print "Successfully installed package %s " %list
	    else:
		display_message_fn("Failed while installing package %s , please check and rerun the script" %list,"ERROR")
		sys.exit(0)
        else:
	    display_message_fn("Package  %s is already installed" %list,"OK")


CHROOT_FILE = "%s/%s-base.tgz" %(CHROOT_PATH,input_build_name)
CURRENT_DIR = os.popen("pwd").read().strip()
verify_distro_release_fn()
local_name = check_local_distro_release_fn("name")
local_version = check_local_distro_release_fn("version")
check_prerequisite_fn()
install_python_module_fn()
if local_name in SRC_DIST:
    with open(PACKAGE_LIST) as f:
        for line in f:
	    line = line.strip()
	    INPUT_DIR = "%s/%s/%s" %(BINARY_LOCATION,local_name,line)
            skip_output = os.system("ls -ld %s >/dev/null 2>&1"%INPUT_DIR)
            if skip_output == 0:
		display_message_fn("Binaries are already available for package %s"%line, "SKIPPED")
		SKIPPED_COUNT = SKIPPED_COUNT + 1
		continue


            os.system("mkdir -p %s"%INPUT_DIR)
            os.chdir(INPUT_DIR)
            VALUE = same_distro_build_fn(line)
	    if VALUE == 0:
	        display_message_fn("Successfully compilied the binary for %s package"%line,"OK")
		clean_fn()
		os.chdir(CURRENT_DIR)
		SUCCESS_COUNT = SUCCESS_COUNT + 1
	    else:
		display_message_fn("Failed while building the binary for %s package"%line,"ERROR")
		clean_fn()
                os.chdir(CURRENT_DIR)
                FAILED_COUNT = FAILED_COUNT + 1

else:
    #update_source_list_fn(input_build_name)
    make_chroot_fn()
    with open(PACKAGE_LIST) as f:
        for line in f:
	    line = line.strip()
    	    INPUT_DIR = "%s/%s/%s" %(BINARY_LOCATION,input_build_name,line)
    	    TEMP_DIR = "%s/%s/%s/temp" %(BINARY_LOCATION,input_build_name,line)
	    check_retuen_code = os.system("sudo sed -i \"/# final cleanup/ccp -r %s %s\n# final cleanup\" %s"%(PBUILD_BUILD_PATH,INPUT_DIR,PBUILD_SCRIPT))
            if check_retuen_code != 0:
                display_message_fn("Failed while modifying the copy changes to %s file"%PBUILD_SCRIPT,"ERROR")
                sys.exit(0)

	    return_code =  diff_distro_build_fn(line)
            if return_code == 3:
	        display_message_fn("Binaries are already available for package %s"%line, "SKIPPED")
                SKIPPED_COUNT = SKIPPED_COUNT + 1
		os.system("sudo cp -r %s_bkp %s"%(PBUILD_SCRIPT,PBUILD_SCRIPT))
                continue


  	    if return_code == 2:
		display_message_fn("Failed while downloading the source file for %s package"%line,"ERROR")
		FAILED_COUNT = FAILED_COUNT + 1
		os.chdir(INPUT_DIR)
		clean_fn()
		os.system("rm -rf %s"%TEMP_DIR)
		os.chdir(CURRENT_DIR)
	    elif return_code == 1:
		display_message_fn("Failed while building the binary for %s package"%line,"ERROR")
                FAILED_COUNT = FAILED_COUNT + 1
		os.chdir(INPUT_DIR)
		os.system("rm -rf %s"%TEMP_DIR)
		clean_fn()
		os.chdir(CURRENT_DIR)
	    elif return_code == 0:
		display_message_fn("Successfully build the binary for %s package"%line,"OK")
                SUCCESS_COUNT = SUCCESS_COUNT + 1
		os.chdir(INPUT_DIR)
		clean_fn()
		os.system("rm -rf %s"%TEMP_DIR)
		os.chdir(CURRENT_DIR)
	
	    os.system("sudo cp -r %s_bkp %s"%(PBUILD_SCRIPT,PBUILD_SCRIPT))

    #revert_back_changes_fn()
footer_fn(L_HOSTNAME,local_name,local_version,input_build_name,BASEDIR,LOGDIR,LOGFILE,BINARY_LOCATION,TOTAL_COUNT,SUCCESS_COUNT,SKIPPED_COUNT,FAILED_COUNT)
if NOTIFICATION_ACTION == "y":
    send_sms_fn(MOBILE_NUM,"Build activity on Ubuntu : Out of Total %s :  SUCCESS = %s , SKIPPED = %s , FAILED = %s"%(TOTAL_COUNT,SUCCESS_COUNT,SKIPPED_COUNT,FAILED_COUNT))
