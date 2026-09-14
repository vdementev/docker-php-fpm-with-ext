# php-fpm-with-ext

PHP-FPM and PHP-CLI images with the extensions most PHP projects actually reach
for already compiled in, a healthcheck that verifies the pool rather than the
socket, and configuration tuned for real applications instead of the upstream
defaults.

Published as [`dementev/php-fpm-with-ext`](https://hub.docker.com/r/dementev/php-fpm-with-ext)
for PHP 7.0 through 8.5, `linux/amd64` and `linux/arm64`.

```yaml
services:
  php:
    image: dementev/php-fpm-with-ext:8.4-fpm
    volumes:
      - ./:/app
```

## Tags

`{php-version}-{flavor}`. There is no `latest`: a PHP image whose tag doesn't
name the version is a trap.

| Flavor | What it is | PHP versions |
|---|---|---|
| `fpm` | PHP-FPM on `:9000`, behind nginx / Angie / Caddy | 7.0 – 8.5 |
| `cli` | One-shot CLI for cron jobs, queue workers, scripts | 8.3, 8.4, 8.5 |
| `cli-builder` | Build stage: CLI plus git, composer, node, npm, brotli, sqlite3 | 7.4, 8.3, 8.4, 8.5 |

PHP 8.1 and older are end of life upstream and are published unpatched, on
purpose, for legacy applications that are being migrated rather than rewritten.
Read [SUPPORT.md](SUPPORT.md) before you pull one — it says exactly what you do
and do not get.

## What's in the FPM images

- **Base**: `php:<version>-fpm-trixie` (Debian) for 8.1 and newer, Alpine for
  7.0 – 8.0.
- **Extensions**: bcmath, exif, gd, igbinary, imagick, intl, memcached, mysqli,
  opcache, pcntl, pdo_mysql, pdo_pgsql, redis, soap, zip, zstd — installed with
  [docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer),
  which is removed again in the same layer.
- **Tools**: `jq`, `less`, `mariadb-client`, `nano`, `procps`, `rsync`, `unzip`,
  `zip`, `zstd`, `libfcgi-bin`. `unzip` and `zip` are separate packages and
  deploy scripts tend to need both, so both are here.
- **Runs as `www-data`**, `WORKDIR /app`, `STOPSIGNAL SIGQUIT` so `docker stop`
  triggers FPM's graceful worker drain instead of cutting requests off.
- The PrestaShop `chmod(0)` shim, available but not enabled — see below.

The CLI images carry the same extension set (minus opcache in the CLI SAPI) and
add `git`. The `cli-builder` images add composer, node, npm, semantic-release,
brotli and sqlite3, and set no `disable_functions` — composer and npm have to be
able to spawn processes.

## Configuration

`conf/php.ini` lands as `/usr/local/etc/php/conf.d/01-php.ini`. Anything you drop
at `99-*.ini` overrides it:

```dockerfile
FROM dementev/php-fpm-with-ext:8.4-fpm
COPY 99-app.ini /usr/local/etc/php/conf.d/99-app.ini
COPY www.conf   /usr/local/etc/php-fpm.d/www.conf
```

Defaults worth knowing before you override them:

- **Limits are generous** — `memory_limit 1024M`, `max_execution_time 3600`,
  `post_max_size` and `upload_max_filesize` at 1 GB, `max_input_vars 50000`.
  They are sized for PrestaShop-class applications and long-running admin
  actions. If your app doesn't need that, lower them: they are a blast radius,
  not a feature.
- **`disable_functions`** blocks the process-spawning family as a whole (`exec`,
  `shell_exec`, `passthru`, `system`, `popen`, `proc_*`, `pcntl_exec`) plus `dl`,
  `show_source` and `highlight_file`. It deliberately does *not* block
  `getmypid` / `getmyuid` / `diskfreespace`, which break real libraries while
  blocking nothing (`posix_getpid` and `disk_free_space` remain).
- **`expose_php = Off`**, `display_errors = Off`, errors to stderr, sessions
  strict-mode with `HttpOnly` + `SameSite=Lax` cookies, and
  `security.limit_extensions = .php` in the pool.
- **OPcache** follows PrestaShop's tuning guide: 512 MB,
  `max_accelerated_files 32531`, `enable_file_override 0`, JIT off. Enabled
  under FPM, off in the CLI SAPI (`opcache.enable_cli = 0`), where a per-process
  cache costs more than it saves.
- **Pool**: `pm dynamic`, 50 max children, `pm.max_requests 500`,
  `clear_env = yes`, `catch_workers_output = yes`.

## Healthcheck

The FPM images run `fpm-health` as their `HEALTHCHECK`. It wraps
[php-fpm-healthcheck](https://github.com/renatomefi/php-fpm-healthcheck) and
fixes two things that matter in production:

- **It insists on a real status page.** php-fpm-healthcheck strips the FastCGI
  response headers with `tail -n +5`, which also strips the `File not found.`
  body it checks for — so on a pool with no `pm.status_path` it exits 0 and the
  container reports healthy while proving nothing beyond an open socket. The
  bundled `www.conf` sets `pm.status_path = /status` and `ping.path = /ping`; if
  you replace `www.conf`, keep `pm.status_path`.
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

`FPM_HEALTH_HOST` (default `localhost`) is there for pools that don't listen on
loopback.

## PrestaShop chmod(0000) cache bug workaround

PrestaShop's cache regeneration — module reset or install, cache clear,
debug-mode toggle — invalidates files like `appParameters.php`,
`class_index.php` and `namespaced_class_stub.php` by calling `chmod($file, 0000)`
and then rewriting them. If the rewrite fails or races, the files stay at mode
`0000` and every request after that returns a 500 until permissions are fixed by
hand. Reported upstream since PS 1.7.4 and still present in 8.2.x (PS issues
#10998, #13050, #30786, #37666).

The FPM images ship `/usr/local/lib/php-chmod-sanitize.so`, a small `LD_PRELOAD`
shim that intercepts `chmod`, `fchmod` and `fchmodat`. Called with mode `0`, it
promotes the call to `0644` for regular files and `0755` for directories;
non-zero modes pass through untouched. It is **not active by default** — enable
it per project:

```yaml
services:
  php:
    image: dementev/php-fpm-with-ext:8.4-fpm
    environment:
      LD_PRELOAD: /usr/local/lib/php-chmod-sanitize.so
```

`LD_PRELOAD` applies to every process in the container (FPM workers, CLI,
composer), so a genuine `chmod($x, 0)` anywhere else is rewritten too — for
PrestaShop that is the point. Only the FPM images ship the shim. It masks the
bug rather than fixing it; keep an eye on upstream.

## Building and testing locally

```sh
docker build -f Dockerfile.8.4-fpm -t php-test .   # one variant
./test.sh                                          # all 18, slow
```

`test.sh` smoke-tests each built image: reported version, extension count, FPM
health, and a clean error log.

## Security and provenance

Published digests carry an SBOM, max-mode SLSA provenance and a keyless Cosign
signature:

```sh
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github\.com/vdementev/docker-php-fpm-with-ext/' \
  dementev/php-fpm-with-ext:8.4-fpm
```

Unlike the other images in this family, this repository has not yet moved to the
shared PR-gated pipeline with a Trivy scan gate — a push to `main` publishes
directly. The migration is open as a pull request and is entangled with the
end-of-life question in [SUPPORT.md](SUPPORT.md). That gap is stated here rather
than glossed over; [SECURITY.md](SECURITY.md) has the reporting channel and the
response targets.

## Related images

One family, built by the same people, meant to run together — a proxy in front,
an app runtime, a database, and a way into it.

| Image | What it does |
|---|---|
| [`dementev/angie`](https://hub.docker.com/r/dementev/angie) — [source](https://github.com/vdementev/angie-docker) | Public-facing reverse proxy and TLS terminator — Angie, the nginx fork, with brotli, zstd and cache-purge |
| [`dementev/nginx`](https://hub.docker.com/r/dementev/nginx) — [source](https://github.com/vdementev/nginx-docker) | Static sites and SPAs behind that proxy — brotli/zstd siblings, Prometheus stub_status |
| **[`dementev/php-fpm-with-ext`](https://hub.docker.com/r/dementev/php-fpm-with-ext)** — this image | PHP-FPM and CLI, PHP 7.0 → 8.5, with the extensions most projects reach for |
| [`dementev/mysql-percona`](https://hub.docker.com/r/dementev/mysql-percona) — [source](https://github.com/vdementev/mysql-percona-docker) | Percona Server for MySQL 8.4 LTS, XtraBackup built in, no root inside |
| [`dementev/adminer`](https://hub.docker.com/r/dementev/adminer) — [source](https://github.com/vdementev/adminer-docker) | Adminer 6 with every driver it supports, for reaching any of the above |

## Maintainer

Built and maintained by [Vasilii Dementev](https://vasiliidementev.com) at
[Lotus Web Agency](https://lotuswebagency.com). These images are the base layer
under the client and product systems we run — PrestaShop stores, Laravel
applications, long-lived legacy PHP — which is where most of the decisions above
come from.

Issues and pull requests:
[github.com/vdementev/docker-php-fpm-with-ext](https://github.com/vdementev/docker-php-fpm-with-ext).
Need this kind of infrastructure built or maintained for your own stack?
[lotuswebagency.com](https://lotuswebagency.com).

Packaging in this repository is MIT licensed — see [LICENSE](LICENSE). PHP and
the bundled extensions keep their own upstream licenses.
