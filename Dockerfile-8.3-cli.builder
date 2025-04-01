FROM php:8.3-cli-alpine3.21

# Add some system packages
RUN set -eux; \
    apk update; \
    apk upgrade --no-interactive; \
    apk add \
        brotli \
        curl \
        git \
        jq \
        mariadb-connector-c \
        mysql-client \
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

COPY ./conf/php-builder.ini /usr/local/etc/php/conf.d/01-php.ini
COPY ./conf/www.conf /usr/local/etc/php-fpm.d/www.conf

RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    node -v; \
    npm install -g npx semantic-release

USER www-data

WORKDIR /app