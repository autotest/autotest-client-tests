#!/usr/bin/perl -w

use strict;
use Test::More;

require_ok('File::Spec');

require Cwd;

my $vms_unix_rpt;

if ($^O eq 'VMS') {
    if (eval 'require VMS::Feature') {
        $vms_unix_rpt = VMS::Feature::current("filename_unix_report");
    } else {
        my $unix_rpt = $ENV{'DECC$FILENAME_UNIX_REPORT'} || '';
        $vms_unix_rpt = $unix_rpt =~ /^[ET1]/i; 
    }
}


my $skip_exception = "Needs VMS::Filespec (and thus VMS)" ;

eval {
   require VMS::Filespec ;
} ;

if ( $@ ) {
   # Not pretty, but it allows testing of things not implemented solely
   # on VMS.  It might be better to change File::Spec::VMS to do this,
   # making it more usable when running on (say) Unix but working with
   # VMS paths.
   eval qq-
      sub File::Spec::VMS::vmsify  { die "$skip_exception" }
      sub File::Spec::VMS::unixify { die "$skip_exception" }
      sub File::Spec::VMS::vmspath { die "$skip_exception" }
   - ;
   $INC{"VMS/Filespec.pm"} = 1 ;
}

foreach (qw(Unix Win32 OS2 Mac Epoc Cygwin)) {
    require_ok("File::Spec::$_");
}

# Each element in this array is a single test. Storing them this way makes
# maintenance easy, and should be OK since perl should be pretty functional
# before these tests are run.

