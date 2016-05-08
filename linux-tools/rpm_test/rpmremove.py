#!/usr/bin/python
# Upgrades packages passed on the command line.
# Usage:
# python rpmupgrade.py rpm_file1.rpm rpm_file2.rpm ...

import rpm, os, sys

# Global file descriptor for the callback.

rpmtsCallback_fd = None

def runCallback(reason, amount, total, key, client_data):
  global rpmtsCallback_fd
  if reason == rpm.RPMCALLBACK_INST_OPEN_FILE:
    print "Opening file. ", reason, amount, total, key, client_data
    rpmtsCallback_fd = os.open(key, os.O_RDONLY)
    return rpmtsCallback_fd
  elif reason == rpm.RPMCALLBACK_INST_START:
    print "Closing file. ", reason, amount, total, key, client_data
    os.close(rpmtsCallback_fd)

def checkCallback(ts, TagN, N, EVR, Flags):
  if TagN == rpm.RPMTAG_REQUIRENAME:
    prev = ""
  h = None
  if N[0] == '/':
    dbitag = 'basenames'
  else:
    dbitag = 'providename'

  # What do you need to do.
  if EVR:
    print "Must find package [", N, "-", EVR, "]"
  else:
    print "Must find file [", N, "]"

  return 1

def readRpmHeader(ts, filename):
  """ Read an rpm header. """
  fd = os.open(filename, os.O_RDONLY)
  h = ts.hdrFromFdno(fd)
  os.close(fd)
  return h

#rpm.addMacro("_dbpath", "/tmp/rpm1")
ts = rpm.TransactionSet()

# Set to not verify DSA signatures.
ts.setVSFlags(-1)
ts.addErase(sys.argv[1])
unresolved_dependencies = ts.check(checkCallback)
if not unresolved_dependencies:
    ts.order()
    print "Running transaction (final step)..."
    ts.run(runCallback, 1)
else:
    print "Error: Unresolved dependencies, transaction failed."
    print unresolved_dependencies 

#rpm.delMacro("_dbpath")
