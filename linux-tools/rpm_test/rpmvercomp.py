#!/usr/bin/python
# Reads in package header, compares to installed package.
# Usage:
# python vercompare.py rpm_file.rpm

import rpm, os, sys

def readRpmHeader(ts, filename):
  """ Read an rpm header. """
  fd = os.open(filename, os.O_RDONLY)
  h = ts.hdrFromFdno(fd)
  os.close(fd)
  return h

ts = rpm.TransactionSet()
h = readRpmHeader( ts, sys.argv[1] )
pkg_ds = h.dsOfHeader()

for inst_h in ts.dbMatch('name', h['name']):
  inst_ds = inst_h.dsOfHeader()
  if pkg_ds.EVR() >= inst_ds.EVR():
    print "Package file is same or newer, OK to upgrade."
  else:
    print "Package file is older than installed version." 
