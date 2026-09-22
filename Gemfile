source ENV['GEM_SOURCE'] || "https://rubygems.org"

def location_for(place, fake_version = nil)
  if place =~ /^(git[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

# C Ruby (MRI) or Rubinius, but NOT Windows
platforms :ruby do
  # pry is pinned to the 0.10.4 release: newer releases pull in `reline`, which
  # requires Ruby >= 2.6 and is therefore incompatible with the Ruby versions
  # this project supports (>= 1.9.3).
  gem 'pry', '~> 0.10.4', :group => :development
  gem 'yard', :group => :development
  gem 'redcarpet', '~> 2.0', :group => :development
  gem "racc", "1.4.9", :group => :development

  # To enable the augeas feature, use this gem.
  # Note that it is a native gem, so the augeas headers/libs
  # are neeed.
  #gem 'ruby-augeas', :group => :development
end

gem "puppet", :path => File.dirname(__FILE__), :require => false
gem "facter", *location_for(ENV['FACTER_LOCATION'] || ['> 2.0', '< 4'])
gem "hiera", *location_for(ENV['HIERA_LOCATION'] || ['>= 2.0', '< 4'])
gem "rake", "10.1.1", :require => false

group(:development, :test) do
  gem "rspec", "~> 3.1", :require => false
  gem "rspec-its", "~> 1.1", :require => false
  gem "rspec-collection_matchers", "~> 1.1", :require => false
  gem "rspec-legacy_formatters", "~> 1.0", :require => false

  # Mocha is not compatible across minor version changes; because of this only
  # versions matching ~> 0.10.5 are supported. All other versions are unsupported
  # and can be expected to fail.
  gem "mocha", "~> 0.10.5", :require => false

  gem "yarjuf", "~> 2.0"

  # json-schema does not support windows, so omit it from the platforms list
  # json-schema uses multi_json, but chokes with multi_json 1.7.9, so prefer 1.7.7
  gem "multi_json", "1.7.7", :require => false, :platforms => [:ruby, :jruby]
  gem "json-schema", "2.1.1", :require => false, :platforms => [:ruby, :jruby]

  gem "rubocop", "~> 0.39.0", :platforms => [:ruby]

  gem 'rdoc', "~> 4.1", :platforms => [:ruby]

  gem 'webmock', '~> 1.24'
  gem 'vcr', '~> 2.9'

  # Code coverage measurement and enforcement. SimpleCov is only activated when
  # the COVERAGE environment variable is set (see spec/spec_helper.rb), so it
  # does not slow down ordinary test runs.
  gem "simplecov", "~> 0.11.0", :require => false

  # The following pins constrain transitive dependencies to versions that are
  # compatible with the Ruby versions this project supports (>= 1.9.3). Newer
  # releases of these gems require Ruby >= 2.4 and would break `bundle install`
  # on the supported runtimes.
  gem "crack", ">= 0.4.3", "< 0.4.5", :require => false  # webmock -> crack (0.4.5+ pulls rexml, needs Ruby >= 2.5)
  gem "addressable", "~> 2.4.0", :require => false       # webmock -> addressable
  gem "builder", "~> 3.2.0", :require => false           # yarjuf -> builder

  # Dependency vulnerability audit (run in CI as `bundle exec bundle-audit
  # check --update`). Placed in the test group so CI (which installs with
  # `--without development extra`) can run the audit gate.
  gem "bundler-audit", "~> 0.6.1", :require => false
end

group(:development) do
  if RUBY_PLATFORM != 'java'
    gem 'ruby-prof', :require => false
  end
end

group(:extra) do
  gem "rack", "~> 1.4", :require => false
  gem "net-ssh", '~> 2.1', :require => false
  gem "puppetlabs_spec_helper", :require => false
  gem "tzinfo", :require => false
  gem "msgpack", :require => false

  # puppetlabs_spec_helper pulls these in unconstrained; pin to versions that
  # support the Ruby versions this project targets (>= 1.9.3).
  gem "rspec-puppet", "~> 2.4.0", :require => false
  gem "puppet-lint", "~> 2.3.0", :require => false
end

require 'yaml'
data = YAML.load_file(File.join(File.dirname(__FILE__), 'ext', 'project_data.yaml'))
bundle_platforms = data['bundle_platforms']
x64_platform = Gem::Platform.local.cpu == 'x64'
data['gem_platform_dependencies'].each_pair do |gem_platform, info|
  next if gem_platform == 'x86-mingw32' && x64_platform
  next if gem_platform == 'x64-mingw32' && !x64_platform
  if bundle_deps = info['gem_runtime_dependencies']
    bundle_platform = bundle_platforms[gem_platform] or raise "Missing bundle_platform"
    platform(bundle_platform.intern) do
      bundle_deps.each_pair do |name, version|
        gem(name, version, :require => false)
      end
    end
  end
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end

# vim:filetype=ruby
