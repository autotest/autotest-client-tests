#!/usr/bin/python -t

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

import sys
import os
from os.path import dirname, join as joinpath
import tempfile
import time

import urlgrabber.grabber as grabber
from urlgrabber.grabber import URLGrabber, urlgrab, urlopen, urlread
from urlgrabber.progress import text_progress_meter

tempsrc = '/tmp/ug-test-src'
tempdst = '/tmp/ug-test-dst'

# this isn't used but forces a proxy handler to be
# added when creating the urllib2 opener.
proxies = { 'http' : 'http://localhost' }
DEBUG=0

def main():
    speedtest(1024)         # 1KB
    speedtest(10 * 1024)    # 10 KB
    speedtest(100 * 1024)   # 100 KB
    speedtest(1000 * 1024)  # 1,000 KB (almost 1MB)
    #speedtest(10000 * 1024) # 10,000 KB (almost 10MB)
    # remove temp files
    os.unlink(tempsrc)
    os.unlink(tempdst)
    
def setuptemp(size):
    if DEBUG: print 'writing %d KB to temporary file (%s).' % (size / 1024, tempsrc)
    file = open(tempsrc, 'w', 1024)
    chars = '0123456789'
    for i in range(size):
        file.write(chars[i % 10])
    file.flush()
    file.close()
    
def speedtest(size):
    setuptemp(size)
    full_times = []
    raw_times = []
    none_times = []
    throttle = 2**40 # throttle to 1 TB/s   :)

    try:
        from urlgrabber.progress import text_progress_meter
    except ImportError, e:
        tpm = None
        print 'not using progress meter'
    else:
        tpm = text_progress_meter(fo=open('/dev/null', 'w'))
        
    # to address concerns that the overhead from the progress meter
    # and throttling slow things down, we do this little test.
    #
    # using this test, you get the FULL overhead of the progress
    # meter and throttling, without the benefit: the meter is directed
    # to /dev/null and the throttle bandwidth is set EXTREMELY high.
    #
    # note: it _is_ even slower to direct the progress meter to a real
    # tty or file, but I'm just interested in the overhead from _this_
    # module.
    
    # get it nicely cached before we start comparing
    if DEBUG: print 'pre-caching'
    for i in range(100):
        urlgrab(tempsrc, tempdst, copy_local=1, throttle=None, proxies=proxies)
    
    if DEBUG: print 'running speed test.'
    reps = 500
    for i in range(reps):
        if DEBUG: 
            print '\r%4i/%-4i' % (i+1, reps),
            sys.stdout.flush()
        t = time.time()
        urlgrab(tempsrc, tempdst,
                copy_local=1, progress_obj=tpm,
                throttle=throttle, proxies=proxies)
        full_times.append(1000 * (time.time() - t))

        t = time.time()
        urlgrab(tempsrc, tempdst,
                copy_local=1, progress_obj=None,
                throttle=None, proxies=proxies)
        raw_times.append(1000 * (time.time() - t))

        t = time.time()
        in_fo = open(tempsrc)
        out_fo = open(tempdst, 'wb')
        while 1:
            s = in_fo.read(1024 * 8)
            if not s: break
            out_fo.write(s)
        in_fo.close()
        out_fo.close()
        none_times.append(1000 * (time.time() - t))

    if DEBUG: print '\r'

    print "%d KB Results:" % (size / 1024)
    print_result('full', full_times)
    print_result('raw', raw_times)
    print_result('none', none_times)

def print_result(label, result_list):
    format = '[%4s] mean: %6.3f ms, median: %6.3f ms, ' \
             'min: %6.3f ms, max: %6.3f ms'
    result_list.sort()
    mean = 0.0
    for i in result_list: mean += i
    mean = mean/len(result_list)
    median = result_list[int(len(result_list)/2)]
    print format % (label, mean, median, result_list[0], result_list[-1])

if __name__ == '__main__':
    main()
