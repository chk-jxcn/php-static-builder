#!/bin/bash

# Set strict bash execution
set -euxo pipefail
IFS=$'\n\t'

build_xz() {
    # build xz
    cd /project
    curl -LO https://github.com/tukaani-project/xz/releases/download/v5.4.3/xz-5.4.3.tar.gz
    tar xzf xz-5.4.3.tar.gz
    cd xz-5.4.3

    ./autogen.sh

    ./configure CFLAGS="-fPIC -O2" --with-pic --enable-shared --enable-static=yes --prefix=/usr

    make -j $(nproc) && make install
}

build_bz2() {
    # build bz2 static
    cd /project
    curl -LO https://github.com/libarchive/bzip2/archive/refs/tags/bzip2-1.0.8.tar.gz
    tar xzf bzip2-1.0.8.tar.gz

    cd bzip2-bzip2-1.0.8

    make PREFIX=/usr CFLAGS+="-fPIC -O2"

    cp libbz2.a /usr/lib/libbz2.a
}

build_libwebp() {
    # build libwebp static
    curl -L https://github.com/webmproject/libwebp/archive/refs/tags/v1.3.2.tar.gz -o libwebp-v1.3.2.tar.gz
    tar xzf libwebp-v1.3.2.tar.gz

    cd libwebp-1.3.2
    ./autogen.sh
    ./configure CFLAGS="-fPIC -O2" --with-pic --enable-static --disable-shared --prefix=/usr

    make clean
    make -j $(nproc) && make install
}

build_libxml2() {
    # build libxml2
    cd /project
    curl -LO https://gitlab.gnome.org/GNOME/libxml2/-/archive/v2.11.4/libxml2-v2.11.4.tar.gz
    tar xzf libxml2-v2.11.4.tar.gz

    cd libxml2-v2.11.4

    ./autogen.sh
    # ./configure --with-pic --enable-shared --enable-static CFLAGS="-fPIC -no-pie -O2" --prefix=/usr/local
    ./configure --prefix=/usr/local --with-pic --disable-shared --enable-static CFLAGS="-fPIC -O2"
    #LDFLAGS="-liconv"

    make clean
    make -j $(nproc) && make install
}

build_xslt() {
    # build xslt
    cd /project
    wget https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.38.tar.xz
    tar xJf libxslt-1.1.38.tar.xz

    cd libxslt-1.1.38

    ./configure --prefix=/usr/local --with-pic --enable-shared --enable-static CFLAGS="-fPIC -O2"

    make -j $(nproc) && make install
}

build_libzip() {
    # build libzip static
    cd /project
    git clone --depth 1 --branch v1.9.2 https://github.com/nih-at/libzip.git

    cd libzip

    rm -rf build

    #LDFLAGS="-lzstd"
    cmake -B build -G Ninja \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DENABLE_BZIP2=ON \
        -DENABLE_LZMA=ON \
        -DENABLE_OPENSSL=ON \
        -DENABLE_ZSTD=ON \
        -DCMAKE_BUILD_TYPE=MinSizeRel

    cmake --build build

    cp ./build/lib/libzip.a /usr/lib/
}

build_curl() {
    # build curl
    cd /project
    wget https://curl.se/download/curl-8.4.0.tar.gz
    tar xf curl-8.4.0.tar.gz

    cd curl-8.4.0

    ./configure --with-pic --disable-shared --enable-static CFLAGS="-fPIC -O2" --with-openssl --prefix=/usr

    make -j $(nproc) && make install
}

build_libidn2() {
    # build libidn2
    cd /project
    wget https://ftp.gnu.org/gnu/libidn/libidn2-2.3.4.tar.gz
    tar xf libidn2-2.3.4.tar.gz

    cd libidn2-2.3.4

    ./configure --with-pic --disable-shared --enable-static CFLAGS="-fPIC -O2" --prefix=/usr

    make
    cp lib/.libs/libidn2.a /usr/lib/libidn2.a
    # ldconfig
}

build_libsecp25k1() {
    # build libsecp25k1
    cd /project
    git clone --branch v0.1.1 --depth 1 https://github.com/1ma/secp256k1-nostr-php

    cd secp256k1-nostr-php
    git submodule init
    git submodule update

    cd secp256k1

    ./autogen.sh &&
        ./configure \
            --disable-benchmark \
            --disable-ctime-tests \
            --disable-examples \
            --disable-exhaustive-tests \
            --disable-shared \
            --disable-tests \
            --prefix=/usr \
            --with-pic

    make -j$(nproc)
    make -j $(nproc) && make install
}

