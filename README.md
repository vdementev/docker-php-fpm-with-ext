# Docker PHP-FPM images with extensions

## Overview
This repository provides Docker images for PHP-FPM that come with a set of common extensions pre-installed and a pre-configured environment. These images are designed primarily for development and personal use, featuring high default values for resource limits like execution time and memory. Use your own configuration files in production environment!

## Disclaimer
I created this Docker image for my personal use, so it hasn't been tested for use cases outside of my own. To override necessary settings, place an .ini file with your desired configuration at /usr/local/etc/php/conf.d/99-php.ini.

## Healthcheck

The FPM images run `fpm-health` as their `HEALTHCHECK`. It wraps
[php-fpm-healthcheck](https://github.com/renatomefi/php-fpm-healthcheck) and
adds two things that matter in practice:

- **It insists on a real status page.** php-fpm-healthcheck strips the FastCGI
  response headers with `tail -n +5`, which also strips the `File not found.`
  body it checks for — so on a pool with no `pm.status_path` it exits 0 and the
  container reports healthy while proving nothing beyond an open socket. The
  bundled `www.conf` sets `pm.status_path = /status` and `ping.path = /ping`;
  if you replace `www.conf`, keep `pm.status_path`.
- **It checks every pool.** Set `FPM_HEALTH_PORTS` to a comma-separated list
  when a container runs more than one pool, and any dead pool marks the whole
  container unhealthy:

```yaml
services:
  php:
    image: dementev/php-fpm-with-ext:8.4-fpm
    environment:
      FPM_HEALTH_PORTS: "9000,9001"
```

`FPM_HEALTH_HOST` (default `localhost`) is there too if the pools don't listen
on loopback.

## PrestaShop chmod(0000) cache bug workaround

PrestaShop's cache regeneration (module reset/install, cache clear, debug-mode toggle) invalidates files like `appParameters.php`, `class_index.php`, and `namespaced_class_stub.php` by calling `chmod($file, 0000)` and then rewriting them. If the rewrite fails or races, the files stay at mode `0000` and every subsequent request returns a 500 until permissions are manually fixed. Reported upstream since PS 1.7.4, still present in 8.2.x (PS issues #10998, #13050, #30786, #37666).

The FPM images ship a small `LD_PRELOAD` shim at `/usr/local/lib/php-chmod-sanitize.so` that intercepts `chmod`, `fchmod`, and `fchmodat`. When called with mode `0`, the shim promotes the call to `0644` for regular files and `0755` for directories. Non-zero modes pass through untouched. The shim is **not active by default** — enable it per project by setting `LD_PRELOAD` on the container:

```yaml
services:
  php:
    image: dementev/php-fpm-with-ext:8.3-fpm
    environment:
      LD_PRELOAD: /usr/local/lib/php-chmod-sanitize.so
```

Notes:
- `LD_PRELOAD` applies to every process in the container (PHP-FPM workers, CLI, composer), so any genuine `chmod($x, 0)` anywhere will also be rewritten. For PrestaShop deployments this is the desired behavior.
- Only the FPM image variants ship the shim. CLI/CLI-builder variants do not.
- The shim masks the bug rather than fixing it — keep an eye on upstream PS fixes.

bump
