#!/bin/bash
############################################################
# Author:  Helen Pang. hpang@us.ibm.com	    		   # 
# alias_mutt.sh	Set alias for local user's mailing address #
############################################################

echo " set alias for local user's mail address"

echo "alias m_1 mutt_1@localhost" >>/home/mutt_1/.muttrc
echo "alias m_2 mutt_2@localhost" >>/home/mutt_1/.muttrc

echo "We will run mutt as user mutt_1 to send mail to alias m_2 (who is mutt_2)."
echo "Please answer "y" to any questions about creating mail file."
echo "Press enter for the prompts about recipient and subject."
echo "Mutt will put you in the VI editor. Enter any test as the body of the"
echo "message then write and  quit vi (:wq). Next press "y" to send the mail."
echo -n "Press enter now to continue..."
read garbage
# switch user to mutt_1 and run the mail command.
su - mutt_1 -c "mutt -s wonder m_2"
echo "======================================================================="
echo "Please enter \"su - mutt_2\" and verify that the email was received and"
echo "then type \"exit\" to revert back to the root user."
