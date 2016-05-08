# Hey Emacs, this is -*- perl -*- !
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# $Id: schema.t,v 1.1 1999/08/10 21:42:39 kmacleod Exp $
#

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Parser::PerlSAX;
use XML::PatAct::MatchName;
use XML::PatAct::ToObjects;

$loaded = 1;
print "ok 1\n";

my $patterns = [
      'schema'      => [ qw{ -holder                                  } ],
      'table'       => [ qw{ -make Schema::Table                      } ],
      'name'        => [ qw{ -field Name -as-string                   } ],
      'summary'     => [ qw{ -field Summary -as-string                } ],
      'description' => [ qw{ -field Description -as-string            } ],
      'column'      => [ qw{ -make Schema::Column -push-field Columns } ],
      'unique'      => [ qw{ -field Unique -value 1                   } ],
      'non-null'    => [ qw{ -field NonNull -value 1                  } ],
      'default'     => [ qw{ -field Default -as-string                } ],
		];

my $matcher = XML::PatAct::MatchName->new( Patterns => $patterns );
my $handler = XML::PatAct::ToObjects->new( Patterns => $patterns,
					   Matcher => $matcher);

my $parser = XML::Parser::PerlSAX->new( Handler => $handler );
$schema = $parser->parse(Source => { String => <<'EOF' } );
    <schema>
      <table>
        <name>MyTable</name>
        <summary>A short summary</summary>
        <description>A long description that may
          contain a subset of HTML</description>
        <column>
          <name>MyColumn1</name>
          <summary>A short summary</summary>
          <description>A long description</description>
          <unique/>
          <non-null/>
          <default>42</default>
        </column>
      </table>
    </schema>
EOF

$not_ok = 0;
$not_ok |= (!defined($schema)) || (ref($schema->[0]) ne 'Schema::Table');
$not_ok |= (!defined($schema->[0]{Name})) || ($schema->[0]{Name} ne 'MyTable');
$not_ok |= (!defined($schema->[0]{Summary}))
    || ($schema->[0]{Summary} ne 'A short summary');
$not_ok |= (!defined($schema->[0]{Description}));
$not_ok |= (!defined($schema->[0]{Columns}))
    || (ref($schema->[0]{Columns}[0]) ne 'Schema::Column');
$not_ok |= (!defined($schema->[0]{Columns}[0]{Name}))
    || ($schema->[0]{Columns}[0]{Name} ne 'MyColumn1');
$not_ok |= (!defined($schema->[0]{Columns}[0]{Summary}))
    || ($schema->[0]{Columns}[0]{Summary} ne 'A short summary');
$not_ok |= !defined($schema->[0]{Columns}[0]{Description});
$not_ok |= (!defined($schema->[0]{Columns}[0]{Unique}))
    || ($schema->[0]{Columns}[0]{Unique} != 1);
$not_ok |= (!defined($schema->[0]{Columns}[0]{NonNull}))
    || ($schema->[0]{Columns}[0]{NonNull} != 1);
$not_ok |= (!defined($schema->[0]{Columns}[0]{Default}))
    || ($schema->[0]{Columns}[0]{Default} != 42);

print $not_ok ? "not ok 2\n" : "ok 2\n";
