FROM php:8.0-fpm-alpine
# Installed PHP Modules:
#     Core
#     ctype
#     curl
#     date
#     dom
#     fileinfo
#     filter
#     ftp
#     hash
#     iconv
#     json
#     libxml
#     mbstring
#     mysqlnd
#     openssl
#     pcre
#     PDO
#     pdo_sqlite
#     Phar
#     posix
#     readline
#     Reflection
#     session
#     SimpleXML
#     sodium
#     SPL
#     sqlite3
#     standard
#     tokenizer
#     xml
#     xmlreader
#     xmlwriter
#     zlib

# Add some system packages
RUN apk update && apk add --no-cache \
    tzdata \
    nano \
    shadow \
    curl \
    mysql-client \
    && rm -rf /var/cache/apk/*

# Add some PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
    bz2 \
    dom\
    exif \
    fileinfo \
    gd \
    iconv \
    mcrypt \
    opcache \
    pdo_mysql \
    redis \
    simplexml \
    xml \
    xmlreader \
    zip \
    zlib