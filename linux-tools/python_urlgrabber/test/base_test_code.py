from munittest import *

base_http = 'http://kjdev1.au.example.com/test/urlgrabber-test/' 
base_ftp  = 'ftp://localhost/test/'

# set to a proftp server only. we're working around a couple of
# bugs in their implementation in byterange.py.
base_proftp = 'ftp://localhost/test/'

reference_data = ''.join( [str(i)+'\n' for i in range(20000) ] )
ref_http = base_http + 'reference'
ref_ftp = base_ftp + 'reference'
ref_proftp = base_proftp + 'reference'
short_reference_data = ' '.join( [str(i) for i in range(10) ] )
short_ref_http = base_http + 'short_reference'
short_ref_ftp = base_ftp + 'short_reference'

ref_200 = ref_http
ref_404 = base_http + 'nonexistent_file'
ref_403 = base_http + 'mirror/broken/'

base_mirror_url    = base_http + 'mirror/'
good_mirrors       = ['m1', 'm2', 'm3']
mirror_files       = ['test1.txt', 'test2.txt']
bad_mirrors        = ['broken']
bad_mirror_files   = ['broken.txt']

proxy_proto = 'http'
proxy_host = 'localhost'
proxy_port = 8888
proxy_user = 'proxyuser'
good_proxy_pass = 'proxypass'
bad_proxy_pass = 'badproxypass'
