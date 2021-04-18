FROM php:8.0-fpm-alpine

# Install dependencies for our app
RUN apk update && apk add --no-cache \
    freetype-dev \
    gd \
    giflib-dev \
    gifsicle \
    icu-dev \
    imagemagick \
    jpegoptim \
    libexif-dev \
    libjpeg-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    mysql-client \
    nano \
    oniguruma-dev \
    optipng \
    pngquant \
    shadow \
    tiff-dev \
    tzdata \
    unzip \
    zip \
    zlib-dev \
    $PHPIZE_DEPS \
&& docker-php-ext-configure \
    gd --with-freetype=/usr/include/ \
       --with-jpeg=/usr/include/ \
&& docker-php-ext-configure intl \
&& docker-php-ext-install \
    pdo_mysql \
    opcache \
    bcmath \
    pcntl \
    gd \
    zip \
    exif \
    intl \
&& pecl install \
    redis-5.3.4 \
&& docker-php-ext-enable \
    redis \
&& docker-php-source delete \
&& rm -rf /var/cache/apk/*