# syntax=docker/dockerfile:1.6
FROM node:24-trixie-slim AS node

FROM php:8.4-cli-trixie

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN set -eux; \
    ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm; \
    ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx; \
    ln -s ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
    brotli \
    git \
    jq \
    less \
    mariadb-client \
    nano \
    procps \
    rsync \
    sqlite3 \
    unzip \
    zip \
    zstd; \
    curl -sSLf -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    install-php-extensions \
    bcmath \
    exif \
    gd \
    igbinary \
    imagick \
    intl \
    memcached \
    mysqli \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    redis \
    soap \
    zip \
    zstd; \
    rm /usr/local/bin/install-php-extensions; \
    curl -sSLf https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    node -v; \
    npm install -g semantic-release; \
    npm cache clean --force; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY ./conf/php-builder.ini /usr/local/etc/php/conf.d/01-php.ini

USER www-data

WORKDIR /app

CMD ["sh"]
