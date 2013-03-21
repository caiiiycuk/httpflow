package Flow;

my $PACKET   = qr|(\d{3}\.\d{3}\.\d{3}\.\d{3}\.\d{5})-(\d{3}\.\d{3}\.\d{3}\.\d{3}\.\d{5})|;
my $GET      = qr|: GET|;
my $GET_PATH = qr|: GET\s+(/[^\s]*)|;
my $HEADER   = qr|^([\w-]+):(.+)$|;

my $RESPONSE_CODE = qr|: HTTP/1.1 (\d+)|;

my $flows = {};
my $activeFlow = undef;
my $verbose = 0;

sub append($);
sub _REQUEST($$$);
sub _RESPONSE($$$);
sub _BODY($);
sub normalize($);
sub verbose($);

sub append($) {
  $line = shift;

  my @closed = ();

  if ($line =~ $PACKET) {
    my $from = $1;
    my $to = $2;

    if ($line =~ $GET) {
      _REQUEST $line, $from, $to;
    } elsif ($line =~ $RESPONSE_CODE) {
      push @closed, _RESPONSE($1, $to, $from);
    } else {
      verbose "Unknow packet type $line";
    }
  } else {
    _BODY $line;
  }

  return @closed;
}

sub _REQUEST($$$) {
  my ($line, $client, $server) = @_;
  
  if ($line =~ $GET_PATH) {
    my $flow = {
      client    => $client,
      server    => $server,
      path      => $1,
      headers   => {},
      startAt   => time()
    };

    $flows->{$client} = $flow;
    $activeFlow = $flow;
  }
}

sub _RESPONSE($$$) {
  my ($code, $client, $server) = @_;

  $activeFlow = undef;

  if (defined $flows->{$client}) {
    my $flow = $flows->{$client};

    if ($flow->{server} eq $server) {
      delete $flows->{$client};

      $flow->{code} = $code;
      $flow->{time} = time() - $flow->{startAt};

      return ($flow);
    }
  }

  return ();
}

sub _BODY($) {
  my $line = normalize shift;

  unless ($activeFlow) {
    return;
  }

  if ($line =~ $HEADER) {
    $activeFlow->{headers}->{normalize($1)} = 
      normalize($2);
  } else {
    verbose "Unknow body part $line\n";
  }
}

sub verbose($) {
  if ($verbose) {
    print STDERR @_;
  }
}

sub makeVerbose {
  $verbose = 1;
}

sub normalize($) {
  my $line = shift;
  $line =~ s/\n|\r//g;
  $line =~ s/^\s+|\s+$//g;
  return $line;
}

1;