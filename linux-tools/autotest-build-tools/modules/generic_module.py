#!/usr/bin/python
import os,sys,logging
from build_conf import *
#############################################
# Create a class for define colors
#############################################
class col:
  red = '\033[1;91m'
  blue = '\033[1;94m'
  bold = '\033[1m'
  under_line = '\033[1;4m'
  yellow = '\033[1;93m'
  norm = '\033[0m'
  green = '\033[1;92m'
  cyan = '\033[1;36m'



###################################################
# Function to display the logs file information
###################################################
def footer_fn(arg1,arg2,arg3,arg4,basedir,logdir,logfile,binary_path,total_count,success_count,skipped_count,failed_count):
    l_hostname = arg1
    l_dist_name = arg2
    l_dist_ver = arg3
    l_build_req = arg4
    local_basedir = basedir
    local_logdir = logdir
    local_logfile = logfile
    l_total = total_count
    l_success = success_count
    l_skipped = skipped_count
    l_failed = failed_count
    l_binary_path = binary_path
     
    print """



                        ======================================================================================
					A U T O T E S T     B I N A R Y    B U I L D    T O O L

			HOSTNAME : %s
                        CURRENT DISTRIBUTION NAME : %s
                        CURRENT DISTRIBUTION VERSION : %s
                        BUILD REQUESTED FOR : %s



                        BASEDIR : %s
                        LOGDIR : %s
                        LOGFILE : %s
                        TEST BINARIES : %s


			TOTAL PACKAGE TO BE BUILD : %s
                                    SUCCESS BUILD : %s
                                    SKIPPED BUILD : %s
                                    FAILED BUILD  : %s


                        =======================================================================================


""" %(l_hostname,l_dist_name,l_dist_ver,l_build_req,local_basedir,local_logdir,local_logfile,l_binary_path,l_total,l_success,l_skipped,l_failed)


#####################################################
# Function to display header of script
#####################################################
def header_fn(arg1,arg2,arg3,arg4):
    l_hostname = arg1
    l_dist_name = arg2
    l_dist_ver = arg3
    l_build_req = arg4
    print """


				==============================================================================================
						A U T O T E S T     B I N A R Y    B U I L D    T O O L
				
				H O S T N A M E : %s
				C U R R E N T   D I S T R I B U T I O N   N A M E : %s
				C U R R E N T   D I S T R I B U T I O N   V E R S I O N : %s
				B U I L D   R E Q U E S T : %s



				===============================================================================================


"""%(l_hostname,l_dist_name,l_dist_ver,l_build_req)



def display_message_fn(arg1,arg2):
    TEXT= arg1
    MSG= arg2
    cmd  = "echo %s | awk -v msg=\"%s\" '{printf(\"%%5s %%-100s %%10s\",\"\",$0,\"[ \"msg\" ]\")}'" %(TEXT,MSG)
    data_to_display = os.popen(cmd).read()
    if MSG == "ERROR":
        print col.red + data_to_display + col.norm
        logging.error(TEXT)
    elif MSG == "OK":
        print col.green + data_to_display + col.norm
	logging.info(TEXT)
    elif MSG == "INFO":
        print col.bold + data_to_display + col.norm
	logging.info(TEXT)
    elif MSG == "WARN":
        print col.cyan + data_to_display + col.norm
	logging.warning(TEXT)
    elif MSG == "SKIPPED":
        print col.cyan + data_to_display + col.norm
        logging.info(TEXT)
    else:
        print  data_to_display



def install_python_module_fn():
    LISTS = generic_conf.python_modules
    for list in LISTS:
        status = os.system("python -c \"import %s\" >/dev/null 2>&1" %list)
        if status != 0:
            display_message_fn("Python module %s is not installed, installing it.. please wait." %list,"WARN")
            command_check = os.system("sudo pip install %s >/dev/null 2>&1"%list)
            if command_check == 0:
                display_message_fn("Successfully installed module %s " %list,"OK")
            else:
                display_message_fn("Failed while installing module %s , please check and rerun the script" %list,"ERROR")
                sys.exit(0)
        else:
            display_message_fn("Python module  %s is already installed" %list,"OK")


def send_sms_fn(num,text):
    value = os.system("dpkg --list|grep google-chrome >/dev/null 2>&1")
    if value != 0:
        display_message_fn("To run this sms feature you should install google chrome","INFO")
        sys.exit(0)


    from selenium import webdriver
    from selenium.webdriver.common.keys import Keys
    import time
    from pyvirtualdisplay import Display
    display = Display(visible=0, size=(800, 800))
    display.start()
    number_l = num
    message_l = text
    chrome_path = "FYI/chromedriver"
    driver = webdriver.Chrome(chrome_path)
    driver.get("http://site24.way2sms.com/content/index.html")
    driver.find_element_by_xpath("""//*[@id="username"]""").send_keys("8147894264")
    driver.find_element_by_xpath("""//*[@id="password"]""").send_keys("Letmein")
    driver.find_element_by_id("loginBTN").click()
    driver.find_element_by_css_selector(".button.br3").click()
    driver.find_element_by_id("sendSMS").click()
    frame = driver.find_element_by_xpath('//*[@id="frame"]')
    driver.switch_to.frame(frame)
    driver.find_element_by_id("mobile").send_keys(number_l)
    driver.find_element_by_id("message").send_keys(message_l)
    driver.find_element_by_id("Send").click()