my @tests = (
# [ Function          ,            Expected          ,         Platform ]

[ "Unix->case_tolerant()",         '0'  ],

[ "Unix->catfile('a','b','c')",         'a/b/c'  ],
[ "Unix->catfile('a','b','./c')",       'a/b/c'  ],
[ "Unix->catfile('./a','b','c')",       'a/b/c'  ],
[ "Unix->catfile('c')",                 'c' ],
[ "Unix->catfile('./c')",               'c' ],

[ "Unix->splitpath('file')",            ',,file'            ],
[ "Unix->splitpath('/d1/d2/d3/')",      ',/d1/d2/d3/,'      ],
[ "Unix->splitpath('d1/d2/d3/')",       ',d1/d2/d3/,'       ],
[ "Unix->splitpath('/d1/d2/d3/.')",     ',/d1/d2/d3/.,'     ],
[ "Unix->splitpath('/d1/d2/d3/..')",    ',/d1/d2/d3/..,'    ],
[ "Unix->splitpath('/d1/d2/d3/.file')", ',/d1/d2/d3/,.file' ],
[ "Unix->splitpath('d1/d2/d3/file')",   ',d1/d2/d3/,file'   ],
[ "Unix->splitpath('/../../d1/')",      ',/../../d1/,'      ],
[ "Unix->splitpath('/././d1/')",        ',/././d1/,'        ],

[ "Unix->catpath('','','file')",            'file'            ],
[ "Unix->catpath('','/d1/d2/d3/','')",      '/d1/d2/d3/'      ],
[ "Unix->catpath('','d1/d2/d3/','')",       'd1/d2/d3/'       ],
[ "Unix->catpath('','/d1/d2/d3/.','')",     '/d1/d2/d3/.'     ],
[ "Unix->catpath('','/d1/d2/d3/..','')",    '/d1/d2/d3/..'    ],
[ "Unix->catpath('','/d1/d2/d3/','.file')", '/d1/d2/d3/.file' ],
[ "Unix->catpath('','d1/d2/d3/','file')",   'd1/d2/d3/file'   ],
[ "Unix->catpath('','/../../d1/','')",      '/../../d1/'      ],
[ "Unix->catpath('','/././d1/','')",        '/././d1/'        ],
[ "Unix->catpath('d1','d2/d3/','')",        'd2/d3/'          ],
[ "Unix->catpath('d1','d2','d3/')",         'd2/d3/'          ],

[ "Unix->splitdir('')",           ''           ],
[ "Unix->splitdir('/d1/d2/d3/')", ',d1,d2,d3,' ],
[ "Unix->splitdir('d1/d2/d3/')",  'd1,d2,d3,'  ],
[ "Unix->splitdir('/d1/d2/d3')",  ',d1,d2,d3'  ],
[ "Unix->splitdir('d1/d2/d3')",   'd1,d2,d3'   ],

[ "Unix->catdir()",                     ''          ],
[ "Unix->catdir('')",                   '/'         ],
[ "Unix->catdir('/')",                  '/'         ],
[ "Unix->catdir('','d1','d2','d3','')", '/d1/d2/d3' ],
[ "Unix->catdir('d1','d2','d3','')",    'd1/d2/d3'  ],
[ "Unix->catdir('','d1','d2','d3')",    '/d1/d2/d3' ],
[ "Unix->catdir('d1','d2','d3')",       'd1/d2/d3'  ],
[ "Unix->catdir('/','d2/d3')",          '/d2/d3'    ],

[ "Unix->canonpath('///../../..//./././a//b/.././c/././')",   '/a/b/../c' ],
[ "Unix->canonpath('')",                       ''               ],
# rt.perl.org 27052
[ "Unix->canonpath('a/../../b/c')",            'a/../../b/c'    ],
[ "Unix->canonpath('/.')",                     '/'              ],
[ "Unix->canonpath('/./')",                    '/'              ],
[ "Unix->canonpath('/a/./')",                  '/a'             ],
[ "Unix->canonpath('/a/.')",                   '/a'             ],
[ "Unix->canonpath('/../../')",                '/'              ],
[ "Unix->canonpath('/../..')",                 '/'              ],

[  "Unix->abs2rel('/t1/t2/t3','/t1/t2/t3')",          '.'                  ],
[  "Unix->abs2rel('/t1/t2/t4','/t1/t2/t3')",          '../t4'              ],
[  "Unix->abs2rel('/t1/t2','/t1/t2/t3')",             '..'                 ],
[  "Unix->abs2rel('/t1/t2/t3/t4','/t1/t2/t3')",       't4'                 ],
[  "Unix->abs2rel('/t4/t5/t6','/t1/t2/t3')",          '../../../t4/t5/t6'  ],
#[ "Unix->abs2rel('../t4','/t1/t2/t3')",              '../t4'              ],
[  "Unix->abs2rel('/','/t1/t2/t3')",                  '../../..'           ],
[  "Unix->abs2rel('///','/t1/t2/t3')",                '../../..'           ],
[  "Unix->abs2rel('/.','/t1/t2/t3')",                 '../../..'           ],
[  "Unix->abs2rel('/./','/t1/t2/t3')",                '../../..'           ],
#[ "Unix->abs2rel('../t4','/t1/t2/t3')",              '../t4'              ],
[  "Unix->abs2rel('/t1/t2/t3', '/')",                 't1/t2/t3'           ],
[  "Unix->abs2rel('/t1/t2/t3', '/t1')",               't2/t3'              ],
[  "Unix->abs2rel('t1/t2/t3', 't1')",                 't2/t3'              ],
[  "Unix->abs2rel('t1/t2/t3', 't4')",                 '../t1/t2/t3'        ],
 [  "Unix->abs2rel('.', '.')",                         '.'                  ],
 [  "Unix->abs2rel('/', '/')",                         '.'                  ],
 [  "Unix->abs2rel('../t1', 't2/t3')",                 '../../../t1'        ],
 [  "Unix->abs2rel('t1', 't2/../t3')",                 '../t1'              ],

[ "Unix->rel2abs('t4','/t1/t2/t3')",             '/t1/t2/t3/t4'    ],
[ "Unix->rel2abs('t4/t5','/t1/t2/t3')",          '/t1/t2/t3/t4/t5' ],
[ "Unix->rel2abs('.','/t1/t2/t3')",              '/t1/t2/t3'       ],
[ "Unix->rel2abs('..','/t1/t2/t3')",             '/t1/t2/t3/..'    ],
[ "Unix->rel2abs('../t4','/t1/t2/t3')",          '/t1/t2/t3/../t4' ],
[ "Unix->rel2abs('/t1','/t1/t2/t3')",            '/t1'             ],

[ "Win32->case_tolerant()",         '1'  ],
[ "Win32->rootdir()",               '\\'  ],

[ "Win32->splitpath('file')",                            ',,file'                            ],
[ "Win32->splitpath('\\d1/d2\\d3/')",                    ',\\d1/d2\\d3/,'                    ],
[ "Win32->splitpath('d1/d2\\d3/')",                      ',d1/d2\\d3/,'                      ],
[ "Win32->splitpath('\\d1/d2\\d3/.')",                   ',\\d1/d2\\d3/.,'                   ],
[ "Win32->splitpath('\\d1/d2\\d3/..')",                  ',\\d1/d2\\d3/..,'                  ],
[ "Win32->splitpath('\\d1/d2\\d3/.file')",               ',\\d1/d2\\d3/,.file'               ],
[ "Win32->splitpath('\\d1/d2\\d3/file')",                ',\\d1/d2\\d3/,file'                ],
[ "Win32->splitpath('d1/d2\\d3/file')",                  ',d1/d2\\d3/,file'                  ],
[ "Win32->splitpath('C:\\d1/d2\\d3/')",                  'C:,\\d1/d2\\d3/,'                  ],
[ "Win32->splitpath('C:d1/d2\\d3/')",                    'C:,d1/d2\\d3/,'                    ],
[ "Win32->splitpath('C:\\d1/d2\\d3/file')",              'C:,\\d1/d2\\d3/,file'              ],
[ "Win32->splitpath('C:d1/d2\\d3/file')",                'C:,d1/d2\\d3/,file'                ],
[ "Win32->splitpath('C:\\../d2\\d3/file')",              'C:,\\../d2\\d3/,file'              ],
[ "Win32->splitpath('C:../d2\\d3/file')",                'C:,../d2\\d3/,file'                ],
[ "Win32->splitpath('\\../..\\d1/')",                    ',\\../..\\d1/,'                    ],
[ "Win32->splitpath('\\./.\\d1/')",                      ',\\./.\\d1/,'                      ],
[ "Win32->splitpath('\\\\node\\share\\d1/d2\\d3/')",     '\\\\node\\share,\\d1/d2\\d3/,'     ],
[ "Win32->splitpath('\\\\node\\share\\d1/d2\\d3/file')", '\\\\node\\share,\\d1/d2\\d3/,file' ],
[ "Win32->splitpath('\\\\node\\share\\d1/d2\\file')",    '\\\\node\\share,\\d1/d2\\,file'    ],
[ "Win32->splitpath('file',1)",                          ',file,'                            ],
[ "Win32->splitpath('\\d1/d2\\d3/',1)",                  ',\\d1/d2\\d3/,'                    ],
[ "Win32->splitpath('d1/d2\\d3/',1)",                    ',d1/d2\\d3/,'                      ],
[ "Win32->splitpath('\\\\node\\share\\d1/d2\\d3/',1)",   '\\\\node\\share,\\d1/d2\\d3/,'     ],

[ "Win32->catpath('','','file')",                            'file'                            ],
[ "Win32->catpath('','\\d1/d2\\d3/','')",                    '\\d1/d2\\d3/'                    ],
[ "Win32->catpath('','d1/d2\\d3/','')",                      'd1/d2\\d3/'                      ],
[ "Win32->catpath('','\\d1/d2\\d3/.','')",                   '\\d1/d2\\d3/.'                   ],
[ "Win32->catpath('','\\d1/d2\\d3/..','')",                  '\\d1/d2\\d3/..'                  ],
[ "Win32->catpath('','\\d1/d2\\d3/','.file')",               '\\d1/d2\\d3/.file'               ],
[ "Win32->catpath('','\\d1/d2\\d3/','file')",                '\\d1/d2\\d3/file'                ],
[ "Win32->catpath('','d1/d2\\d3/','file')",                  'd1/d2\\d3/file'                  ],
[ "Win32->catpath('C:','\\d1/d2\\d3/','')",                  'C:\\d1/d2\\d3/'                  ],
[ "Win32->catpath('C:','d1/d2\\d3/','')",                    'C:d1/d2\\d3/'                    ],
[ "Win32->catpath('C:','\\d1/d2\\d3/','file')",              'C:\\d1/d2\\d3/file'              ],
[ "Win32->catpath('C:','d1/d2\\d3/','file')",                'C:d1/d2\\d3/file'                ],
[ "Win32->catpath('C:','\\../d2\\d3/','file')",              'C:\\../d2\\d3/file'              ],
[ "Win32->catpath('C:','../d2\\d3/','file')",                'C:../d2\\d3/file'                ],
[ "Win32->catpath('','\\../..\\d1/','')",                    '\\../..\\d1/'                    ],
[ "Win32->catpath('','\\./.\\d1/','')",                      '\\./.\\d1/'                      ],
[ "Win32->catpath('\\\\node\\share','\\d1/d2\\d3/','')",     '\\\\node\\share\\d1/d2\\d3/'     ],
[ "Win32->catpath('\\\\node\\share','\\d1/d2\\d3/','file')", '\\\\node\\share\\d1/d2\\d3/file' ],
[ "Win32->catpath('\\\\node\\share','\\d1/d2\\','file')",    '\\\\node\\share\\d1/d2\\file'    ],

[ "Win32->splitdir('')",             ''           ],
[ "Win32->splitdir('\\d1/d2\\d3/')", ',d1,d2,d3,' ],
[ "Win32->splitdir('d1/d2\\d3/')",   'd1,d2,d3,'  ],
[ "Win32->splitdir('\\d1/d2\\d3')",  ',d1,d2,d3'  ],
[ "Win32->splitdir('d1/d2\\d3')",    'd1,d2,d3'   ],

[ "Win32->catdir()",                        ''                   ],
[ "Win32->catdir('')",                      '\\'                 ],
[ "Win32->catdir('/')",                     '\\'                 ],
[ "Win32->catdir('/', '../')",              '\\'                 ],
[ "Win32->catdir('/', '..\\')",             '\\'                 ],
[ "Win32->catdir('\\', '../')",             '\\'                 ],
[ "Win32->catdir('\\', '..\\')",            '\\'                 ],
[ "Win32->catdir('//d1','d2')",             '\\\\d1\\d2'         ],
[ "Win32->catdir('\\d1\\','d2')",           '\\d1\\d2'         ],
[ "Win32->catdir('\\d1','d2')",             '\\d1\\d2'         ],
[ "Win32->catdir('\\d1','\\d2')",           '\\d1\\d2'         ],
[ "Win32->catdir('\\d1','\\d2\\')",         '\\d1\\d2'         ],
[ "Win32->catdir('','/d1','d2')",           '\\d1\\d2'         ],
[ "Win32->catdir('','','/d1','d2')",        '\\d1\\d2'         ],
[ "Win32->catdir('','//d1','d2')",          '\\d1\\d2'         ],
[ "Win32->catdir('','','//d1','d2')",       '\\d1\\d2'         ],
[ "Win32->catdir('','d1','','d2','')",      '\\d1\\d2'           ],
[ "Win32->catdir('','d1','d2','d3','')",    '\\d1\\d2\\d3'       ],
[ "Win32->catdir('d1','d2','d3','')",       'd1\\d2\\d3'         ],
[ "Win32->catdir('','d1','d2','d3')",       '\\d1\\d2\\d3'       ],
[ "Win32->catdir('d1','d2','d3')",          'd1\\d2\\d3'         ],
[ "Win32->catdir('A:/d1','d2','d3')",       'A:\\d1\\d2\\d3'     ],
[ "Win32->catdir('A:/d1','d2','d3','')",    'A:\\d1\\d2\\d3'     ],
#[ "Win32->catdir('A:/d1','B:/d2','d3','')", 'A:\\d1\\d2\\d3'     ],
[ "Win32->catdir('A:/d1','B:/d2','d3','')", 'A:\\d1\\B:\\d2\\d3' ],
[ "Win32->catdir('A:/')",                   'A:\\'               ],
[ "Win32->catdir('\\', 'foo')",             '\\foo'              ],
[ "Win32->catdir('','','..')",              '\\'                 ],
[ "Win32->catdir('A:', 'foo')",             'A:\\foo'            ],

[ "Win32->catfile('a','b','c')",        'a\\b\\c' ],
[ "Win32->catfile('a','b','.\\c')",      'a\\b\\c'  ],
[ "Win32->catfile('.\\a','b','c')",      'a\\b\\c'  ],
[ "Win32->catfile('c')",                'c' ],
[ "Win32->catfile('.\\c')",              'c' ],
[ "Win32->catfile('a/..','../b')",       '..\\b' ],
[ "Win32->catfile('A:', 'foo')",         'A:\\foo'            ],


[ "Win32->canonpath('')",               ''                    ],
[ "Win32->canonpath('a:')",             'A:'                  ],
[ "Win32->canonpath('A:f')",            'A:f'                 ],
[ "Win32->canonpath('A:/')",            'A:\\'                ],
# rt.perl.org 27052
[ "Win32->canonpath('a\\..\\..\\b\\c')", '..\\b\\c'           ],
[ "Win32->canonpath('//a\\b//c')",      '\\\\a\\b\\c'         ],
[ "Win32->canonpath('/a/..../c')",      '\\a\\....\\c'        ],
[ "Win32->canonpath('//a/b\\c')",       '\\\\a\\b\\c'         ],
[ "Win32->canonpath('////')",           '\\'                  ],
[ "Win32->canonpath('//')",             '\\'                  ],
[ "Win32->canonpath('/.')",             '\\'                  ],
[ "Win32->canonpath('//a/b/../../c')",  '\\\\a\\b\\c'         ],
[ "Win32->canonpath('//a/b/c/../d')",   '\\\\a\\b\\d'         ],
[ "Win32->canonpath('//a/b/c/../../d')",'\\\\a\\b\\d'         ],
[ "Win32->canonpath('//a/b/c/.../d')",  '\\\\a\\b\\d'         ],
[ "Win32->canonpath('/a/b/c/../../d')", '\\a\\d'              ],
[ "Win32->canonpath('/a/b/c/.../d')",   '\\a\\d'              ],
[ "Win32->canonpath('\\../temp\\')",    '\\temp'              ],
[ "Win32->canonpath('\\../')",          '\\'                  ],
[ "Win32->canonpath('\\..\\')",         '\\'                  ],
[ "Win32->canonpath('/../')",           '\\'                  ],
[ "Win32->canonpath('/..\\')",          '\\'                  ],
[ "Win32->canonpath('d1/../foo')",      'foo'                 ],

# FakeWin32 subclass (see below) just sets CWD to C:\one\two and getdcwd('D') to D:\alpha\beta

[ "FakeWin32->abs2rel('/t1/t2/t3','/t1/t2/t3')",     '.'                      ],
[ "FakeWin32->abs2rel('/t1/t2/t4','/t1/t2/t3')",     '..\\t4'                 ],
[ "FakeWin32->abs2rel('/t1/t2','/t1/t2/t3')",        '..'                     ],
[ "FakeWin32->abs2rel('/t1/t2/t3/t4','/t1/t2/t3')",  't4'                     ],
[ "FakeWin32->abs2rel('/t4/t5/t6','/t1/t2/t3')",     '..\\..\\..\\t4\\t5\\t6' ],
[ "FakeWin32->abs2rel('../t4','/t1/t2/t3')",         '..\\..\\..\\one\\t4'    ],  # Uses _cwd()
[ "FakeWin32->abs2rel('/','/t1/t2/t3')",             '..\\..\\..'             ],
[ "FakeWin32->abs2rel('///','/t1/t2/t3')",           '..\\..\\..'             ],
[ "FakeWin32->abs2rel('/.','/t1/t2/t3')",            '..\\..\\..'             ],
[ "FakeWin32->abs2rel('/./','/t1/t2/t3')",           '..\\..\\..'             ],
[ "FakeWin32->abs2rel('\\\\a/t1/t2/t4','/t2/t3')",   '\\\\a\\t1\\t2\\t4'      ],
[ "FakeWin32->abs2rel('//a/t1/t2/t4','/t2/t3')",     '\\\\a\\t1\\t2\\t4'      ],
[ "FakeWin32->abs2rel('A:/t1/t2/t3','A:/t1/t2/t3')",     '.'                  ],
[ "FakeWin32->abs2rel('A:/t1/t2/t3/t4','A:/t1/t2/t3')",  't4'                 ],
[ "FakeWin32->abs2rel('A:/t1/t2/t3','A:/t1/t2/t3/t4')",  '..'                 ],
[ "FakeWin32->abs2rel('A:/t1/t2/t3','B:/t1/t2/t3')",     'A:\\t1\\t2\\t3'     ],
[ "FakeWin32->abs2rel('A:/t1/t2/t3/t4','B:/t1/t2/t3')",  'A:\\t1\\t2\\t3\\t4' ],
[ "FakeWin32->abs2rel('E:/foo/bar/baz')",            'E:\\foo\\bar\\baz'      ],
[ "FakeWin32->abs2rel('C:/one/two/three')",          'three'                  ],
[ "FakeWin32->abs2rel('C:\\Windows\\System32', 'C:\\')",  'Windows\System32'  ],
[ "FakeWin32->abs2rel('\\\\computer2\\share3\\foo.txt', '\\\\computer2\\share3')",  'foo.txt' ],
[ "FakeWin32->abs2rel('C:\\one\\two\\t\\asd1\\', 't\\asd\\')", '..\\asd1'     ],
[ "FakeWin32->abs2rel('\\one\\two', 'A:\\foo')",     'C:\\one\\two'           ],

[ "FakeWin32->rel2abs('temp','C:/')",                       'C:\\temp'                        ],
[ "FakeWin32->rel2abs('temp','C:/a')",                      'C:\\a\\temp'                     ],
[ "FakeWin32->rel2abs('temp','C:/a/')",                     'C:\\a\\temp'                     ],
[ "FakeWin32->rel2abs('../','C:/')",                        'C:\\'                            ],
[ "FakeWin32->rel2abs('../','C:/a')",                       'C:\\'                            ],
[ "FakeWin32->rel2abs('\\foo','C:/a')",                     'C:\\foo'                         ],
[ "FakeWin32->rel2abs('temp','//prague_main/work/')",       '\\\\prague_main\\work\\temp'     ],
[ "FakeWin32->rel2abs('../temp','//prague_main/work/')",    '\\\\prague_main\\work\\temp'     ],
[ "FakeWin32->rel2abs('temp','//prague_main/work')",        '\\\\prague_main\\work\\temp'     ],
[ "FakeWin32->rel2abs('../','//prague_main/work')",         '\\\\prague_main\\work'           ],
[ "FakeWin32->rel2abs('D:foo.txt')",                        'D:\\alpha\\beta\\foo.txt'        ],


[ "OS2->case_tolerant()",         '1'  ],

[ "OS2->catdir('A:/d1','B:/d2','d3','')", 'A:/d1/B:/d2/d3' ],

[ "OS2->catfile('a','b','c')",            'a/b/c'          ],
[ "OS2->catfile('a','b','./c')",          'a/b/c'  ],
[ "OS2->catfile('./a','b','c')",          'a/b/c'  ],
[ "OS2->catfile('c')",                    'c' ],
[ "OS2->catfile('./c')",                  'c' ],

[ "OS2->catdir('/', '../')",              '/'                 ],
[ "OS2->catdir('/', '..\\')",             '/'                 ],
[ "OS2->catdir('\\', '../')",             '/'                 ],
[ "OS2->catdir('\\', '..\\')",            '/'                 ],

[ "Mac->case_tolerant()",         '1'  ],

[ "Mac->catpath('','','')",              ''                ],
[ "Mac->catpath('',':','')",             ':'               ],
[ "Mac->catpath('','::','')",            '::'              ],

[ "Mac->catpath('hd','','')",            'hd:'             ],
[ "Mac->catpath('hd:','','')",           'hd:'             ],
[ "Mac->catpath('hd:',':','')",          'hd:'             ],
[ "Mac->catpath('hd:','::','')",         'hd::'            ],

[ "Mac->catpath('hd','','file')",       'hd:file'          ],
[ "Mac->catpath('hd',':','file')",      'hd:file'          ],
[ "Mac->catpath('hd','::','file')",     'hd::file'         ],
[ "Mac->catpath('hd',':::','file')",    'hd:::file'        ],

[ "Mac->catpath('hd:','',':file')",      'hd:file'         ],
[ "Mac->catpath('hd:',':',':file')",     'hd:file'         ],
[ "Mac->catpath('hd:','::',':file')",    'hd::file'        ],
[ "Mac->catpath('hd:',':::',':file')",   'hd:::file'       ],

[ "Mac->catpath('hd:','d1','file')",     'hd:d1:file'      ],
[ "Mac->catpath('hd:',':d1:',':file')",  'hd:d1:file'      ],
[ "Mac->catpath('hd:','hd:d1','')",      'hd:d1:'          ],

[ "Mac->catpath('','d1','')",            ':d1:'            ],
[ "Mac->catpath('',':d1','')",           ':d1:'            ],
[ "Mac->catpath('',':d1:','')",          ':d1:'            ],

[ "Mac->catpath('','d1','file')",        ':d1:file'        ],
[ "Mac->catpath('',':d1:',':file')",     ':d1:file'        ],

[ "Mac->catpath('','','file')",          'file'            ],
[ "Mac->catpath('','',':file')",         'file'            ], # !
[ "Mac->catpath('',':',':file')",        ':file'           ], # !


[ "Mac->splitpath(':')",              ',:,'               ],
[ "Mac->splitpath('::')",             ',::,'              ],
[ "Mac->splitpath(':::')",            ',:::,'             ],

[ "Mac->splitpath('file')",           ',,file'            ],
[ "Mac->splitpath(':file')",          ',:,file'           ],

[ "Mac->splitpath('d1',1)",           ',:d1:,'            ], # dir, not volume
[ "Mac->splitpath(':d1',1)",          ',:d1:,'            ],
[ "Mac->splitpath(':d1:',1)",         ',:d1:,'            ],
[ "Mac->splitpath(':d1:')",           ',:d1:,'            ],
[ "Mac->splitpath(':d1:d2:d3:')",     ',:d1:d2:d3:,'      ],
[ "Mac->splitpath(':d1:d2:d3:',1)",   ',:d1:d2:d3:,'      ],
[ "Mac->splitpath(':d1:file')",       ',:d1:,file'        ],
[ "Mac->splitpath('::d1:file')",      ',::d1:,file'       ],

[ "Mac->splitpath('hd:', 1)",         'hd:,,'             ],
[ "Mac->splitpath('hd:')",            'hd:,,'             ],
[ "Mac->splitpath('hd:d1:d2:')",      'hd:,:d1:d2:,'      ],
[ "Mac->splitpath('hd:d1:d2',1)",     'hd:,:d1:d2:,'      ],
[ "Mac->splitpath('hd:d1:d2:file')",  'hd:,:d1:d2:,file'  ],
[ "Mac->splitpath('hd:d1:d2::file')", 'hd:,:d1:d2::,file' ],
[ "Mac->splitpath('hd::d1:d2:file')", 'hd:,::d1:d2:,file' ], # invalid path
[ "Mac->splitpath('hd:file')",        'hd:,,file'         ],

[ "Mac->splitdir()",                   ''            ],
[ "Mac->splitdir('')",                 ''            ],
[ "Mac->splitdir(':')",                ':'           ],
[ "Mac->splitdir('::')",               '::'          ],
[ "Mac->splitdir(':::')",              '::,::'       ],
[ "Mac->splitdir(':::d1:d2')",         '::,::,d1,d2' ],

[ "Mac->splitdir(':d1:d2:d3::')",      'd1,d2,d3,::'],
[ "Mac->splitdir(':d1:d2:d3:')",       'd1,d2,d3'   ],
[ "Mac->splitdir(':d1:d2:d3')",        'd1,d2,d3'   ],

# absolute paths in splitdir() work, but you'd better use splitpath()
[ "Mac->splitdir('hd:')",              'hd:'              ],
[ "Mac->splitdir('hd::')",             'hd:,::'           ], # invalid path, but it works
[ "Mac->splitdir('hd::d1:')",          'hd:,::,d1'        ], # invalid path, but it works
[ "Mac->splitdir('hd:d1:d2:::')",      'hd:,d1,d2,::,::'  ],
[ "Mac->splitdir('hd:d1:d2::')",       'hd:,d1,d2,::'     ],
[ "Mac->splitdir('hd:d1:d2:')",        'hd:,d1,d2'        ],
[ "Mac->splitdir('hd:d1:d2')",         'hd:,d1,d2'        ],
[ "Mac->splitdir('hd:d1::d2::')",      'hd:,d1,::,d2,::'  ],

[ "Mac->catdir()",                 ''             ],
[ "Mac->catdir(':')",              ':'            ],

[ "Mac->catdir(':', ':')",         ':'            ],
[ "Mac->catdir(':', '')",          ':'            ],

[ "Mac->catdir(':', '::')",        '::'           ],

[ "Mac->catdir('::', '')",         '::'           ],
[ "Mac->catdir('::', ':')",        '::'           ],

[ "Mac->catdir('::', '::')",       ':::'          ],

[ "Mac->catdir(':d1')",                    ':d1:'        ],
[ "Mac->catdir(':d1:')",                   ':d1:'        ],
[ "Mac->catdir(':d1','d2')",               ':d1:d2:'     ],
[ "Mac->catdir(':d1',':d2')",              ':d1:d2:'     ],
[ "Mac->catdir(':d1',':d2:')",             ':d1:d2:'     ],
[ "Mac->catdir(':d1',':d2::')",            ':d1:d2::'     ],
[ "Mac->catdir(':',':d1',':d2')",          ':d1:d2:'     ],
[ "Mac->catdir('::',':d1',':d2')",         '::d1:d2:'    ],
[ "Mac->catdir('::','::',':d1',':d2')",    ':::d1:d2:'   ],
[ "Mac->catdir(':',':',':d1',':d2')",      ':d1:d2:'     ],
[ "Mac->catdir('::',':',':d1',':d2')",     '::d1:d2:'    ],

[ "Mac->catdir('d1')",                    ':d1:'         ],
[ "Mac->catdir('d1','d2','d3')",          ':d1:d2:d3:'   ],
[ "Mac->catdir('d1','d2/','d3')",         ':d1:d2/:d3:'  ],
[ "Mac->catdir('d1','',':d2')",           ':d1:d2:'      ],
[ "Mac->catdir('d1',':',':d2')",          ':d1:d2:'      ],
[ "Mac->catdir('d1','::',':d2')",         ':d1::d2:'     ],
[ "Mac->catdir('d1',':::',':d2')",        ':d1:::d2:'    ],
[ "Mac->catdir('d1','::','::',':d2')",    ':d1:::d2:'    ],
[ "Mac->catdir('d1','d2')",               ':d1:d2:'      ],
[ "Mac->catdir('d1','d2', '')",           ':d1:d2:'      ],
[ "Mac->catdir('d1','d2', ':')",          ':d1:d2:'      ],
[ "Mac->catdir('d1','d2', '::')",         ':d1:d2::'     ],
[ "Mac->catdir('d1','d2','','')",         ':d1:d2:'      ],
[ "Mac->catdir('d1','d2',':','::')",      ':d1:d2::'     ],
[ "Mac->catdir('d1','d2','::','::')",     ':d1:d2:::'    ],
[ "Mac->catdir('d1',':d2')",              ':d1:d2:'      ],
[ "Mac->catdir('d1',':d2:')",             ':d1:d2:'      ],

[ "Mac->catdir('hd:',':d1')",       'hd:d1:'      ],
[ "Mac->catdir('hd:d1:',':d2')",    'hd:d1:d2:'   ],
[ "Mac->catdir('hd:','d1')",        'hd:d1:'      ],
[ "Mac->catdir('hd:d1:',':d2')",    'hd:d1:d2:'   ],
[ "Mac->catdir('hd:d1:',':d2:')",   'hd:d1:d2:'   ],

[ "Mac->catfile()",                      ''                      ],
[ "Mac->catfile('')",                    ''                      ],
[ "Mac->catfile(':')",                   ':'                     ],
[ "Mac->catfile(':', '')",               ':'                     ],

[ "Mac->catfile('d1','d2','file')",      ':d1:d2:file' ],
[ "Mac->catfile('d1','d2',':file')",     ':d1:d2:file' ],
[ "Mac->catfile('file')",                'file'        ],
[ "Mac->catfile(':', 'file')",           ':file'       ],

[ "Mac->canonpath('')",                   ''     ],
[ "Mac->canonpath(':')",                  ':'    ],
[ "Mac->canonpath('::')",                 '::'   ],
[ "Mac->canonpath('a::')",                'a::'  ],
[ "Mac->canonpath(':a::')",               ':a::' ],

[ "Mac->abs2rel('hd:d1:d2:','hd:d1:d2:')",            ':'            ],
[ "Mac->abs2rel('hd:d1:d2:','hd:d1:d2:file')",        ':'            ], # ignore base's file portion
[ "Mac->abs2rel('hd:d1:d2:file','hd:d1:d2:')",        ':file'        ],
[ "Mac->abs2rel('hd:d1:','hd:d1:d2:')",               '::'           ],
[ "Mac->abs2rel('hd:d3:','hd:d1:d2:')",               ':::d3:'       ],
[ "Mac->abs2rel('hd:d3:','hd:d1:d2::')",              '::d3:'        ],
[ "Mac->abs2rel('hd:d1:d4:d5:','hd:d1::d2:d3::')",    '::d1:d4:d5:'  ],
[ "Mac->abs2rel('hd:d1:d4:d5:','hd:d1::d2:d3:')",     ':::d1:d4:d5:' ], # first, resolve updirs in base
[ "Mac->abs2rel('hd:d1:d3:','hd:d1:d2:')",            '::d3:'        ],
[ "Mac->abs2rel('hd:d1::d3:','hd:d1:d2:')",           ':::d3:'       ],
[ "Mac->abs2rel('hd:d3:','hd:d1:d2:')",               ':::d3:'       ], # same as above
[ "Mac->abs2rel('hd:d1:d2:d3:','hd:d1:d2:')",         ':d3:'         ],
[ "Mac->abs2rel('hd:d1:d2:d3::','hd:d1:d2:')",        ':d3::'        ],
[ "Mac->abs2rel('hd1:d3:d4:d5:','hd2:d1:d2:')",       'hd1:d3:d4:d5:'], # volume mismatch
[ "Mac->abs2rel('hd:','hd:d1:d2:')",                  ':::'          ],

[ "Mac->rel2abs(':d3:','hd:d1:d2:')",          'hd:d1:d2:d3:'     ],
[ "Mac->rel2abs(':d3:d4:','hd:d1:d2:')",       'hd:d1:d2:d3:d4:'  ],
[ "Mac->rel2abs('','hd:d1:d2:')",              ''                 ],
[ "Mac->rel2abs('::','hd:d1:d2:')",            'hd:d1:d2::'       ],
[ "Mac->rel2abs('::','hd:d1:d2:file')",        'hd:d1:d2::'       ],# ignore base's file portion
[ "Mac->rel2abs(':file','hd:d1:d2:')",         'hd:d1:d2:file'    ],
[ "Mac->rel2abs('::file','hd:d1:d2:')",        'hd:d1:d2::file'   ],
[ "Mac->rel2abs('::d3:','hd:d1:d2:')",         'hd:d1:d2::d3:'    ],
[ "Mac->rel2abs('hd:','hd:d1:d2:')",           'hd:'              ], # path already absolute
[ "Mac->rel2abs('hd:d3:file','hd:d1:d2:')",    'hd:d3:file'       ],
[ "Mac->rel2abs('hd:d3:','hd:d1:file')",       'hd:d3:'           ],

[ "Epoc->case_tolerant()",         '1'  ],

[ "Epoc->canonpath('')",                                      ''          ],
[ "Epoc->canonpath('///../../..//./././a//b/.././c/././')",   '/a/b/../c' ],
[ "Epoc->canonpath('/./')",                                   '/'         ],
[ "Epoc->canonpath('/a/./')",                                 '/a'        ],

# XXX Todo, copied from Unix, but fail. Should they? 2003-07-07 Tels
#[ "Epoc->canonpath('/a/.')",                                  '/a'        ],
#[ "Epoc->canonpath('/.')",                                    '/'         ],

[ "Cygwin->case_tolerant()",         '1'  ],
[ "Cygwin->catfile('a','b','c')",         'a/b/c'  ],
[ "Cygwin->catfile('a','b','./c')",       'a/b/c'  ],
[ "Cygwin->catfile('./a','b','c')",       'a/b/c'  ],
[ "Cygwin->catfile('c')",                 'c' ],
[ "Cygwin->catfile('./c')",               'c' ],

[ "Cygwin->splitpath('file')",            ',,file'            ],
[ "Cygwin->splitpath('/d1/d2/d3/')",      ',/d1/d2/d3/,'      ],
[ "Cygwin->splitpath('d1/d2/d3/')",       ',d1/d2/d3/,'       ],
[ "Cygwin->splitpath('/d1/d2/d3/.')",     ',/d1/d2/d3/.,'     ],
[ "Cygwin->splitpath('/d1/d2/d3/..')",    ',/d1/d2/d3/..,'    ],
[ "Cygwin->splitpath('/d1/d2/d3/.file')", ',/d1/d2/d3/,.file' ],
[ "Cygwin->splitpath('d1/d2/d3/file')",   ',d1/d2/d3/,file'   ],
[ "Cygwin->splitpath('/../../d1/')",      ',/../../d1/,'      ],
[ "Cygwin->splitpath('/././d1/')",        ',/././d1/,'        ],

[ "Cygwin->catpath('','','file')",            'file'            ],
[ "Cygwin->catpath('','/d1/d2/d3/','')",      '/d1/d2/d3/'      ],
[ "Cygwin->catpath('','d1/d2/d3/','')",       'd1/d2/d3/'       ],
[ "Cygwin->catpath('','/d1/d2/d3/.','')",     '/d1/d2/d3/.'     ],
[ "Cygwin->catpath('','/d1/d2/d3/..','')",    '/d1/d2/d3/..'    ],
[ "Cygwin->catpath('','/d1/d2/d3/','.file')", '/d1/d2/d3/.file' ],
[ "Cygwin->catpath('','d1/d2/d3/','file')",   'd1/d2/d3/file'   ],
[ "Cygwin->catpath('','/../../d1/','')",      '/../../d1/'      ],
[ "Cygwin->catpath('','/././d1/','')",        '/././d1/'        ],
[ "Cygwin->catpath('d1','d2/d3/','')",        'd2/d3/'          ],
[ "Cygwin->catpath('d1','d2','d3/')",         'd2/d3/'          ],

[ "Cygwin->splitdir('')",           ''           ],
[ "Cygwin->splitdir('/d1/d2/d3/')", ',d1,d2,d3,' ],
[ "Cygwin->splitdir('d1/d2/d3/')",  'd1,d2,d3,'  ],
[ "Cygwin->splitdir('/d1/d2/d3')",  ',d1,d2,d3'  ],
[ "Cygwin->splitdir('d1/d2/d3')",   'd1,d2,d3'   ],

[ "Cygwin->catdir()",                     ''          ],
[ "Cygwin->catdir('/')",                  '/'         ],
[ "Cygwin->catdir('','d1','d2','d3','')", '/d1/d2/d3' ],
[ "Cygwin->catdir('d1','d2','d3','')",    'd1/d2/d3'  ],
[ "Cygwin->catdir('','d1','d2','d3')",    '/d1/d2/d3' ],
[ "Cygwin->catdir('d1','d2','d3')",       'd1/d2/d3'  ],
[ "Cygwin->catdir('/','d2/d3')",     '/d2/d3'  ],

[ "Cygwin->canonpath('///../../..//./././a//b/.././c/././')",   '/a/b/../c' ],
[ "Cygwin->canonpath('')",                       ''               ],
[ "Cygwin->canonpath('a/../../b/c')",            'a/../../b/c'    ],
[ "Cygwin->canonpath('/.')",                     '/'              ],
[ "Cygwin->canonpath('/./')",                    '/'              ],
[ "Cygwin->canonpath('/a/./')",                  '/a'             ],
[ "Cygwin->canonpath('/a/.')",                   '/a'             ],
[ "Cygwin->canonpath('/../../')",                '/'              ],
[ "Cygwin->canonpath('/../..')",                 '/'              ],

[  "Cygwin->abs2rel('/t1/t2/t3','/t1/t2/t3')",          '.'                  ],
[  "Cygwin->abs2rel('/t1/t2/t4','/t1/t2/t3')",          '../t4'              ],
[  "Cygwin->abs2rel('/t1/t2','/t1/t2/t3')",             '..'                 ],
[  "Cygwin->abs2rel('/t1/t2/t3/t4','/t1/t2/t3')",       't4'                 ],
[  "Cygwin->abs2rel('/t4/t5/t6','/t1/t2/t3')",          '../../../t4/t5/t6'  ],
#[ "Cygwin->abs2rel('../t4','/t1/t2/t3')",              '../t4'              ],
[  "Cygwin->abs2rel('/','/t1/t2/t3')",                  '../../..'           ],
[  "Cygwin->abs2rel('///','/t1/t2/t3')",                '../../..'           ],
[  "Cygwin->abs2rel('/.','/t1/t2/t3')",                 '../../..'           ],
[  "Cygwin->abs2rel('/./','/t1/t2/t3')",                '../../..'           ],
#[ "Cygwin->abs2rel('../t4','/t1/t2/t3')",              '../t4'              ],
[  "Cygwin->abs2rel('/t1/t2/t3', '/')",                 't1/t2/t3'           ],
[  "Cygwin->abs2rel('/t1/t2/t3', '/t1')",               't2/t3'              ],
[  "Cygwin->abs2rel('t1/t2/t3', 't1')",                 't2/t3'              ],
[  "Cygwin->abs2rel('t1/t2/t3', 't4')",                 '../t1/t2/t3'        ],

[ "Cygwin->rel2abs('t4','/t1/t2/t3')",             '/t1/t2/t3/t4'    ],
[ "Cygwin->rel2abs('t4/t5','/t1/t2/t3')",          '/t1/t2/t3/t4/t5' ],
[ "Cygwin->rel2abs('.','/t1/t2/t3')",              '/t1/t2/t3'       ],
[ "Cygwin->rel2abs('..','/t1/t2/t3')",             '/t1/t2/t3/..'    ],
[ "Cygwin->rel2abs('../t4','/t1/t2/t3')",          '/t1/t2/t3/../t4' ],
[ "Cygwin->rel2abs('/t1','/t1/t2/t3')",            '/t1'             ],
[ "Cygwin->rel2abs('//t1/t2/t3','/foo')",          '//t1/t2/t3'      ],

) ;

