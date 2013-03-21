use warnings;
use strict;
use utf8;
use FindBin;
use Getopt::Std;
use lib "$FindBin::Bin/lib";

use Flow;
use Replicator;
use JSON;

my %opt = ();
getopts( 'hdpvr:', \%opt ) or usage();
usage() if $opt{h};

Flow::makeVerbose() if $opt{v};

my $replicator = undef;

if ($opt{r}) {
  $replicator = new Replicator($opt{r});
  unless ($replicator) {
    die "Unable to parse replicate server parameter should be host:port/percent%\n";
  }
}

binmode STDOUT, ":encoding(UTF-8)";

open(my $fh, "<-:encoding(UTF-8)") 
  || die "Unable to open STDIN for reading\n";

while (<$fh>) {
  my @closed = Flow::append $_;
    
  foreach (@closed) {
    if ($opt{d}) {
      print JSON::to_json($_, {utf8 => 1, pretty => $opt{p}}), "\n";
    }

    if ($opt{r}) {
      $replicator->replicate($_);
    }
  }
}

close $fh;

sub usage {
  print STDERR << "EOF";
httpflow
========

httpflow - extract http requests from tcpflow output and replicate it on another server.

usage
========
```
httpflow [-hdpvr:]
  -h    : help message
  -d    : dump all request to stdout (JSON should be installed)
  -p    : pretty print
  -v    : print debug output
  -r    : replicate on server host:port/percent%
```

examples
========
```
Dump all request on port 8080
  sudo tcpflow -c -i any tcp port 8080 | perl httpflow.pl -dp

Replicate 10% of requests on test server and write errors to file
  sudo tcpflow -c -i any tcp port 8080 | perl httpflow.pl -r host:port/10% > erros

Replicate 100% of requests on test server and dump request and errors to console
  sudo tcpflow -c -i any tcp port 8080 | perl httpflow.pl -dpr host:port/100%

```

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

replicate output errors explain (-r)
========
There are to types of replicate errors:
* ```wrong response code``` - when response code not match
* ```request processing is slow``` - when generation of request is slower than on original server

Example of wrong response code:
```
==>error: wrong response code (expected: 200 != actual: 404), request:
{
   "client" : "127.000.000.001.43827",
   "headers" : {
      "TE" : "deflate,gzip;q=0.3",
      "Accept" : "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Encoding" : "gzip, deflate",
      "Accept-Language" : "en-US,en;q=0.5",
      "Cookie" : "blackbird={\"pos\": 1, \"size\": 0, \"load\": null}; blackbird={\"pos\": 1, \"size\": 0, \"load\": null}; _ym_visorc=w",
      "Host" : "127.0.0.1:8080"
   },
   "time" : 0,
   "startAt" : 1363855762,
   "path" : "/maps/?tewerqwe=qweqw",
   "server" : "127.000.000.001.08080",
   "code" : "404"
}
```

support
========
https://github.com/caiiiycuk/httpflow

EOF

  exit;
}