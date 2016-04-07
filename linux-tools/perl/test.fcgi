#!/usr/bin/perl
use strict;
use CGI;
use CGI::Fast;

while (my $q = new CGI::Fast()) {

print $q->header() ;
print $q->start_html('Test FAST CGI script');
print $q->p('Hello!');
print $q->end_html();

}

