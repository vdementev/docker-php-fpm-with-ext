FROM php:7.4-cli-alpine3.16

# Add some system packages
RUN set -eux; \
    apk update; \
    apk upgrade -q; \
    apk add \
        brotli \
        curl \
        git \
        jq \
        mariadb-connector-c \
        nano \
        nodejs \ 
        npm \
        zip \
        zstd; \
    rm -rf /var/cache/apk/*

# Add some PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN set -eux; \
    install-php-extensions \
        exif \
        gd \
        igbinary \
        intl \
        mcrypt \
        memcached \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        redis \
        soap \
        timezonedb \
        zip \
        zstd

RUN rm -rf /var/cache/apk/*

COPY ./conf/php7.ini /usr/local/etc/php/conf.d/01-php.ini
COPY ./conf/www.conf /usr/local/etc/php-fpm.d/www.conf

RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    node -v; \
    npm install -g npx semantic-release

USER www-data

WORKDIR /app