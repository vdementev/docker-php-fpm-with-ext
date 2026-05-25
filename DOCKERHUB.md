# php-fpm-with-ext — PHP-FPM / CLI with common extensions

PHP-FPM and PHP-CLI images for **development and personal use**,
pre-loaded with the extensions most projects reach for (gd, intl,
imagick, redis, memcached, pdo_mysql, pdo_pgsql, opcache, soap, zip,
zstd, …) and a small `LD_PRELOAD` shim that papers over the PrestaShop
`chmod(0)` cache bug.

Defaults are generous (long `max_execution_time`, big `memory_limit`,
verbose error reporting) — drop your own `.ini` at
`/usr/local/etc/php/conf.d/99-php.ini` to override anything in
production.

## Tags

Each tag is `{version}-{flavor}`:

| Flavor        | What it's for                                             | PHP versions       |
|---------------|-----------------------------------------------------------|--------------------|
| `fpm`         | PHP-FPM behind a reverse proxy (nginx/Angie/Caddy).       | 7.0 – 8.5          |
| `cli`         | One-shot PHP CLI for cron jobs, queue workers, scripts.   | 8.3, 8.4, 8.5      |
| `cli-builder` | CI/build environment: CLI + git, composer, node, npm, brotli, sqlite3. | 7.4, 8.3, 8.4, 8.5 |

Multi-arch: `linux/amd64`, `linux/arm64`. SBOM and max-mode build
provenance attached to every image. Images are signed with Cosign
(keyless, OIDC-bound to this repo) — verify with:

```
cosign verify dementev/php-fpm-with-ext:8.5-fpm \
  --certificate-identity-regexp '^https://github\.com/vdementev/docker-php-fpm-with-ext/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

> EOL PHP versions (7.0 – 8.0) are still built for legacy projects, but
> their base images no longer receive security patches. Use them
> behind a strict proxy and only when you have no choice.

## What's inside (FPM)

- **PHP-FPM** (alpine for 7.0 – 8.0, debian trixie for 8.1+) with a
  consistent extension set: exif, gd, igbinary, imagick, intl,
  memcached, mysqli, opcache, pcntl, pdo_mysql, pdo_pgsql, redis, soap,
  zip, zstd.
- **php-fpm-healthcheck** (renatomefi) wired up as a Docker
  `HEALTHCHECK` against the FPM status socket.
- **`STOPSIGNAL SIGQUIT`** so `docker stop` triggers FPM's graceful
  worker drain instead of an immediate `SIGTERM` kill.
- Tools: `jq`, `mariadb-client`, `nano`, `rsync`, `zip`, `zstd`,
  `fcgi`/`libfcgi-bin` (for the healthcheck binary).
- Runs as `www-data` by default. `WORKDIR /app`.

## What's inside (CLI / CLI-builder)

- `cli`: same extension set as FPM, minus the FPM healthcheck and shim.
- `cli-builder`: adds `git`, `composer`, `node`, `npm`,
  `semantic-release`, `brotli`, `sqlite3`, `pdo_sqlite` for CI usage.
- Default `CMD ["sh"]` on `cli-builder`. Runs as `www-data`.

## PrestaShop `chmod(0)` shim

PrestaShop's cache regeneration (module reset/install, cache clear,
debug-mode toggle) invalidates files like `appParameters.php`,
`class_index.php`, and `namespaced_class_stub.php` by calling
`chmod($file, 0000)` and then rewriting them. If the rewrite fails or
races, the files stay at mode `0000` and every subsequent request
returns a 500 until permissions are manually fixed. Reported upstream
since PS 1.7.4, still present in 8.2.x
(PS issues #10998, #13050, #30786, #37666).

The FPM images ship `/usr/local/lib/php-chmod-sanitize.so`, an
`LD_PRELOAD` shim that intercepts `chmod`, `fchmod`, and `fchmodat`.
When called with mode `0`, the shim promotes the call to `0644` for
regular files and `0755` for directories. Non-zero modes pass through.
**Not active by default** — enable it per project:

```yaml
services:
  php:
    image: dementev/php-fpm-with-ext:8.3-fpm
    environment:
      LD_PRELOAD: /usr/local/lib/php-chmod-sanitize.so
```

`LD_PRELOAD` applies to every process in the container (FPM workers,
CLI, composer), so any genuine `chmod($x, 0)` anywhere will also be
rewritten — for PrestaShop that's the desired behavior. CLI / CLI-
builder variants do **not** ship the shim. The shim masks the bug
rather than fixing it — track upstream PS fixes.

## Override config

```dockerfile
FROM dementev/php-fpm-with-ext:8.3-fpm
COPY 99-app.ini /usr/local/etc/php/conf.d/99-app.ini
COPY www.conf  /usr/local/etc/php-fpm.d/www.conf
```

`01-php.ini` is the image-default; anything in `99-*.ini` overrides it.

## Source

[github.com/vdementev/docker-php-fpm-with-ext](https://github.com/vdementev/docker-php-fpm-with-ext) · MIT license
