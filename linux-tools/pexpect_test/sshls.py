#!/usr/bin/env python

"""This runs 'ls -l' on a remote host using SSH. At the prompts enter hostname,
user, and password.

Example:
	.sshls.py -s www.example.com -u mylogin -p mypassword

$Id: sshls.py 489 2007-11-28 23:40:34Z noah $
"""
import traceback
import pexpect
import getopt, os, sys

def ssh_command (user, host, password, command):

    """This runs a command on the remote host. This could also be done with the
pxssh class, but this demonstrates what that class does at a simpler level.
This returns a pexpect.spawn object. This handles the case when you try to
connect to a new host and ssh asks you if you want to accept the public key
fingerprint and continue connecting. """

    ssh_newkey = 'Are you sure you want to continue connecting'
    child = pexpect.spawn('ssh -l %s %s %s'%(user, host, command))
    i = child.expect([pexpect.TIMEOUT, ssh_newkey, 'password: '])
    if i == 0: # Timeout
        print 'ERROR!'
        print 'SSH could not login. Here is what SSH said:'
        print child.before, child.after
        return None
    if i == 1: # SSH does not have the public key. Just accept it.
        child.sendline ('yes')
        i = child.expect([pexpect.TIMEOUT, 'password: '])
        if i == 0: # Timeout
            print 'ERROR!'
            print 'SSH could not login. Here is what SSH said:'
            print child.before, child.after
            return None       
    child.sendline(password)
    return child

def exit_with_usage():

    print globals()['__doc__']
    os._exit(1)

def main ():

    ######################################################################
    ## Parse the options, arguments, get ready, etc.
    ######################################################################
    try:
        optlist, args = getopt.getopt(sys.argv[1:], 'h?s:u:p:', ['help','h','?'])
    except Exception, e:
        print str(e)
        exit_with_usage()
    options = dict(optlist)
    if len(args) > 1:
        exit_with_usage()

    if [elem for elem in options if elem in ['-h','--h','-?','--?','--help']]:
        print "Help:"
        exit_with_usage()

    if '-s' in options:
        hostname = options['-s']
    if '-u' in options:
        username = options['-u']
    if '-p' in options:
        password = options['-p']

    child = ssh_command (username, hostname, password, '/bin/ls -l')
    child.expect(pexpect.EOF)
    child.sendline('logout')
    child.close()
    print child.before

if __name__ == '__main__':
    try:
        main()
    except Exception, e:
        print str(e)
        traceback.print_exc()
        os._exit(1)

