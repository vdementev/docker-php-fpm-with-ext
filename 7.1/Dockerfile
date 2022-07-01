FROM php:7.1-fpm-alpine

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
RUN IPE_LZF_BETTERCOMPRESSION=1 install-php-extensions \
    bcmath \
    bz2 \
    exif \
    gd \
    imagick \
    imap \
    intl \
    lzf \
    mcrypt \
    opcache \
    pcntl \
    pdo_mysql \
    redis \
    zip


# List of supported extensions available here:
# https://github.com/mlocati/docker-php-extension-installer#readme

# Installed modules:
# php -m
# [PHP Modules]
# bcmath
# bz2
# Core
# ctype
# curl
# date
# dom
# exif
# fileinfo
# filter
# ftp
# gd
# hash
# iconv
# imagick
# imap
# intl
# json
# libxml
# lzf
# mbstring
# mcrypt
# mysqlnd
# openssl
# pcntl
# pcre
# PDO
# pdo_mysql
# pdo_sqlite
# Phar
# posix
# readline
# redis
# Reflection
# session
# SimpleXML
# sodium
# SPL
# sqlite3
# standard
# tokenizer
# xml
# xmlreader
# xmlwriter
# Zend OPcache
# zip
# zlib