# Docker image with PHP-FPM and some extensions



## Build local
`docker build --squash -t dementev/php-fpm-with-ext:latest .`

Enable experimental features by starting dockerd with the --experimental flag or adding "experimental": true to the daemon.json file.


## Disclaimer
I made this Docker image for myself, so I have not tested it in use cases that I do not use myself.