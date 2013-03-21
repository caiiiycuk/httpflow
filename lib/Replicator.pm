package Replicator;

use Proc::Fork;

my $verbose = 0;

sub new {
  my $class = shift;
  my $line = shift;
  
  if ($line =~ m|(.+):(.+)\{(.+)\}|) {
    return bless {
      host => $1,
      port => $2,
      http => 'http://' . $1 . ':' . $2,
      throughput => $3,
      req_count => 0,
      req_sec => 0
    }, $class;
  }

  return 0;
}

sub replicate {
  my $self = shift;
  my $request = shift;

  my $sec = time();
  if ($sec ne $self->{rec_sec}) {
    $self->{rec_sec} = $sec;
    $self->{req_count} = 0;
  }

  $self->{req_count}++;

  if ($self->{req_count} > $self->{throughput}) {
    my $count = $self->{req_count};
    my $max = $self->{throughput};
    verbose("Skip request (too fast), $count req/sec > $max req/sec\n");
    return;
  }

  run_fork {
    child {
      use JSON;
      use LWP::UserAgent;
      require HTTP::Request;

      my $userAgent  = delete $request->{headers}->{'User-Agent'};
      my $connection = delete $request->{headers}->{'Connection'};

      $httpRequest = HTTP::Request->new(
        GET => $self->{http} . $request->{path});

      for my $key (keys %{ $request->{headers} }) {
        $httpRequest->header($key => $request->{headers}->{$key} );
      }

      my $lwp = LWP::UserAgent->new;
      $lwp->timeout(10);
      $lwp->agent($userAgent) if ($userAgent);

      my $startAt = time();
      my $response = $lwp->request($httpRequest);
      my $time = time() - $startAt;

      if ($request->{code} ne $response->code()) {
        my $expected = $request->{code};
        my $actual = $response->code();
        my $requestDump = JSON::to_json($_, {utf8 => 1, pretty => 1});
        print STDERR <<"CODE";
==>error: wrong response code (expected: $expected != actual: $actual), request:
$requestDump
CODE
      }

      if ($time > $request->{time} + 1) {
        my $requestDump = JSON::to_json($_, {utf8 => 1, pretty => 1});
        print STDERR <<"TIME";
==>error: request processing is slow ($time vs $request->{time}), request:
$requestDump
TIME
      }
    }
    error {
      print STDERR "Unable to spawn child process\n";  
    }
  }

}

sub verbose($) {
  if ($verbose) {
    print STDOUT @_;
  }
}

sub makeVerbose {
  $verbose = 1;
}

1;