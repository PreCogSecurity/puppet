# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security

- **Dependency audit gate in CI**: `bundler-audit` is now part of the test
  toolchain and runs as a dedicated CI job (`bundle exec bundle-audit check
  --update`). The gate is intentionally strict: the current dependency graph
  is era-appropriate (2016) and known advisories must be remediated by
  upgrading dependencies before shipping.
- **Secret scanning in CI**: added `util/ci/secret_scan.rb`, a dependency-free
  scanner for cloud access keys, private key material, and API tokens. It runs
  as a dedicated CI job and fails the build when a potential secret is
  committed.
- **Reproducible installs**: committed `Gemfile.lock` (generated with Bundler
  2.1.4) so a fresh clone installs the exact dependency graph. Transitive
  dependencies were pinned to versions compatible with the supported Ruby
  range (>= 1.9.3); newer releases of several gems require Ruby >= 2.4 and
  would break `bundle install` on supported runtimes.
- **Coverage gate**: SimpleCov is wired into the spec suite (activated via
  `COVERAGE=yes`) with a configurable minimum coverage threshold
  (`MINIMUM_COVERAGE`, default 40%) enforced by a dedicated CI job.

### Changed

- `.travis.yml` rewritten with explicit, named jobs (spec, coverage, RuboCop,
  commit-message check, dependency audit, secret scan) replacing the previous
  `$CHECK` environment-variable indirection. CI now runs on Ruby 2.3.1 with
  Bundler 2.1.4; the EOL Ruby 1.9.3/2.0.0/2.1.7/2.2.4 matrix was dropped
  because they cannot run the bundler version required by the lockfile.
- `appveyor.yml` updated to Ruby 2.3-x64 and Bundler 2.1.4 to match.
- Fixed a duplicate key in `.rubocop.yml` (`Lint/LiteralInInterpolation` was
  declared twice; the second declaration silently disabled the cop).
- Added `Dockerfile`, `.dockerignore`, and `docker-compose.yml` for
  one-command startup of the Puppet master (`docker compose up --build`).
- Added `.env.example` documenting the environment variables Puppet and its
  build tooling actually read.

### Added

- `CHANGELOG.md` (this file).
- `util/ci/secret_scan.rb`.

## [4.5.0] - 2016-05-12

- Puppet 4.5.0 release. See the upstream Puppet release notes for the full
  list of features and fixes in this version.