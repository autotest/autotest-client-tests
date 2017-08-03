#!/usr/bin/python
############################################################################################
#
# Description : This file will contain  <source> and <destination> of all test binaries
#
#	     <Source> : Once build is done, what need to copied.
#	<Destination> : Source need to be copied in a specfic autotest folder to test.
#
#############################################################################################		


#############################################################################################
# This class contain the packages name and what need to copied and where need to be copied   
#############################################################################################
class ubuntu_src_dest:
    libffi6 = {'TEST_SOURCE': ['testsuite'],'DESTINATION': ['']}
    libmnl0 = {'TEST_SOURCE': ['examples/genl/.libs','examples/netfilter/.libs','examples/rtnl/.libs/'],'DESTINATION': ['tests']}
    libnetfilter-conntrack3 = {'TEST_SOURCE': ['utils/.libs/'],'DESTINATION': ['utils']}
    parted = {'TEST_SOURCE': ['tests/.libs','tests','build-aux'],'DESTINATION': ['']}
