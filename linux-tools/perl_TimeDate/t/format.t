use Test::More tests => 202;
use Date::Format qw(ctime time2str);
use Date::Language;
use utf8;
my ($pkg, $t,$language);
$pkg = 'Date::Format::Generic';
while(<DATA>) {
  chomp;
  if (/^(\d+)/) {
    $t = $1;
    next;
  }
  elsif (/^(\w+)/) {
    $language = $1;
    $pkg = Date::Language->new($language);
    next;
  }

  my($fmt,$res) = split(/\t+/,$_);
  my $str = $pkg->time2str($fmt,$t,'GMT');
    is($str, $res,"$fmt");
}

__DATA__
936709362 # Tue Sep  7 11:22:42 1999 GMT
%y	99
%Y	1999
%%	%
%a	Tue
%A	Tuesday
%b	Sep
%B	September
%c	09/07/99 13:02:42
%C	Tue Sep  7 13:02:42 GMT 1999
%d	07
%e	 7
%D	09/07/99
%G	1026
%h	Sep
%H	13
%I	01
%j	250
%k	13
%l	 1
%L	9
%m	09
%M	02
%o	 7th
%p	PM
%q	3
%r	01:02:42 PM
%R	13:02
%s	936709362
%S	42
%T	13:02:42
%U	36
%w	2
%W	36
%x	09/07/99
%X	13:02:42
%y	99
%Y	1999
%Z	GMT
%z	+0000
%Od	VII
%Oe	VII
%OH	XIII
%OI	I
%Oj	CCL
%Ok	XIII
%Ol	I
%Om	IX
%OM	II
%Oq	III
%OY	MCMXCIX
%Oy	XCIX
German
%y	99
%Y	1999
%%	%
%a	Die
%A	Dienstag
%b	Sep
%B	September
%c	09/07/99 13:02:42
%C	Die Sep  7 13:02:42 GMT 1999
%d	07
%e	 7
%D	09/07/99
%h	Sep
%H	13
%I	01
%j	250
%k	13
%l	 1
%L	9
%m	09
%M	02
%o	 7.
%p	PM
%q	3
%r	01:02:42 PM
%R	13:02
%s	936709362
%S	42
%T	13:02:42
%U	36
%w	2
%W	36
%x	09/07/99
%X	13:02:42
%y	99
%Y	1999
%Z	GMT
%z	+0000
%Od	VII
%Oe	VII
%OH	XIII
%OI	I
%Oj	CCL
%Ok	XIII
%Ol	I
%Om	IX
%OM	II
%Oq	III
%OY	MCMXCIX
%Oy	XCIX
Italian
%y	99
%Y	1999
%%	%
%a	Mar
%A	Martedi
%b	Set
%B	Settembre
%c	09/07/99 13:02:42
%C	Mar Set  7 13:02:42 GMT 1999
%d	07
%e	 7
%D	09/07/99
%h	Set
%H	13
%I	01
%j	250
%k	13
%l	 1
%L	9
%m	09
%M	02
%o	 7th
%p	PM
%q	3
%r	01:02:42 PM
%R	13:02
%s	936709362
%S	42
%T	13:02:42
%U	36
%w	2
%W	36
%x	09/07/99
%X	13:02:42
%y	99
%Y	1999
%Z	GMT
%z	+0000
%Od	VII
%Oe	VII
%OH	XIII
%OI	I
%Oj	CCL
%Ok	XIII
%Ol	I
%Om	IX
%OM	II
%Oq	III
%OY	MCMXCIX
%Oy	XCIX
316648800	# Wed Jan  14 00:00:00 1980
%G	1	#0 is interpreted as empty string
Bulgarian
1283926923 # ср сеп  8 09:22:03 EET 2010 /Tue Sep 06:22:03 GMT 2010
%y	10
%Y	2010
%%	%
%a	ср
%A	сряда
%b	сеп
%B	септември
%c	09/08/10 06:22:03
%C	ср сеп  8 06:22:03 GMT 2010
%d	08
%e	 8
%D	09/08/10
%G	1600
%h	сеп
%H	06
%I	06
%j	251
%k	 6
%l	 6
%L	9
%m	09
%M	22
%o	 8ми
%p	AM
%q	3
%r	06:22:03 AM
%R	06:22
%s	1283926923
%S	03
%T	06:22:03
%U	36
%w	3
%W	36
%x	09/08/10
%X	06:22:03
%Z	GMT
%z	+0000
%z	+0000
%Od	VIII
%Oe	VIII
%OH	VI
%OI	VI
%Oj	CCLI
%Ok	VI
%Ol	VI
%Om	IX
%OM	XXII
%Oq	III
%OY	MMX
%Oy	X
