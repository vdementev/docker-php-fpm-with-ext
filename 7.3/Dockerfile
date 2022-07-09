FROM php:7.3-fpm-alpine

# Add some system packages
RUN apk update && apk add --no-cache \
    brotli \
    curl \
    ghostscript \
    imagemagick \
    mysql-client \
    nano \
    shadow \
    tzdata \
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
    lz4 \
    lzf \
    mcrypt \
    memcached \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    redis \
    tidy \
    uploadprogress \
    zip

COPY ./php.ini /usr/local/etc/php/conf.d/01-php.ini

# List of supported extensions available here:
# https://github.com/mlocati/docker-php-extension-installer#readme