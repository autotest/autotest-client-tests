#!/usr/bin/perl

# This code used to generate a memory error in valgrind/etc.
# Testing it.

use strict;
use warnings;

use Test::More tests => 2;

use utf8;

package Test::XML::Ordered;

use XML::LibXML::Reader;

use Test::More;

use base 'Exporter';

use vars '@EXPORT_OK';

@EXPORT_OK = (qw(is_xml_ordered));

sub new
{
    my $class = shift;
    my $self = {};

    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _got
{
    return shift->{got_reader};
}

sub _expected
{
    return shift->{expected_reader};
}

sub _init
{
    my ($self, $args) = @_;

    $self->{got_reader} =
        XML::LibXML::Reader->new(@{$args->{got_params}});
    $self->{expected_reader} =
        XML::LibXML::Reader->new(@{$args->{expected_params}});

    $self->{diag_message} = $args->{diag_message};

    $self->{got_end} = 0;
    $self->{expected_end} = 0;

    return;
}

sub _got_end
{
    return shift->{got_end};
}

sub _expected_end
{
    return shift->{expected_end};
}

sub _read_got
{
    my $self = shift;

    if ($self->_got->read() <= 0)
    {
        $self->{got_end} = 1;
    }

    return;
}

sub _read_expected
{
    my $self = shift;

    if ($self->_expected->read() <= 0)
    {
        $self->{expected_end} = 1;
    }

    return;
}

sub _next_elem
{
    my $self = shift;

    $self->_read_got();
    $self->_read_expected();

    return;
}

sub _ns
{
    my $elem = shift;
    my $ns = $elem->namespaceURI();

    return defined($ns) ? $ns : "";
}

sub _compare_loop
{
    my $self = shift;

    my $calc_prob = sub {
        my $args = shift;

        if (!exists($args->{param}))
        {
            die "No 'param' specified.";
        }
        return
        {
            verdict => 0,
            param => $args->{param},
        }
    };

    NODE_LOOP:
    while ((!$self->_got_end()) && (!$self->_expected_end()))
    {
        my $type = $self->_got->nodeType();
        my $exp_type = $self->_expected->nodeType();

        if ($type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE())
        {
            $self->_read_got();
            redo NODE_LOOP;
        }
        elsif ($exp_type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE())
        {
            $self->_read_expected();
            redo NODE_LOOP;
        }
        elsif ($type != $exp_type)
        {
            return $calc_prob->({param => "nodeType"});
        }
        elsif ($type == XML_READER_TYPE_TEXT())
        {
            my $got_text = $self->_got->value();
            my $expected_text = $self->_expected->value();

            foreach my $t ($got_text, $expected_text)
            {
                $t =~ s{\A\s+}{}ms;
                $t =~ s{\s+\z}{}ms;
                $t =~ s{\s+}{ }ms;
            }
            if ($got_text ne $expected_text)
            {
                return $calc_prob->({param => "text"});
            }
        }
        elsif ($type == XML_READER_TYPE_ELEMENT())
        {
            if ($self->_got->name() ne $self->_expected->name())
            {
                return $calc_prob->({param => "element_name"});
            }
            if (_ns($self->_got) ne _ns($self->_expected))
            {
                return $calc_prob->({param => "mismatch_ns"});
            }
        }
    }
    continue
    {
        $self->_next_elem();
    }

    return { verdict => 1};
}

sub _get_diag_message
{
    my ($self, $status_struct) = @_;

    if ($status_struct->{param} eq "nodeType")
    {
        return
            "Different Node Type!\n"
            . "Got: " . $self->_got->nodeType() . " at line " . $self->_got->lineNumber()
            . "\n"
            . "Expected: " . $self->_expected->nodeType() . " at line " . $self->_expected->lineNumber()
            ;
    }
    elsif ($status_struct->{param} eq "text")
    {
        return
            "Texts differ: Got at " . $self->_got->lineNumber(). " with value <<@{[$self->_got->value()]}>> ; Expected at ". $self->_expected->lineNumber() . " with value <<@{[$self->_expected->value()]}>>.";
    }
    elsif ($status_struct->{param} eq "element_name")
    {
        return
            "Got name: " . $self->_got->name(). " at " . $self->_got->lineNumber() .
            " ; " .
            "Expected name: " . $self->_expected->name() . " at " .$self->_expected->lineNumber();
    }
    elsif ($status_struct->{param} eq "mismatch_ns")
    {
        return
            "Got Namespace: " . _ns($self->_got). " at " . $self->_got->lineNumber() .
            " ; " .
            "Expected Namespace: " . _ns($self->_expected) . " at " .$self->_expected->lineNumber();
    }

    else
    {
        die "Unknown param";
    }
}

sub compare
{
    local $Test::Builder::Level = $Test::Builder::Level+1;

    my $self = shift;

    $self->_next_elem();

    my $status_struct = $self->_compare_loop();
    my $verdict = $status_struct->{verdict};

    if (!$verdict)
    {
        diag($self->_get_diag_message($status_struct));
    }

    return ok($verdict, $self->{diag_message});
}

sub is_xml_ordered
{
    local $Test::Builder::Level = $Test::Builder::Level+1;

    my ($got_params, $expected_params, $message) = @_;

    my $comparator =
        Test::XML::Ordered->new(
            {
                got_params => $got_params,
                expected_params => $expected_params,
                diag_message => $message,
            }
        );

    return $comparator->compare();
}

1;

my $xml_source = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/">
  <head>
    <title>David vs. Goliath - Part I</title>
  </head>
  <body>
    <div class="fiction story" xml:id="index">
      <h1>David vs. Goliath - Part I</h1>
      <div class="fiction section" xml:id="top">
        <h2>The Top Section</h2>
        <p>
    King David and Goliath were standing by each other.
    </p>
        <p>
    David said unto Goliath: "I will shoot you. I <b>swear</b> I will"
    </p>
        <div class="fiction section" xml:id="goliath">
          <h3>Goliath's Response</h3>
          <p>
    Goliath was not amused.
    </p>
          <p>
    He said to David: "Oh, really. <i>David</i>, the red-headed!".
    </p>
          <p>
    David started listing Goliath's disadvantages:
    </p>
        </div>
      </div>
    </div>
  </body>
</html>
EOF

my $final_source = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/">
  <head>
    <title>David vs. Goliath - Part I</title>
  </head>
  <body>
    <div class="fiction story" xml:id="index">
      <h1>David vs. Goliath - Part I</h1>
      <div class="fiction section" xml:id="top">
        <h2>The Top Section</h2>
        <p>
    King David and Goliath were standing by each other.
    </p>
        <p>
    David said unto Goliath: "I will shoot you. I <b>swear</b> I will"
    </p>
        <div class="fiction section" xml:id="goliath">
          <h3>Goliath's Response</h3>
          <p>
    Goliath was not amused.
    </p>
          <p>
    He said to David: "Oh, really. <i>David</i>, the red-headed!".
    </p>
          <p>
    David started listing Goliath's disadvantages:
    </p>
        </div>
      </div>
    </div>
  </body>
</html>
EOF

my @common = (validation => 0, load_ext_dtd => 0, no_network => 1);
# TEST
Test::XML::Ordered::is_xml_ordered(
    [ string => $final_source, @common,],
    [ string => $xml_source, @common,],
    "foo",
);

# TEST
ok (1, "Finished");
