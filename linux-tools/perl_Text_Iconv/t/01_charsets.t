# @(#) $Id: 01_charsets.t,v 1.4 2007/10/12 21:38:01 mxp Exp $
# -*- encoding: iso-8859-1 -*-

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::Iconv;
$loaded = 1;
print "ok 1\n";

Text::Iconv->raise_error(1);

# Note: On VMS codepages are found in SYS$I18N_ICONV

%codesets = ('iso88591' => [qw(iso88591 iso8859-1 iso-8859-1 ISO88591
                               ISO8859-1 ISO-8859-1 88591 8859-1)],
             'cp037'    => [qw(cp037 CP037 ibm037 IBM037 ibm-037 IBM-037)],
             'cp850'    => [qw(cp850 CP850 ibm850 IBM850 ibm-850 IBM-850)],
             'utf8'     => [qw(utf8 utf-8 UTF8 UTF-8)]);

%strings  = ('iso88591' => "Schöne Grüße",
             'cp037'    => "\xa2\xa4\xa4\x94\x40\x83\xa4\x89\x98\xa4\x85",
             'cp850'    => "Sch\x94ne Gr\x81\xe1e",
             'utf8'     => "Sch\xc3\xb6ne Gr\xc3\xbc\xc3\x9fe");

$test_no = 1;

foreach $source (keys %strings)
{
   foreach $target (keys %codesets)
   {
      unless ($source eq $target)
      {
         $test_no++;

         $c1 = try_codesets($codesets{$source}, $codesets{$target});
         $c2 = try_codesets($codesets{$target}, $codesets{$source});

         if (not defined $c1 or not defined $c2)
         {
            print "not ok $test_no \t # (call to open_iconv() failed)\n";
         }
         elsif ($c1 == 0 or $c2 == 0)
         {
            print "ok $test_no \t ",
		"# skip ($source <-> $target conversion not supported)\n";
         }
         else
         {
            eval
            {
               $r1 = $c1->convert($strings{$source});
               $r2 = $c2->convert($r1);
            };

            if ($@)
            {
               print "not ok $test_no \t ",
		   "# ($source <-> $target conversion failed: $@)\n";
            }
            elsif ($r2 eq $strings{$source})
            {
               print "ok $test_no \t # ($source <-> $target) ",
		   "[", $c1->retval, "/", $c2->retval, "]\n";
            }
            else
            {
               print "not ok $test_no \t ",
		   "# ($source <-> $target roundtrip failed)",
		   "[", $c1->retval, "/", $c2->retval, "]\n";
            }
         }
      }
   }
}

###############################################################################

# This function expects two array references, each listing all the
# alternative names to try for the source and target codesets.  If the
# codeset is not supported (at least not under any of the names that
# were given), it returns 0.  If the call to iconv_open() fails due to
# other reasons, it returns undef.  Otherwise a Text::Iconv object for
# the requested conversion is returned.

sub try_codesets
{
   my ($from, $to) = @_;
   my $converter;

 TRY:
   foreach my $f (@$from)
   {
      foreach my $t (@$to)
      {
         eval
         {
            $converter = new Text::Iconv($f, $t);
         };

         last TRY if not $@;
      }
   }

   if ($@ =~ /^Unsupported conversion/)
   {
      return 0;
   }
   elsif ($@)
   {
      return undef;
   }
   else
   {
      return $converter;
   }
}

### Local variables:
### mode: perl
### End:
