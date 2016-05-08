#!/bin/bash
##############################################################
# Author:	  	Helen Pang. hpang@us.ibm.com	     #
# batch_mutt.sh:  	Send the prepared mail		     #
##############################################################

echo "This will run mutt using mutt's batch mode "
echo "It will send a prepared mail 'myfile' from user mutt_1 to user mutt_2, "
echo -n "set the mail subject as 'wonder', and using "
echo -n "alias address 'm_2' for user mutt_2. "
echo ""
echo -n "Press enter to continue..."
read garbage
su - mutt_1 -c "mutt -s wonder m_2 < myfile"
echo "========================================================"
echo "Please enter \"su - mutt_2\" and verify that the email was received."
