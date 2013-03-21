httpflow
========

httpflow - extract http requests from tcpflow output and replicate it on another server.

usage
========
```
httpflow [-hdpv]
  -h    : help message
  -d    : dump all request to stdout (JSON should be installed)
  -p    : pretty print
  -v    : print debug output
```

examples
========
```
Dump all request on port 8080
  sudo tcpflow -c -i any tcp port 8080 | perl httpflow.pl -dp
```

output explain (-dp)
========
Dump of request is valid json string which can be pretty printed with -p flag. 
If -p flag is omitted then each request is take one line in httpflow output, so
it can be easily parse with other tools.

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

* client  - ipaddress.port of client machine
* server  - ipaddress.port of server machine
* startAt - time when request starts
* time    - elapsed time in seconds
* path    - path of request
* headers - hash of request headers
* code    - response code