# Docker PHP-FPM images with extensions

## Overview
This repository provides Docker images for PHP-FPM that come with a set of common extensions pre-installed and a pre-configured environment. These images are designed primarily for development and personal use, featuring high default values for resource limits like execution time and memory. Use your own configuration files in production environment!

## Disclaimer
I created this Docker image for my personal use, so it hasn't been tested for use cases outside of my own. To override necessary settings, place an .ini file with your desired configuration at /usr/local/etc/php/conf.d/99-php.ini.