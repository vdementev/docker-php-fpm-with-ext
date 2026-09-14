# php-fpm-with-ext — PHP-FPM / CLI with the extensions preinstalled

PHP-FPM and PHP-CLI images with the extensions most PHP projects actually reach
for already compiled in (gd, intl, imagick, redis, memcached, pdo_mysql,
pdo_pgsql, opcache, soap, zip, zstd, …), a healthcheck that verifies the pool
rather than the socket, and a small `LD_PRELOAD` shim for the PrestaShop
`chmod(0)` cache bug.

Defaults are sized for PrestaShop-class applications — 1 GB `memory_limit`, long
`max_execution_time`, large uploads. Drop your own `.ini` at
`/usr/local/etc/php/conf.d/99-php.ini` to override anything.

## Tags

`{version}-{flavor}`. There is no `latest`: a PHP image whose tag doesn't name
the version is a trap.

| Flavor | What it's for | PHP versions |
|---|---|---|
| `fpm` | PHP-FPM behind a reverse proxy (nginx / Angie / Caddy) | 7.0 – 8.5 |
| `cli` | One-shot PHP CLI for cron jobs, queue workers, scripts | 8.3, 8.4, 8.5 |
| `cli-builder` | Build stage: CLI + git, composer, node, npm, brotli, sqlite3 | 7.4, 8.3, 8.4, 8.5 |

Multi-arch: `linux/amd64`, `linux/arm64`. Every image carries an SBOM, max-mode
build provenance and a keyless Cosign signature:

```
cosign verify dementev/php-fpm-with-ext:8.5-fpm \
  --certificate-identity-regexp '^https://github\.com/vdementev/docker-php-fpm-with-ext/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

> **PHP 8.1 and older are end of life upstream** and are published here
> unpatched, on purpose, for legacy applications being migrated rather than
> rewritten. `7.0` – `8.0` are frozen: PECL no longer serves extension sources
> for them, so those tags keep working but cannot be rebuilt from scratch. The
> full matrix and what "supported" means for each row is in
> [SUPPORT.md](https://github.com/vdementev/docker-php-fpm-with-ext/blob/main/SUPPORT.md).

## What's inside (FPM)

- **PHP-FPM** (alpine for 7.0 – 8.0, debian trixie for 8.1+) with a
  consistent extension set: exif, gd, igbinary, imagick, intl,
  memcached, mysqli, opcache, pcntl, pdo_mysql, pdo_pgsql, redis, soap,
  zip, zstd.
- **`fpm-health`** wired up as a Docker `HEALTHCHECK`: it wraps
  php-fpm-healthcheck (renatomefi), requires a real status page back
  rather than just an open socket, and walks every pool listed in
  `FPM_HEALTH_PORTS` (comma-separated, default `9000`) so a container
  running more than one pool reports unhealthy when any of them dies.
  `pm.status_path = /status` and `ping.path = /ping` are set in the
  bundled `www.conf` — a replacement `www.conf` has to keep
  `pm.status_path`, or the healthcheck will (correctly) fail.
- **`STOPSIGNAL SIGQUIT`** so `docker stop` triggers FPM's graceful
  worker drain instead of an immediate `SIGTERM` kill.
- Tools: `jq`, `less`, `mariadb-client`, `nano`, `procps`, `rsync`,
  `unzip`, `zip`, `zstd`, `fcgi`/`libfcgi-bin` (for the healthcheck
  binary). `unzip` is a separate package from `zip` — deploy scripts
  that shell out to it need both.
- Runs as `www-data` by default. `WORKDIR /app`.

## What's inside (CLI / CLI-builder)

- `cli`: same extension set as FPM, minus the FPM healthcheck and shim.
  Adds `git` on top of the FPM tool list.
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

Defaults worth knowing before you override them:

- `disable_functions` blocks the process-spawning family as a whole
  (`exec`, `shell_exec`, `passthru`, `system`, `popen`, `proc_*`,
  `pcntl_exec`) plus `dl`, `show_source`/`highlight_file`. It does *not*
  block `getmypid`/`getmyuid`/`diskfreespace` — those break real
  libraries and blocked nothing (`posix_getpid`, `disk_free_space`).
  The `cli-builder` images set no `disable_functions` at all, since
  composer and npm need to spawn processes.
- OPcache follows PrestaShop's tuning guide, with
  `max_accelerated_files = 32531`, `enable_file_override = 0` and JIT
  off (`opcache.jit = disable`, `jit_buffer_size = 0`).

## Security

Published digests are signed and carry an SBOM and build provenance. This
repository has not yet moved to the shared PR-gated pipeline with a Trivy scan
gate that the other `dementev/*` images use — a push to `main` publishes
directly. That gap is stated rather than glossed over; see
[SECURITY.md](https://github.com/vdementev/docker-php-fpm-with-ext/blob/main/SECURITY.md)
for the reporting channel and response targets.

## Related images

One family, built by the same pipeline, meant to run together — a proxy in
front, an app runtime, a database, and a way into it.

| Image | What it does |
|---|---|
| [`dementev/angie`](https://hub.docker.com/r/dementev/angie) — [source](https://github.com/vdementev/angie-docker) | Public-facing reverse proxy and TLS terminator — Angie, the nginx fork, with brotli, zstd and cache-purge |
| [`dementev/nginx`](https://hub.docker.com/r/dementev/nginx) — [source](https://github.com/vdementev/nginx-docker) | Static sites and SPAs behind that proxy — brotli/zstd siblings, Prometheus stub_status |
| **[`dementev/php-fpm-with-ext`](https://hub.docker.com/r/dementev/php-fpm-with-ext)** — this image | PHP-FPM and CLI, PHP 7.0 → 8.5, with the extensions most projects reach for |
| [`dementev/mysql-percona`](https://hub.docker.com/r/dementev/mysql-percona) — [source](https://github.com/vdementev/mysql-percona-docker) | Percona Server for MySQL 8.4 LTS, XtraBackup built in, no root inside |
| [`dementev/adminer`](https://hub.docker.com/r/dementev/adminer) — [source](https://github.com/vdementev/adminer-docker) | Adminer 6 with every driver it supports, for reaching any of the above |

## Maintainer

Built and maintained by [Vasilii Dementev](https://vasiliidementev.com) at
[Lotus Web Agency](https://lotuswebagency.com). These images are not a side
project — they are the base layer under the client and product systems we run,
which is why they are gated, tested and signed rather than pushed by hand.

Issues and pull requests:
[github.com/vdementev/docker-php-fpm-with-ext](https://github.com/vdementev/docker-php-fpm-with-ext).
Need this kind of infrastructure built or maintained for your own stack?
[lotuswebagency.com](https://lotuswebagency.com).

Packaging in this repository is MIT licensed — see
[LICENSE](https://github.com/vdementev/docker-php-fpm-with-ext/blob/main/LICENSE). The software
inside the image keeps its own upstream licenses.
