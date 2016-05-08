#!/bin/bash
##################################################################
# Author:	  	Helen Pang. hpang@us.ibm.com	    	 #
# include_mutt.sh:  	Include a file as a part of the new mail #
##################################################################

echo "This will run mutt using mutt's include mode."
echo "It will include myfile as a part of new mail sent from user mutt_1 to mutt_2 "
echo -n "set the mail subject as 'wonder', and using "
echo "alias address 'm_2' for user mutt_2's mailing address. "
echo "Press enter to continue..."
read garbage
su - mutt_1 -c "mutt -s wonder -i myfile m_2"
echo "===================================================================="
echo "Please enter \"su - mutt_2\" and verify that the email was recieved."
