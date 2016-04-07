
use strict;

use ExtUtils::testlib;

use GSSAPI qw(:all);
use Test::More tests => 3;



#--------------------------------------------------------
{
   my ($name, $display);
   my $keystring = 'chpasswd@mars.gac.edu';
   my $status = GSSAPI::Name->import($name, $keystring);
   ok ( $status, 'GSSAPI::Name->import() ' . $status );
   SKIP: {
       if ( $status->major != GSS_S_COMPLETE  ) {
           skip('GSSAPI::Name->import() failed ' . $status, 2 );
       }

       my $status = $name->display($display);
       #
       # The lc is needed for implementations that uppercase
       # the realm - part of $display
       # see <http://rt.cpan.org/Public/Bug/Display.html?id=18531>
       #
       ok ( $status, '$name->display() GSS_S_COMPLETE ' . $status);
       SKIP: {
           if ( $status->major != GSS_S_COMPLETE  ) {
             skip('$name->display() failed', 1 );
           }
           cmp_ok ( lc $display, 'eq', $keystring, 'check bugfix of <http://rt.cpan.org/Public/Bug/Display.html?id=5681>');
       }
   }
}
diag( "\n\n if you want to run tests that do a realworld *use* of your GSSAPI",
      "\n start a kinit and try to run",
      "\n\n./examples/getcred_hostbased.pl \n\n" );
#--------------------------------------------------------