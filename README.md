# Docker image with PHP-FPM and some extensions

![Docker Pulls](https://img.shields.io/docker/pulls/dementev/php-fpm-with-ext?style=flat-square) ![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/dementev/php-fpm-with-ext?style=flat-square) ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/dementev/php-fpm-with-ext/latest?style=flat-square) 


## Disclaimer
I made this Docker image for myself, so I have not tested it in use cases that I do not use myself.

By default high values for execution time and memory usage are used. To change them put ini file with needed configuration into /usr/local/etc/php/conf.d/99-php.ini