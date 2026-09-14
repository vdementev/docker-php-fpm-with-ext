# Security policy

## Reporting a vulnerability

Please report privately rather than opening a public issue.

- [GitHub private vulnerability reporting](https://github.com/vdementev/docker-php-fpm-with-ext/security/advisories/new) (preferred)
- `security@lotuswebagency.com`

Useful in a report: the tag or digest you found it in, the CVE or a
reproduction, and what an attacker gets out of it. If you have a fix, a pull
request is welcome, but send the report first.

## Response targets

Business days, Asia/Bangkok.

| Stage | Target |
|---|---|
| Acknowledgement | 2 business days |
| Triage and severity call | 5 business days |
| Published fix — fixable CRITICAL or HIGH | 7 days from triage |
| Published fix — everything else | the next release |

Fixes ship as a rebuild of the affected tags, so `docker pull` is the upgrade
path. Tag lifecycle and rebuild cadence are described in [SUPPORT.md](SUPPORT.md).

## What is already automated

Builds run on every push to `main` and publish straight to Docker Hub. Unlike
the other `dementev/*` images, this repository has **not** yet moved to the
shared PR-gated pipeline in
[vdementev/docker-workflows](https://github.com/vdementev/docker-workflows), so
there is no Trivy gate standing between a change and a published tag here yet.
The migration is open as a pull request and is blocked on the end-of-life
question described in [SUPPORT.md](SUPPORT.md). Treat that as a known gap when
you assess this image, and prefer the supported PHP versions.

Published digests still carry an SBOM, build provenance and a keyless Cosign
signature.

## Scope

In scope: anything shipped from this repository, and anything in a published
`dementev/php-fpm-with-ext` image.

Out of scope: vulnerabilities in upstream projects that we only package — report
those upstream, and tell us so we can pin or patch around them; findings that
require an already-compromised host or Docker daemon; and CVEs in the PHP
runtime of an end-of-life tag, which are expected and documented in
[SUPPORT.md](SUPPORT.md) rather than fixable here.
