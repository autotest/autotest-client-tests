
sub ntest ($$$) {
  my $ret = 1;
  if ($_[1] != $_[2]) {
    printf "#$_[0]: expecting $_[1]\n";
    printf "#$_[0]:       got $_[2]\n";
    printf "#line %d %s\n",(caller)[2,1];
    print "not ";
    $ret = 0;
  }
  print "ok $_[0]\n";
  $ret;
}

sub stest ($$$) {
  my $ret = 1;
  unless (defined $_[2] && $_[1] eq $_[2]) {
    printf "#$_[0]: expecting %s\n", $_[1] =~ /[^\.\d\w]/ ? "hex:".unpack("H*",$_[1]) : $_[1];
    printf "#$_[0]:       got %s\n", defined($_[2]) ? $_[2] =~  /[^\.\d\w]/ ? "hex:".unpack("H*",$_[2]) : $_[2] : 'undef';
    printf "#line %d %s\n",(caller)[2,1];
    print "not ";
    $ret = 0;
  }
  print "ok $_[0]\n";
  $ret;
}

sub btest ($$) {
  unless ($_[1]) {
    printf "#line %d %s\n",(caller)[2,1];
    print "not ";
  }
  print "ok $_[0]\n";
  $_[1]
}


sub rtest ($$$) {
  unless (eval { require Data::Dumper } ) {
    print "ok $_[0] # skip need Data::Dumper\n";
    return;
  }

  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Useqq = 1;
  my $expect = Data::Dumper::Dumper($_[1]);
  my $got = Data::Dumper::Dumper($_[2]);
  my $ok = $expect eq $got;

  unless ($ok) {
    printf "#$_[0]: expecting %s\n", $expect;
    printf "#$_[0]:       got %s\n", $got;
    printf "#line %d %s\n",(caller)[2,1];
    print "not ";
  }
  print "ok $_[0]\n";
  $ok;
}

1;

