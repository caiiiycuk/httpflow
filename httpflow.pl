use warnings;
use strict;
use utf8;
use FindBin;
use Getopt::Std;
use lib "$FindBin::Bin/lib";

use Flow;
use FileDump;
use JSON;

my $dumped = 0;

$SIG{'INT'} = sub {
  print "$dumped http requests dumped\n";
  FileDump::close();
  exit;
};

my %opt = ();
getopts( 'hdpvsf:', \%opt ) or usage();
usage() if $opt{h};

Flow::makeVerbose() if $opt{v};
FileDump::writeToFile($opt{f}, $opt{s}) if $opt{f};

binmode STDOUT, ":encoding(UTF-8)";

open(my $fh, "<-:encoding(UTF-8)") 
  || die "Unable to open STDIN for reading\n";

while (<$fh>) {
  my @closed = Flow::append $_;
    
  foreach (@closed) {
    if ($opt{d}) {
      print JSON::to_json($_, {utf8 => 1, pretty => $opt{p}}), "\n";
    }

    if ($opt{f}) {
      FileDump::write(JSON::to_json($_, {utf8 => 1, pretty => 0}));
    }

    $dumped++;
  }
}

close $fh;

sub usage {
  print STDERR << "EOF";
  httpflow
========

httpflow - extract http requests from tcpflow output.

usage
========
```
httpflow [-hdpvsf:]
  -h    : help message
  -d    : dump all requests to stdout
  -f    : dump all requests to file
  -s    : split dump file by hours
  -p    : pretty print
  -v    : print debug output
```

examples
========
```
Dump all requests on port 80
  sudo tcpflow -p -c -i any tcp port 80 | perl httpflow.pl -dp
  or
  sudo tcpdump -p -i any -w - 'tcp port 80' | tcpflow -r - -c | perl httpflow.pl -dp

Dump all requests into file
  sudo tcpflow -p -c -i any tcp port 80 | perl httpflow.pl -f requests.dump
  or
  sudo tcpdump -p -i any -w - 'tcp port 80' | tcpflow -r - -c | perl httpflow.pl -f requests.dump

Dump all reqests into file and split by hours
  sudo tcpflow -p -c -i any tcp port 80 | perl httpflow.pl -sf requests.dump
  or
  sudo tcpdump -p -i any -w - 'tcp port 80' | tcpflow -r - -c | perl httpflow.pl -sf requests.dump
```

prerequisites
========
* tcpflow
* perl with JSON module (cpan -i JSON)

dump output explain (-dp)
========
Dump of request is valid json string which can be pretty printed with -p flag. 
If -p flag is omitted then each request is take one line in httpflow output, so
it can be easily parsed with other tools.

Example output:
```
{
 "client" : "127.000.000.001.42108",
 "headers" : {
    "Connection" : "keep-alive",
    "User-Agent" : "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:19.0) Gecko/20100101 Firefox/19.0",
    "Accept-Encoding" : "gzip, deflate",
    "Accept" : "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Cookie" : "_ym_visorc=w; blackbird={\"pos\": 1, \"size\": 0, \"load\": null}",
    "Accept-Language" : "en-US,en;q=0.5",
    "Host" : "127.0.0.1:8080"
 },
 "time" : 0,
 "startAt" : 1363841630,
 "path" : "/",
 "server" : "127.000.000.001.08080",
 "code" : "200"
}
```    

* ```client```  - ipaddress.port of client machine
* ```server```  - ipaddress.port of server machine
* ```startAt``` - time when request starts
* ```time```    - elapsed time in seconds
* ```path```    - path of request
* ```headers``` - hash of request headers
* ```code```    - response code

support
========
https://github.com/caiiiycuk/httpflow

EOF

  exit;
}