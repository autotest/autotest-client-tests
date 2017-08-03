#==========================================================================================================
#
#         FILE: run.py
#
#	Usage: python run.py 
#
#
#  DESCRIPTION:  Script to build/test autotest test packages and run regression
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  IBM LTC Test Team
#      COMPANY:  IBM
#      VERSION:  1.0
#      CREATED:  22-Feb-2017 Abhishek Sharma < abhisshm@in.ibm.com >
#     REVISION:  ---
#==========================================================================================================

#=========================================================
#  Importing python predefine and user defined modules
#=========================================================
import os,sys,getopt,os.path        # importing OS module for performing os related activity.
#if sys.version[0:3] == "2.7":
#    import subprocess

####################################################
# Import generic modules
####################################################
from modules.generic_module import *
from modules.build_conf import *

os.system('clear')
###############################################
# Import custom modules based on conf file
###############################################
ACTION = generic_conf.build_type
if ACTION == "CUSTOM":
   from modules.custom_module import *
elif ACTION == "REDHAT":
   from modules.rhel_module import *
elif ACTION == "SUSE":
   from modules.suse_module import *
elif ACTION == "UBUNTU":
   from modules.ubuntu_module import *
elif ACTION == "CENTOS":
   from modules.centos_module import *
else:
   print "build_type under modules/build_conf.py is either empty or not configured properly, please configure and rerun"


