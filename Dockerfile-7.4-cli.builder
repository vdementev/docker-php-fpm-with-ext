FROM php:7.4-fpm-alpine

# Add some system packages
RUN apk update && apk add --no-cache \
    brotli \
    curl \
    git \
    imagemagick \
    mariadb-connector-c \
    mysql-client \
    nano \
    nodejs \
    npm \
    zip \
    zstd \
    && rm -rf /var/cache/apk/ \
    && rm -rf /root/.cache \
    && rm -rf /tmp/*

# Add some PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    imagick \
    imap \
    intl \
    mcrypt \
    memcached \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    redis \
    soap \
    zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN node -v && npm install -g npx
RUN npm install -g semantic-release

WORKDIR /app