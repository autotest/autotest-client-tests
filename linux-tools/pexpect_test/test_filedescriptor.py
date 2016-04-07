#!/usr/bin/env python
import fdpexpect, pexpect, traceback 
import sys
import os
TEST_DIR = os.environ['TSTDIR']
file = TEST_DIR+"/"+"TESTDATA.txt"
def test_fd ():
	fd = os.open (file, os.O_RDONLY)
	s = fdpexpect.fdspawn (fd)
	s.expect ('This is the end of test data:')
	s.expect (pexpect.EOF)
	assert s.before == ' END\n'

def test_maxread ():
	fd = os.open (file, os.O_RDONLY)
	s = fdpexpect.fdspawn (fd)
	s.maxread = 100
	s.expect('2')
	s.expect ('This is the end of test data:')
	s.expect (pexpect.EOF)
	assert s.before == ' END\n'
  
def test_fd_isalive ():
	fd = os.open (file, os.O_RDONLY)
	s = fdpexpect.fdspawn (fd)
	assert s.isalive()
	os.close (fd)
	assert not s.isalive(), "Should not be alive after close()"

def test_fd_isatty ():
	fd = os.open (file, os.O_RDONLY)
	s = fdpexpect.fdspawn (fd)
	assert not s.isatty()
	s.close()

def main():
	test_fd()
	test_maxread()
	test_fd_isalive()
	test_fd_isatty()

if __name__ == '__main__':

	try:
		main()
	except Exception, e:
		print str(e)
		traceback.print_exc()
		os._exit(1)
