FROM php:7.4-fpm-alpine

# Install dependencies for our app
RUN apk update && apk add --no-cache \
    shadow \
    nano \
    zip \
    libzip-dev \
    unzip \
    oniguruma-dev \
    libmcrypt-dev \
    freetype-dev \
    libexif-dev \
    zlib-dev \
    tiff-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libpng-dev \
    giflib-dev \
    imagemagick \
    gd \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    mysql-client \
    icu-dev \
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