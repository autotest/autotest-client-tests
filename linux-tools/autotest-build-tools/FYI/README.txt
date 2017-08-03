#==========================================================================================================
##
##         FILE: README.txt
##
##  DESCRIPTION:  This File contains the steps of build and test autotest tests for all Linux Destro
##
##      OPTIONS:  ---
## REQUIREMENTS:  ---
##         BUGS:  ---
##        NOTES:  ---
##       AUTHOR:  IBM LTC Test Team
##      COMPANY:  IBM
##      VERSION:  1.0
##      CREATED:  16-Feb-2017 Abhishek Sharma < abhisshm@in.ibm.com >
##     REVISION:  22-Feb-2017 Abhishek Sharma < abhisshm@in.ibm.com >
##==========================================================================================================


Supported Linux Destro : Redhat,Ubuntu,suse,CentOS
        Supported Arch : Intel X86_64 and ia32
                         IBM Power (ppc,ppc64,ppc64le,ppcnf)
                         IBM Z box( s390x)

Below steps are automted in run.py script, for better understanding steps are written down.

1) Git clone the latest autotest and autotest-linux-tools
2) Based on the arguments build the required packages and copy to autotest-linux-tools
3) Run the Regression test.


NOTE : Before running the run.py script please verify modules/build_conf.py script
       This is a configuration file to execute run.py
       Before executing modify the data based on your requirement 
