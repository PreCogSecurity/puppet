# Puppet master container image (built from source).
#
# SECURITY NOTE: this image pins Ruby 2.3.8, the newest Ruby release this
# codebase supports (the code predates Ruby 2.4, which removed Fixnum/Bignum).
# Ruby 2.3 is end-of-life; the runtime MUST be upgraded in lockstep with a
# codebase modernization pass before this image is used in production.
FROM ruby:2.3.8

LABEL maintainer="PreCog Security" \
      description="Puppet configuration management master (from source)" \
      org.opencontainers.image.source="https://github.com/PreCogSecurity/puppet"

# Puppet 4.x default directory layout (overridable via puppet.conf).
ENV PUPPET_CODEDIR=/etc/puppetlabs/code \
    PUPPET_CONFDIR=/etc/puppetlabs/puppet \
    PUPPET_LOGDIR=/var/log/puppetlabs/puppet \
    PUPPET_RUNDIR=/var/run/puppetlabs

WORKDIR /app

# Install the bundler version the committed Gemfile.lock was generated with
# (BUNDLED WITH 2.1.4), so installs are reproducible.
RUN gem install bundler -v 2.1.4

# Install dependencies first so image rebuilds can leverage layer caching.
# The Gemfile reads ext/project_data.yaml at evaluation time, so ext/ and the
# gemspec's version file must be present before `bundle install` runs.
COPY Gemfile Gemfile.lock .gemspec ./
COPY ext ./ext
COPY lib/puppet/version.rb ./lib/puppet/version.rb
RUN bundle install --without development extra --jobs 4 --retry 3

# Copy the rest of the source tree (see .dockerignore).
COPY . .

# The puppet master (server) listens on 8140/tcp (SSL).
EXPOSE 8140

# The master auto-generates its CA and server certificates on first run.
CMD ["bundle", "exec", "puppet", "master", "--verbose"]