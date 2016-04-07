#!/usr/bin/python

import rpm, sys, os;
def readRpmHeader(ts, filename):
  """ Read an rpm header. """
  fd = os.open(filename, os.O_RDONLY)
  h = None
  try:
    h = ts.hdrFromFdno(fd)
  except rpm.error, e:
    if str(e) == "public key not available":
      print str(e)
    if str(e) == "public key not trusted":
      print str(e)
    if str(e) == "error reading package header":
      print str(e)

  h = None
  os.close(fd)
  return h

ts = rpm.TransactionSet()
h = readRpmHeader( ts, sys.argv[1] ) 
