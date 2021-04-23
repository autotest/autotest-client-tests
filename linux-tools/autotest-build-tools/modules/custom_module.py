#!/usr/bin/python
import os,sys,logging,time


# Import custom modules
from build_conf import *
from generic_module import *

####################################################
# Capture all variables based on build conf file
####################################################
SLEEP_TAG = custom_conf.sleep_tag		
BUILD_NUMS = custom_conf.num_of_build_per_cycle			
BASEDIR = generic_conf.basedir
LOGDIR = generic_conf.logdir 
return_code = os.system("ls -ld %s >/dev/null 2>&1" %LOGDIR)
if return_code != 0:
    create_status = os.system("mkdir -p %s >/dev/null 2>&1 " %LOGDIR)
    if create_status != 0:
        print col.red + "\nERROR:  Failed while creating directory %s\n" %LOGDIR + col.norm
	sys.exit(0)
    

LOGFILE = generic_conf.logfile
logging.basicConfig(filename=LOGFILE,format='%(asctime)s -   [ %(levelname)s ] - %(message)s',level=logging.DEBUG)

try:
    LOCAL_BUILD_TAG = custom_conf.build_tag
except:
    display_message_fn("Seems like build_tag is commented or deleted in conf file","ERROR")
    footer_fn(BASEDIR,LOGDIR,LOGFILE)
    sys.exit(0)

try:
    BUILD_SUPPORTED_TAG = custom_conf.build_supporting_tags
except:
    display_message_fn("Seems like build_supporting_tags is commented or deleted in conf file","ERROR")
    footer_fn(BASEDIR,LOGDIR,LOGFILE)
    sys.exit(0)






####################################################
# Function to verify given input is valid or not
####################################################
def varify_build_fn():
    for input_tags in LOCAL_BUILD_TAG:
        if input_tags in BUILD_SUPPORTED_TAG:
	    continue
	else:
	    display_message_fn("Given input tag \"%s\" is not supported right now" %input_tags,"ERROR")
	    footer_fn(BASEDIR,LOGDIR,LOGFILE)
	    sys.exit(0)



##########################################################
# Funtion to setup required environment
##########################################################

varify_build_fn()
footer_fn(BASEDIR,LOGDIR,LOGFILE)
