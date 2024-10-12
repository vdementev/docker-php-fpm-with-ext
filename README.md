# Docker PHP-FPM images with some extensions

![Docker Pulls](https://img.shields.io/docker/pulls/dementev/php-fpm-with-ext?style=flat-square)


## Disclaimer
I created this Docker image for my personal use, so it hasn't been tested for use cases outside of my own. By default, the image is configured with high values for execution time and memory usage. To customize these settings, place an .ini file with your desired configuration at /usr/local/etc/php/conf.d/99-php.ini.