build_php() {
    cd /project
    wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz -O php-${PHP_VERSION}.tar.gz
    tar xzf php-${PHP_VERSION}.tar.gz
    cd php-${PHP_VERSION}

    # sed -i 's/-export-dynamic/-all-static/g' Makefile
    autoupdate

    # add autoconf 2.71 fix
    wget https://raw.githubusercontent.com/petk/php-src/253ec6986fc5effc9bb4b3f41eefcad743f48ad5/build/libtool.m4 -O build/libtool.m4
    wget https://raw.githubusercontent.com/php/php-src/608bf7d1d3e641c915c011bebd7e50dfff41c4c8/configure.ac -O configure.ac

    # Replace incorrect version string
    sed -i "s/8.2.7-dev/${PHP_VERSION}/g" configure.ac

    cp ./configure ./configure.bak
    make distclean || make clean || true

    # add event extension
    wget https://pecl.php.net/get/event-3.0.8.tgz -O event-3.0.8.tgz
    tar xf event-3.0.8.tgz
    mv event-3.0.8 ext/event
    cp ext/event/php8/*.h ext/event/

    # add igbinary extension
    wget https://pecl.php.net/get/igbinary-3.2.14.tgz -O igbinary-3.2.14.tgz
    tar xf igbinary-3.2.14.tgz
    mv igbinary-3.2.14 ext/igbinary

    # add redis extension
    wget https://pecl.php.net/get/redis-5.3.7.tgz -O redis-5.3.7.tgz
    tar xf redis-5.3.7.tgz
    mv redis-5.3.7 ext/redis

    # add swoole extension
    wget https://pecl.php.net/get/swoole-5.0.3.tgz -O swoole-5.0.3.tgz
    tar xf swoole-5.0.3.tgz
    mv swoole-5.0.3 ext/swoole

    # add secp256k1_nostr extension
    cp -rf /project/secp256k1-nostr-php/ext ext/secp256k1_nostr

    # rebuilding configuration
    ./buildconf --force
    #autoupdate

    ./configure --datarootdir=/usr/share --prefix=/usr \
        --sysconfdir=/etc/php --with-config-file-path=/etc/php/ \
        --with-config-file-scan-dir=/etc/php/conf.d/ \
        --disable-shared --enable-static --disable-zts \
        --enable-posix --enable-pcntl --disable-cgi --disable-phpdbg \
        --enable-short-tags --with-pear --enable-phar --enable-fpm \
        --without-apxs2 --enable-bcmath --enable-gd --enable-intl \
        --enable-mbstring --enable-soap --enable-sockets --with-bz2 \
        --with-curl --with-jpeg --with-libxml=/usr/local \
        --with-openssl --with-pdo-mysql --with-pdo-pgsql \
        --with-readline --with-sodium --with-sqlite3 --with-tidy \
        --with-webp --with-xsl --with-zip --with-zlib --with-openssl \
        --with-iconv --with-mysqli --enable-sysvmsg --enable-sysvsem \
        --enable-sysvshm --enable-calendar --enable-exif \
        --enable-shmop --disable-opcache --disable-opcache-jit \
        --enable-filter --with-event-core --with-event-extra \
        --with-event-openssl --enable-event-sockets \
        --enable-igbinary --enable-redis --enable-redis-igbinary \
        --enable-redis-zstd --enable-rtld-now --with-event-pthreads \
        --with-nghttp2-dir=/usr --enable-swoole --enable-cares \
        --enable-mysqlnd --enable-openssl --enable-sockets \
        --enable-brotli --enable-swoole-curl --enable-swoole-pgsql \
        --with-external-pcre --enable-secp256k1_nostr

    # add makefile additional command for static build
    printf "\n\n%s\n\n%s\n\n%s\n\n\n" \
        'prepare-static-global: $(PHP_GLOBAL_OBJS)' \
        'prepare-static-binary: $(PHP_BINARY_OBJS)' \
        'prepare-static-cli: $(PHP_CLI_OBJS)' |
        tee -a Makefile

    # Add the static-library dependencies as a variable to the Makefile.
    printf "\n# %s\n%s\n\n" \
        'Added by static-builder.' \
        'STATIC_EXTRA_LIBS="-lstdc++ -ldl -lrt -l:libdl.a -l:libnghttp2.a -l:libgcrypt.a -l:libgpg-error.a -l:libncurses.a -l:libpq.a  -l:libpgport.a -l:libpgcommon.a -l:libreadline.a -l:libssl.a -l:libcrypto.a -l:libbrotlidec.a -l:libbrotlicommon.a -l:liblzma.a -l:libzstd.a -l:libzip.a -l:libcurl.a -l:libxml2.a -l:libpcre2-posix.a"' |
        tee -a Makefile

    # Add a new Makefile target to statically build the CLI SAPI.
    printf "%s\n%s\n\t%s\n\n" \
        'BUILD_STATIC_CLI = $(LIBTOOL) --mode=link $(CC) -export-dynamic -all-static $(CFLAGS_CLEAN) $(EXTRA_CFLAGS) $(EXTRA_LDFLAGS_PROGRAM) $(LDFLAGS) $(PHP_RPATHS) $(PHP_GLOBAL_OBJS:.lo=.o) $(PHP_BINARY_OBJS:.lo=.o) $(PHP_CLI_OBJS:.lo=.o) $(EXTRA_LIBS) $(ZEND_EXTRA_LIBS) $(STATIC_EXTRA_LIBS) -o $(SAPI_CLI_PATH)' \
        'cli-static: $(PHP_GLOBAL_OBJS) $(PHP_BINARY_OBJS) $(PHP_CLI_OBJS)' \
        '$(BUILD_STATIC_CLI)' |
        tee -a Makefile

    # Add a new Makefile target to statically build the FPM SAPI.
    printf "%s\n%s\n\t%s\n\n" \
        'BUILD_STATIC_FPM = $(LIBTOOL) --mode=link $(CC) -export-dynamic -all-static $(CFLAGS_CLEAN) $(EXTRA_CFLAGS) $(EXTRA_LDFLAGS_PROGRAM) $(LDFLAGS) $(PHP_RPATHS) $(PHP_GLOBAL_OBJS:.lo=.o) $(PHP_BINARY_OBJS:.lo=.o) $(PHP_FASTCGI_OBJS:.lo=.o) $(PHP_FPM_OBJS:.lo=.o) $(EXTRA_LIBS) $(FPM_EXTRA_LIBS) $(ZEND_EXTRA_LIBS) $(STATIC_EXTRA_LIBS) -o $(SAPI_FPM_PATH)' \
        'fpm-static: $(PHP_GLOBAL_OBJS) $(PHP_BINARY_OBJS) $(PHP_FASTCGI_OBJS) $(PHP_FPM_OBJS)' \
        '$(BUILD_STATIC_FPM)' |
        tee -a Makefile

    #make prepare-static-global -j $(nproc)
    #make prepare-static-binary -j $(nproc)
    #make prepare-static-cli -j $(nproc)

    make -j $(nproc)

    mv ./sapi/cli/php ./sapi/cli/php.bak
    mv ./sapi/fpm/php-fpm ./sapi/fpm/php-fpm.bak

    # Compile CLI.
    make cli-static -j $(nproc)
    strip --strip-all ./sapi/cli/php

    # Compile FPM
    make fpm-static -j $(nproc)
    strip --strip-all ./sapi/fpm/php-fpm

    # Compress with UPX
    upx -9 ./sapi/cli/php
    upx -9 ./sapi/fpm/php-fpm

    # install php
    make install-cli
    make install-fpm
    #make install-pear-installer
    make install-pear
    make install-build
    make install-programs
    make install-headers
    # make install-modules -j $(nproc) || true
    cp php.ini-production /etc/php/php.ini

    # make php-static distribution directory
    mkdir -p php-static-${PHP_VERSION}
    mkdir -p php-static-${PHP_VERSION}/usr/bin
    mkdir -p php-static-${PHP_VERSION}/usr/sbin
    mkdir -p php-static-${PHP_VERSION}/usr/local/bin
    mkdir -p php-static-${PHP_VERSION}/etc/php
    mkdir -p php-static-${PHP_VERSION}/etc/php/php-fpm.d
    mkdir -p php-static-${PHP_VERSION}/etc/ssl

    # copy binary
    cp -rf sapi/cli/php php-static-${PHP_VERSION}/usr/bin
    cp -rf sapi/fpm/php-fpm php-static-${PHP_VERSION}/usr/sbin/php-fpm
    cp -rf php.ini-production php-static-${PHP_VERSION}/etc/php/php.ini
    cp -rf sapi/fpm/php-fpm.conf php-static-${PHP_VERSION}/etc/php/php-fpm.conf
    cp -rf sapi/fpm/www.conf php-static-${PHP_VERSION}/etc/php/php-fpm.d/www.conf.EXAMPLE
    cp -rf /etc/ssl/certs php-static-${PHP_VERSION}/etc/ssl/certs
    # cp -rf composer.phar php-static/usr/local/bin/composer

    # chown as regular default user (usually with id 1000)
    chown -R 1000:1000 php-static-${PHP_VERSION}

    tar czf php-static-${PHP_VERSION}.tar.gz php-static-${PHP_VERSION}
    sha256sum -b php-static-${PHP_VERSION}.tar.gz >php-static-${PHP_VERSION}.tar.gz.SHA256 || true

    # chown as regular default user (usually with id 1000)
    chown 1000:1000 php-static-${PHP_VERSION}.tar.gz || true
    chown 1000:1000 php-static-${PHP_VERSION}.tar.gz.SHA256 || true

    cp -rf php-static-${PHP_VERSION}.tar.gz /work || true
    cp -rf php-static-${PHP_VERSION}.tar.gz.SHA256 /work || true
}

#build dependencies
echo "Building dependencies"
echo "====================="
echo "Building xz"
build_xz
echo "Building bz2"
build_bz2
echo "Building libwebp"
build_libwebp
echo "Building libxml2"
build_libxml2
echo "Building xslt"
build_xslt
echo "Building libzip"
build_libzip
echo "Building curl"
build_curl
echo "Building libidn2"
build_libidn2
echo "Building libsecp25k1"
build_libsecp25k1

# build php
# Check env variable and set default if not exist
if [[ -z "${PHP_VERSION}" ]]; then
    PHP_VERSION=8.2.11
else
    PHP_VERSION="${PHP_VERSION}"
fi

echo "Building PHP=${PHP_VERSION}"
build_php
