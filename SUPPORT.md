# Support and lifecycle

## Tags

Tags are `{php-version}-{flavor}`. There is no `latest` — a PHP image without an
explicit version in the tag is a trap.

| Flavor | What it is |
|---|---|
| `fpm` | PHP-FPM listening on `:9000`, with the `fpm-health` healthcheck and the PrestaShop `chmod(0)` shim available for `LD_PRELOAD`. |
| `cli` | PHP CLI for workers, cron jobs and one-shot commands. Opcache is off. |
| `cli-builder` | The CLI image plus Composer, git and the build tools a `composer install` needs. Meant for a build stage, not for runtime. |

Architectures: `linux/amd64`, `linux/arm64`.

## Version matrix

Upstream status is [php.net's own](https://www.php.net/supported-versions.php),
as of September 2026 — not our opinion of it.

| Tag prefix | Flavors | Upstream PHP | Status here |
|---|---|---|---|
| `8.5` | fpm, cli, cli-builder | Active support | Supported |
| `8.4` | fpm, cli, cli-builder | Active support | Supported |
| `8.3` | fpm, cli, cli-builder | Security fixes only | Supported |
| `8.2` | fpm | Security fixes until 2026-12-31 | Supported until upstream stops |
| `8.1` | fpm | **End of life** (2025-12-31) | Published, unpatched |
| `8.0` | fpm | **End of life** (2023-11-26) | Published, unpatched, frozen |
| `7.4` | fpm, cli-builder | **End of life** (2022-11-28) | Published, unpatched, frozen |
| `7.3` | fpm | **End of life** (2021-12-06) | Published, unpatched, frozen |
| `7.2` | fpm | **End of life** (2020-11-30) | Published, unpatched, frozen |
| `7.1` | fpm | **End of life** (2019-12-01) | Published, unpatched, frozen |
| `7.0` | fpm | **End of life** (2019-01-10) | Published, unpatched, frozen |

## The end-of-life tags

They are still published, deliberately, and you should understand what that
means before you pull one.

**What you get.** A working PHP of that version, with the same extension set and
configuration as the supported tags. That is the entire value proposition: these
exist so a legacy application can be lifted onto a modern Docker host and kept
running while it is being migrated, instead of being kept alive on a decade-old
host that nobody dares to touch.

**What you do not get.** Security fixes for the PHP runtime — upstream stopped
shipping them on the dates above, and no repackaging changes that. The Alpine
and Debian base layers still get patched by the rebuild, but the interpreter
does not. Anything at or below `8.1` should be treated as running unpatched
code.

**What is frozen.** `7.0` through `8.0` build from cached layers only: PECL no
longer serves extension sources for those versions, so those Dockerfiles cannot
be rebuilt from scratch. The published tags keep working; they will not get new
builds. When the cache eventually goes, those tags stop being reproducible and
we will say so here rather than quietly failing.

**If you are on one of these:** the upgrade path is the point. `8.2` is the
nearest tag that still receives upstream security fixes, and `8.4` is the one
worth aiming at.

## Pinning

The version in the tag is the PHP minor, not the patch — `8.4-fpm` moves as PHP
8.4 patches land. For a reproducible build, pin the digest:

```dockerfile
FROM dementev/php-fpm-with-ext:8.4-fpm@sha256:...
```

## Patch cadence

Every push to `main` rebuilds and republishes the whole matrix. Unlike the other
`dementev/*` images, this repository has not yet moved to the shared PR-gated
pipeline with the Trivy scan gate — see [SECURITY.md](SECURITY.md) for what that
means in practice, and the open migration pull request for where it stands.

## Getting help

Open an issue at
[github.com/vdementev/docker-php-fpm-with-ext/issues](https://github.com/vdementev/docker-php-fpm-with-ext/issues).
Security reports go through [SECURITY.md](SECURITY.md) instead.
