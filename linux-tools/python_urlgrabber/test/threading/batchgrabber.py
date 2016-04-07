#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2.1 of the License, or (at your option) any later version.
#
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public
#   License along with this library; if not, write to the 
#      Free Software Foundation, Inc., 
#      59 Temple Place, Suite 330, 
#      Boston, MA  02111-1307  USA

# This file is part of urlgrabber, a high-level cross-protocol url-grabber
# Copyright 2002-2004 Michael D. Stenner, Ryan Tomayko

"""Module for testing urlgrabber under multiple threads.

This module can be used from the command line. Each argument is 
a URL to grab.

The BatchURLGrabber class has an interface similar to URLGrabber 
but instead of pulling files when urlgrab is called, the request
is queued. Calling BatchURLGrabber.batchgrab causes all files to
be pulled in multiple threads.

"""

import os.path, sys
if __name__ == '__main__':
  print os.path.dirname(sys.argv[0])
  sys.path.insert(0, (os.path.dirname(sys.argv[0]) or '.') + '/../..')

from threading import Thread, Semaphore
from urlgrabber.grabber import URLGrabber, URLGrabError
from urlgrabber.progress import MultiFileMeter, TextMultiFileMeter
from time import sleep, time

DEBUG=0

class BatchURLGrabber:
  def __init__(self, maxthreads=5, **kwargs):
    self.maxthreads = 5
    self.grabber = URLGrabber(**kwargs)
    self.queue = []
    self.threads = []
    self.sem = Semaphore()
    
  def urlgrab(self, url, filename=None, **kwargs):
    self.queue.append( (url, filename, kwargs) )
  
  def batchgrab(self):
    if hasattr(self.grabber.opts.progress_obj, 'start'):
        self.grabber.opts.progress_obj.start(len(self.queue))
    while self.queue or self.threads:
      if self.queue and (len(self.threads) < self.maxthreads):
        url, filename, kwargs = self.queue[0]
        del self.queue[0]
        thread = Worker(self, url, filename, kwargs)
        self.threads.append(thread)
        if DEBUG: print "starting worker: " + url
        thread.start()
      else:
        for t in self.threads:
          if not t.isAlive():
            if DEBUG: print "cleaning up worker: " + t.url
            self.threads.remove(t)
        #if len(self.threads) == self.maxthreads:
        #  sleep(0.2)
        sleep(0.2)
        
class Worker(Thread):
  def __init__(self, parent, url, filename, kwargs):
    Thread.__init__(self)
    self.parent = parent
    self.url = url
    self.filename = filename
    self.kwargs = kwargs
  
  def run(self):
    if DEBUG: print "worker thread started."
    grabber = self.parent.grabber
    progress_obj = grabber.opts.progress_obj
    if isinstance(progress_obj, MultiFileMeter):
      self.kwargs['progress_obj'] = progress_obj.newMeter()
    try:
      rslt = self.parent.grabber.urlgrab(self.url, self.filename, **self.kwargs)
    except URLGrabError, e:
      print '%s, %s' % (e, self.url)
      
def main():
  progress_obj = None
  # uncomment to play with BatchProgressMeter (doesn't work right now)
  # progress_obj = TextMultiFileMeter()
  g = BatchURLGrabber(keepalive=1, progress_obj=progress_obj)
  for arg in sys.argv[1:]:
    g.urlgrab(arg)
  if DEBUG: print "before batchgrab"
  try:
    g.batchgrab()
  except KeyboardInterrupt:
    sys.exit(1)
    
  if DEBUG: print "after batchgrab"
  
if __name__ == '__main__':
  main()
