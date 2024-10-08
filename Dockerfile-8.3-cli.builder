FROM php:8.3-cli-alpine3.20

# Add some system packages
RUN apk update && apk add --no-cache \
    7zip \
    brotli \
    curl \
    git \
    mariadb-connector-c \
    mysql-client \
    nano \
    nodejs \ 
    npm \
    zip \
    zstd

# Add some PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
    exif \
    gd \
    Igbinary \
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

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN node -v && npm install -g npx
RUN npm install -g semantic-release

WORKDIR /app