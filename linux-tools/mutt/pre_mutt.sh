#!/bin/bash
#################################################
# Author:  	Helen Pang. hpang@us.ibm.com	#    
# pre-mutt.sh:	Settings for bringing up mutt	#
#################################################

clear

echo "Here are the settings to bring up mutt tool "

# create local users: mutt_1 and mutt_2
useradd -m mutt_1
useradd -m mutt_2

# copy the default system Muttrc file to local users's directories 
cp -f /etc/Muttrc /home/mutt_1/.muttrc
cp -f /etc/Muttrc /home/mutt_2/.muttrc

# create a file for user mutt_1
echo "Hello, this is my first mutt mail" >/home/mutt_1/myfile

# change ownership for local user's directories 
chown -R mutt_1.users /home/mutt_1/
chown -R mutt_2.users /home/mutt_2/

