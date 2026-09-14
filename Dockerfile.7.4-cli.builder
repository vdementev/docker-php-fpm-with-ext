# syntax=docker/dockerfile:1.6
FROM php:7.4-cli-alpine3.16

# This variant is published unpatched, on purpose. See SUPPORT.md.
LABEL com.lotuswebagency.support="end-of-life" \
      com.lotuswebagency.eol-date="2022-11-28" \
      com.lotuswebagency.rebuildable="false" \
      com.lotuswebagency.upgrade-to="8.4-fpm" \
      org.opencontainers.image.documentation="https://github.com/vdementev/docker-php-fpm-with-ext/blob/main/SUPPORT.md" \
      com.lotuswebagency.support-note="PHP 7.4 reached end of life on 2022-11-28 and receives no upstream security fixes. Published for legacy applications being migrated; see SUPPORT.md. PECL no longer serves extension sources for this version, so this variant builds from cache only."

# Add some packages
RUN set -eux; \
    apk upgrade --no-cache -q; \
    curl -sSLf -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    apk add --no-cache \
    bash \
    brotli \
    git \
    jq \
    mariadb-connector-c \
    mysql-client \
    nano \
    nodejs \
    npm \
    rsync \
    sqlite \
    zip \
    zstd; \
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
    npm install -g npx semantic-release

COPY ./conf/php7.ini /usr/local/etc/php/conf.d/01-php.ini
COPY ./conf/www.conf /usr/local/etc/php-fpm.d/www.conf

USER www-data

WORKDIR /app

CMD ["sh"]
