#!/usr/bin/env python
import pexpect, fdpexpect
import commands
import sys, os
import traceback

testdata = 'BEGIN\nHello world\nEND'
def test_run():
	print "test run"
	status = commands.getoutput('ls -l /bin')
	(status_with_pexpect, exitstatus) = pexpect.run ('ls -l /bin', withexitstatus=1)
	status_with_pexpect = status_with_pexpect.replace('\r','')[:-1]
	assert status == status_with_pexpect
	assert exitstatus == 0
	
	(data, exitstatus) = pexpect.run ('ls -l /najoeufhdnzkxjd', withexitstatus=1)
	assert exitstatus != 0

def test_dotexpression():
	print "dot all"
	p = pexpect.spawn('echo "%s"' % testdata)
	i = p.expect (['BEGIN(.*)END', pexpect.EOF])
	assert i==0, 'DOT is not working.'

def test_missing_command():
	print "missing"
	try:
		i = pexpect.spawn ('UNKNOWN')
	except Exception:
		pass
	else:
		print('Expected an Exception.')

def test_constr():
	print "contr"
	p1 = pexpect.spawn('/bin/ls -l /bin')
	p2 = pexpect.spawn('/bin/ls' ,['-l', '/bin'])
	p1.expect (pexpect.EOF)
	p2.expect (pexpect.EOF)
	assert (p1.before == p2.before)

def main():
	test_run()
	print "done tesst run"
	test_dotexpression()
	test_missing_command()
	test_constr()

if __name__ == "__main__":
    try:
        main()
    except Exception, e:
        print str(e)
	traceback.print_exc()
        os._exit(1)

