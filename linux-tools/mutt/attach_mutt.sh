#!/bin/bash
##############################################################
# Author:	  	Helen Pang. hpang@us.ibm.com	     #
# attach_mutt.sh:  	Attach a file to the mail sent	     #
##############################################################

echo "This will run mutt using mutt's attach mode."
echo "It will attach myfile to the mail sent from user mutt_1 to mutt_2 "
echo -n "set the mail subject as 'wonder', and using "
echo "alias address 'm_2' for user mutt_2's mailing address."
echo -n  "Press enter to continue..."
read garbage
su - mutt_1 -c "mutt -s wonder -a myfile -- m_2 </dev/null"
echo "=================================================================="
echo "Please enter \"su - mutt_2\" to verify that the email was received."
echo "In mutt, use the "v" command to see the attachment."

