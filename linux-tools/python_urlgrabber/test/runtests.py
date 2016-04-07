#!/usr/bin/python

"""Usage: python runtests.py [OPTIONS]
Quick script to run all unit tests from source directory 
(e.g. without having to install.)

OPTIONS:
  
  -d, --descriptions=NUM Set to 0 to turn off printing 
                         test doc strings as descriptions.
  -v, --verbosity=NUM    Output verbosity level. Defaults to
                         2 which is one line of info per test. Set 
                         to 1 to get one char of info per test
                         or 0 to disable status output completely.
"""
  
# $Id: runtests.py,v 1.7 2004/03/31 17:02:00 mstenner Exp $

import sys
from os.path import dirname, join as joinpath
from getopt import getopt
from base_test_code import *

def main():
    # setup sys.path so that we can run this from the source
    # directory.
    (descriptions, verbosity) = parse_args()
    dn = dirname(sys.argv[0])
    sys.path.insert(0, joinpath(dn,'..'))
    sys.path.insert(0, dn)
    # it's okay to import now that sys.path is setup.
    import test_grabber, test_byterange, test_mirror
    suite = TestSuite( (test_grabber.suite(),
                        test_mirror.suite()) )
    suite.description = 'urlgrabber tests'
    runner = TextTestRunner(stream=sys.stdout,
                            descriptions=descriptions,
                            verbosity=verbosity)
    runner.run(suite)

def parse_args():
    descriptions = 1
    verbosity = 2
    opts, args = getopt(sys.argv[1:],'hd:v:',['descriptions=','help','verbosity='])
    for o,a in opts:
        if o in ('-h', '--help'):
            usage()
            sys.exit(0)
        elif o in ('-d', '--descriptions'):
            descriptions = int(a)
        elif o in ('-v', '--verbosity'):
            verbosity = int(a)
    return (descriptions,verbosity)
    
def usage():
    print __doc__
     
if __name__ == '__main__':
    main()
