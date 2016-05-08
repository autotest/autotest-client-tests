
###
# XML::Filter::BufferText tests
# Robin Berjon <robin@knowscape.com>
# 29/01/2002 - v0.01
###

use strict;
use Test::More tests => 4;
BEGIN { use_ok('XML::Filter::BufferText'); }


package TestBuffer;
use strict;
use vars qw( $COUNT $DATA );
$COUNT = 0;
$DATA  = '';

sub new { return bless {}, 'TestBuffer'; }
sub characters { $COUNT++; }
sub comment { $DATA = $_[1]->{Data}; }

package main;
my $h = TestBuffer->new;
my $f = XML::Filter::BufferText->new( Handler => $h );

$f->start_document;
$f->characters({ Data => 'foo1' });
$f->characters({ Data => 'foo2' });
$f->end_document;
ok($TestBuffer::COUNT == 1);

$TestBuffer::DATA  = '';
$TestBuffer::COUNT = 0;
$f->start_document;
$f->characters({ Data => 'foo1' });
$f->comment({ Data => 'COMMENT' });
$f->characters({ Data => 'foo2' });
$f->end_document;
ok($TestBuffer::COUNT == 2);
ok($TestBuffer::DATA  eq 'COMMENT');
