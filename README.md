# php-static-builder
PHP Static Binary Builder. Building PHP static binary for personal project and testing.

**Please, do not use this for production.**

PHP static binary compiled with modules (`php -m`):
```
bcmath
bz2
calendar
Core
ctype
curl
date
dom
event
exif
FFI
fileinfo
filter
gd
hash
iconv
igbinary
intl
json
libxml
mbstring
mysqli
mysqlnd
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_pgsql
pdo_sqlite
Phar
posix
random
readline
redis
Reflection
session
shmop
SimpleXML
soap
sockets
sodium
SPL
sqlite3
standard
swoole
sysvmsg
sysvsem
sysvshm
tidy
tokenizer
xml
xmlreader
xmlwriter
xsl
zip
zlib
```

## Getting Started
Clone repository

```
git clone https://github.com/atrifat/php-static-builder
cd php-static-builder
```

If you have [act](https://github.com/nektos/act) then you can build PHP static binary using one simple command:

```
act --env PHP_VERSION=8.2.10
```

Otherwise you can also build using [builder-alpine](https://github.com/atrifat/builder-alpine/pkgs/container/builder-alpine) docker image:

```
docker run --rm -v `pwd`:/project -it ghcr.io/atrifat/builder-alpine:latest
```

and run build.sh

```
chmod +x build.sh
PHP_VERSION=8.2.10 ./build.sh
```

## License
MIT

## Author
Rif'at Ahdi Ramadhani (atrifat)
