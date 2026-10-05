# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security

- **Log files are no longer created world readable**: `Puppet::Util::Log`'s file
  destination passed no mode to `File.open`, so a new log file inherited the
  process umask and was `0644` on a stock configuration. It is now created with
  mode `0640`. The log directory is created `0750` rather than `0755`, matching
  the documented mode of the `logdir` setting. Puppet logs carry node names,
  managed resource contents and, at debug level, applied parameter values, so
  they must not be readable by unprivileged local users. Existing log files keep
  the permissions their administrator gave them; nothing is rewritten on disk.
- **Structured logging (`log_format`)**: new `plain` (default) / `json` setting.
  With `log_format = json` the console and file destinations emit newline
  delimited JSON, one self-describing object per line carrying level, message,
  source, tags, timestamp and issue code. This removes the need for brittle grok
  patterns to ship Puppet logs to a SIEM, and unlike the historical JSON-array
  format it stays parseable after an unclean shutdown. Colour escapes are never
  emitted inside structured output. A `.json` log file keeps the legacy array
  format, so existing log consumers are unaffected. Invalid values fail closed
  with a `Puppet::Settings::ValidationError` naming the offending value.
- **Static analysis and dependency review in CI**: added
  `.github/workflows/security.yml` with CodeQL Ruby semantic analysis (weekly
  and on every push/PR), pull-request dependency review that blocks a gem with a
  known advisory, and a gitleaks history scan. Every job runs with
  `permissions: contents: read` except CodeQL, which needs `security-events:
  write`.
- **Dependency update tooling**: added `.github/dependabot.yml` covering both the
  bundler ecosystem and GitHub Actions pins. It only opens pull requests, and
  each one must clear the existing CI gates to merge. Gems whose current pins are
  required to keep Ruby >= 1.9.3 support (`rubocop`, `mocha`, `pry`, `racc`,
  `redcarpet`, `rdoc`) are excluded from routine-bump groups on purpose.
- **Vulnerability disclosure policy**: added `SECURITY.md` with the supported
  version matrix, private reporting instructions, response targets, scope
  boundaries, and the hardening guidance most relevant to running an agent.
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

- **CI moved to GitHub Actions**: added `.github/workflows/ci.yml` with six named
  jobs (`fresh-install`, `test`, `coverage`, `lint`, `dependency-audit`,
  `secret-scan`). The hosted Travis CI service no longer builds open-source
  repositories, which meant the gates described in `.travis.yml` were not
  actually being enforced. Ruby is supplied by a pinned `ruby:2.3` container
  rather than `actions/setup-ruby`, because the committed `Gemfile.lock` does
  not resolve on a modern runtime; Bundler is pinned to 2.1.4 to match
  `BUNDLED WITH`, and `BUNDLE_FROZEN` is set so drift is reported instead of
  silently rewriting the lockfile. A new `fresh-install` job resolves the
  lockfile with no bundler cache and runs a smoke spec, which catches toolchain
  drift early. `.travis.yml` and `appveyor.yml` are kept for reference.
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
- README build badge repointed from the retired Travis CI project to the GitHub
  Actions `ci` and `security` workflows.

### Added

- `.github/workflows/ci.yml`, `.github/workflows/security.yml`,
  `.github/dependabot.yml`.
- `SECURITY.md`.
- `spec/unit/util/log/structured_format_spec.rb` covering the `log_format`
  setting, structured console and file output, the preserved JSON-array
  behaviour, and log file/directory permissions.
- `CHANGELOG.md` (this file).
- `util/ci/secret_scan.rb`.

## [4.5.0] - 2016-05-12

- Puppet 4.5.0 release. See the upstream Puppet release notes for the full
  list of features and fixes in this version.