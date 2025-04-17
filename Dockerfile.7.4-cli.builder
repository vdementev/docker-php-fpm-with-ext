FROM php:7.4-cli-alpine3.16

# Add some packages
RUN set -eux; \
    apk update; \
    apk upgrade --no-interactive; \
    curl -sSLf -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    apk add \
    brotli \
    busybox \
    fcgi \
    git \
    jq \
    mariadb-connector-c \
    mysql-client \
    nano \
    nodejs \ 
    npm \
    zip \
    zstd; \
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
    zip \
    zstd; \
    rm -rf /var/cache/apk/*; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    node -v; \
    npm install -g npx semantic-release

COPY ./conf/php-builder.ini /usr/local/etc/php/conf.d/01-php.ini
COPY ./conf/www.conf /usr/local/etc/php-fpm.d/www.conf

USER www-data

WORKDIR /app