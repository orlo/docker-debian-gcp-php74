# Public Docker image

## Features 

 * PHP 7.4 via deb.sury.org
 * PHP GRPC module
 * PHP Protobuf module
 * Apache mod\_php
 
See also: https://hub.docker.com/r/socialsigninapp/docker-debian-gcp-php74/

## Building

( http_proxy stuff is optional. )

```bash
docker build \
    --build-arg=http_proxy="http://192.168.86.66:3128" \
    --build-arg=https_proxy="http://192.168.86.66:3128" \
    --no-cache \
    --rm \
    -t socialsigninapp/docker-debian-gcp-php74:latest \
    -t socialsigninapp/docker-debian-gcp-php74:$(date +%F) \
    --pull \
    .
```

## Todo

 * Add checksum checking on the downloaded pecl tgz files.
 * Link better to Debian/Debsury.org so we rebuild on change of those files
