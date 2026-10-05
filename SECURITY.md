# Security Policy

## Supported Versions

Security fixes are applied to the most recent minor release of the current major
version, and are backported to the previous major version on a best-effort
basis while it is still maintained. Older releases do not receive patches.

| Version | Supported          |
| ------- | ------------------ |
| 4.x     | :white_check_mark: |
| < 4.0   | :x:                |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for a security vulnerability.**

A public issue turns a vulnerability into an attack instruction, and gives
anyone reading it a head start on exploitation before a fix exists.

Instead, report it privately through GitHub's private vulnerability reporting:

1. Go to this repository's **Security** tab.
2. Select **Advisories** -> **Report a vulnerability**.
3. Include, where you have them:
   - the affected version or commit,
   - the configuration required to reproduce (this matters a great deal for
     Puppet: certificate trust settings, `certname`, `--test` mode, and which
     providers run),
   - the exact steps or manifest needed to reproduce,
   - the impact you observed.

If private advisory reporting is unavailable to you, contact
**security@precogsecurity.com** instead and ask for a private channel.

### What to expect

- **Acknowledgement**: within 3 business days.
- **Triage**: within 10 business days, with an assessment of severity and
  whether we consider it in scope.
- **Fix**: a remediation plan and target release. We will tell you when the fix
  ships and will credit you in the advisory unless you prefer otherwise.

Please give us a reasonable opportunity to ship a fix before disclosing. We ask
for 90 days, and we will not pursue legal action against researchers who follow
this policy in good faith.

## Scope

In scope:

- The Puppet engine in this repository (`lib/`, `api/`, `bin/`, `ext/`).
- The build and CI configuration (`.github/workflows/`, `Dockerfile`,
  `util/ci/`).
- The shipped container images.

Out of scope:

- Vulnerabilities in third-party gems. Those are reported to the gem's
  maintainer. Report them to us anyway and we will help route the report, but we
  cannot issue a fix for someone else's gem.
- Findings that require an already-compromised host, an already-compromised CA
  certificate, or root access on the agent.
- Denial of service through deliberately huge manifests authored by a party who
  already controls the catalog.
- Missing hardening guidance with no concrete exploit path.

## Defensive Hardening

The behaviours below are the ones most worth understanding before deploying.

- **Secrets do not belong in Puppet.** Hiera with a secrets backend such as
  eyaml or Vault keeps credentials out of the catalog, the agent's cache, and
  the logs. A `Puppet::Util::Log` message at debug level can echo a parameter
  value, so debug logging is not safe on a host you do not fully control.
- **Certificates are the trust anchor.** Do not run with
  `ssl_verify_client_cert` disabled on a production agent, and do not set
  `--test`/noop in an automated pipeline where a failed catalog would go
  unnoticed.
- **Puppet runs as root.** The agent needs root to manage system state. Treat
  the Puppet CA and every certificate signed by it as equivalent to root on
  every managed node.
- **Log files are not world readable.** They are created with mode `0640` in a
  `0750` directory. Keep it that way; do not relax it to make a log shipper
  happy without restricting the shipper some other way.
- **Audit the dependency graph.** CI runs `bundler-audit` on every build. A
  green audit is the evidence that no known advisory affects a locked gem.

## Automated Security Controls

| Control | Where | What it does |
| --- | --- | --- |
| Dependency vulnerability audit | `.github/workflows/ci.yml` (`dependency-audit`) | `bundle-audit check --update` fails the build on any advisory affecting `Gemfile.lock` |
| Dependency update proposals | `.github/dependabot.yml` | Opens reviewed PRs for outdated gems and stale Actions pins; nothing merges without CI |
| Dependency change review | `.github/workflows/security.yml` (`dependency-review`) | Blocks a PR that introduces a gem with a known advisory |
| Static analysis | `.github/workflows/security.yml` (`codeql`) | CodeQL Ruby semantic analysis on push, on PR, and weekly |
| Secret scanning | `util/ci/secret_scan.rb`, `gitleaks` | Fails the build on committed credentials |
| Test suite | `.github/workflows/ci.yml` (`test`, `coverage`) | Full RSpec suite; SimpleCov gate at `MINIMUM_COVERAGE` (default 40%) |

## Verifying the Controls Locally

None of these need credentials or network access beyond RubyGems:

    gem install bundler -v 2.1.4
    bundle install --without development extra

    bundle exec rspec spec                              # full suite
    bundle exec rake rubocop                            # lint
    bundle exec bundle-audit check --update             # advisory audit
    bundle exec ruby util/ci/secret_scan.rb             # secret scan
    COVERAGE=yes MINIMUM_COVERAGE=40 bundle exec rspec spec   # coverage gate