can_ok('File::Spec::Win32', '_cwd');

{
    package File::Spec::FakeWin32;
    use vars qw(@ISA);
    @ISA = qw(File::Spec::Win32);

    sub _cwd { 'C:\\one\\two' }

    # Some funky stuff to override Cwd::getdcwd() for testing purposes,
    # in the limited scope of the rel2abs() method.
    if ($Cwd::VERSION && $Cwd::VERSION gt '2.17') {  # Avoid a 'used only once' warning
	local $^W;
	*rel2abs = sub {
	    my $self = shift;
	    local $^W;
	    local *Cwd::getdcwd = sub {
	      return 'D:\alpha\beta' if $_[0] eq 'D:';
	      return 'C:\one\two'    if $_[0] eq 'C:';
	      return;
	    };
	    *Cwd::getdcwd = *Cwd::getdcwd; # Avoid a 'used only once' warning
	    return $self->SUPER::rel2abs(@_);
	};
	*rel2abs = *rel2abs; # Avoid a 'used only once' warning
    }
}

# Tries a named function with the given args and compares the result against
# an expected result. Works with functions that return scalars or arrays.
for ( @tests ) {
    my ($function, $expected) = @$_;

    $function =~ s#\\#\\\\#g ;
    $function =~ s/^([^\$].*->)/File::Spec::$1/;
    my $got = join ',', eval $function;

 SKIP: {
	if ($@) {
	    skip "skip $function: $skip_exception", 1
		if $@ =~ /^\Q$skip_exception/;
	    is($@, '', $function);
	} else {
	    is($got, $expected, $function);
	}
    }
}

done_testing();
