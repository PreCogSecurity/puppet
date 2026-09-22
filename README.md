Puppet
======

[![Build Status](https://travis-ci.org/puppetlabs/puppet.png?branch=master)](https://travis-ci.org/puppetlabs/puppet)
[![Inline docs](https://inch-ci.org/github/puppetlabs/puppet.png)](https://inch-ci.org/github/puppetlabs/puppet)

Puppet, an automated administrative engine for your Linux, Unix, and Windows systems, performs
administrative tasks (such as adding users, installing packages, and updating server
configurations) based on a centralized specification.

Documentation
-------------

Documentation for Puppet and related projects can be found online at the
[Puppet Docs site](https://docs.puppetlabs.com).

HTTP API
--------
[HTTP API Index](https://docs.puppetlabs.com/puppet/latest/reference/http_api/http_api_index.html)

Installation
------------

The best way to run Puppet is with [Puppet Enterprise](https://puppetlabs.com/puppet/puppet-enterprise),
which also includes orchestration features, a web console, and professional support.
[The PE documentation is available here.](https://docs.puppetlabs.com/pe/latest)

To install an open source release of Puppet,
[see the installation guide on the docs site.](http://docs.puppetlabs.com/puppet/latest/reference/install_pre.html)

If you need to run Puppet from source as a tester or developer,
[see the running from source guide on the docs site.](https://docs.puppetlabs.com/guides/from_source.html)

Developing and Contributing
------

We'd love to get contributions from you! For a quick guide to getting your
system setup for developing take a look at our [Quickstart
Guide](docs/quickstart.md). Once you are up and running, take a look at the
[Contribution Documents](CONTRIBUTING.md) to see how to get your changes merged
in.

For more complete docs on developing with puppet you can take a look at the
rest of the [developer documents](docs/index.md).

Running from source
-------------------

Prerequisites: Ruby >= 1.9.3 (Ruby 2.3.x recommended) and Bundler 2.1.x.

    gem install bundler -v 2.1.4
    bundle install --without development extra
    bundle exec puppet --version

The committed `Gemfile.lock` pins the exact dependency graph, so installs are
reproducible across machines and CI.

Running the test suite
----------------------

The full spec suite (unit and integration) is run with:

    bundle exec rspec spec

Static analysis and repository hygiene gates (also enforced in CI):

    bundle exec rake rubocop            # lint
    bundle exec rake commits            # commit message format
    bundle exec bundle-audit check --update   # dependency vulnerability audit
    bundle exec ruby util/ci/secret_scan.rb   # secret scanning

Code coverage is measured with SimpleCov and gated by a minimum threshold.
Enable it explicitly so ordinary test runs stay fast:

    COVERAGE=yes MINIMUM_COVERAGE=40 bundle exec rspec spec

Running with Docker
-------------------

A Dockerfile and docker-compose.yml are provided for one-command startup of
the Puppet master built from this source tree:

    docker compose up --build

The master listens on 8140/tcp, auto-generates its CA and server certificates
on first run, and serves the example manifests in `./examples` as the
production environment. See `.env.example` for the environment variables
Puppet and its build tooling honor.

Security
--------

- Dependency vulnerabilities are audited in CI with `bundler-audit`; the gate
  is intentionally strict and must be green before shipping.
- `util/ci/secret_scan.rb` scans the tree for credentials (cloud keys, private
  key material, API tokens) and fails CI on matches. Run it locally before
  pushing: `bundle exec ruby util/ci/secret_scan.rb`.
- Never commit secrets. Use a secret store (e.g. Hiera with eyaml, or a vault)
  for credentials that Puppet must manage.

License
-------

See [LICENSE](LICENSE) file.

Support
-------

Please log tickets and issues at our [JIRA tracker](https://tickets.puppetlabs.com).  A [mailing
list](https://groups.google.com/forum/?fromgroups#!forum/puppet-users) is
available for asking questions and getting help from others. In addition there
is an active #puppet channel on Freenode.

We use semantic version numbers for our releases, and recommend that users stay
as up-to-date as possible by upgrading to patch releases and minor releases as
they become available.

Bugfixes and ongoing development will occur in minor releases for the current
major version. Security fixes will be backported to a previous major version on
a best-effort basis, until the previous major version is no longer maintained.

For example: If a security vulnerability is discovered in Puppet 4.1.1, we
would fix it in the 4 series, most likely as 4.1.2. Maintainers would then make
a best effort to backport that fix onto the latest Puppet 3 release.

Long-term support, including security patches and bug fixes, is available for
commercial customers. Please see the following page for more details:

[Puppet Enterprise Support Lifecycle](https://puppetlabs.com/misc/puppet-enterprise-lifecycle)

Maintainers
-------

* Kylo Ginsberg, kylo@puppet.com, github:kylog, jira:kylo
* Henrik Lindberg, henrik.lindberg@puppet.com, github:hlindberg, jira:henrik.lindberg
