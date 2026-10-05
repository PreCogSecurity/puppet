#! /usr/bin/env ruby
require 'spec_helper'
require 'json'
require 'stringio'
require 'time'

require 'puppet/util/log'

# Structured logging and log file permissions.
#
# Puppet's log output used to be human readable only, which left operators who
# ship logs onward to a SIEM maintaining brittle grok patterns and trying to
# regex a file path back out of free text. `log_format = json` emits newline
# delimited JSON instead: one self-describing object per line that a collector
# can tail line by line.
describe 'structured log output' do
  include PuppetSpec::Files

  let(:console) { Puppet::Util::Log.desttypes[:console] }
  let(:file_dest) { Puppet::Util::Log.desttypes[:file] }

  before :each do
    @original_format = Puppet[:log_format]
    @original_color = Puppet[:color]
  end

  after :each do
    Puppet[:log_format] = @original_format
    Puppet[:color] = @original_color
  end

  # Capture a stream by rebinding the global rather than using an RSpec output
  # matcher, so this spec does not depend on any particular rspec version.
  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    begin
      yield
      $stdout.string
    ensure
      $stdout = original
    end
  end

  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    begin
      yield
      $stderr.string
    ensure
      $stderr = original
    end
  end

  def log_message(overrides = {})
    Puppet::Util::Log.new(
      { :level => :notice, :message => "don't panic", :source => "a hitchhiker" }.merge(overrides)
    )
  end

  describe 'the :log_format setting' do
    it "defaults to human readable output so existing behaviour is unchanged" do
      expect(Puppet[:log_format]).to eq('plain')
    end

    it "accepts the structured format" do
      Puppet[:log_format] = 'json'

      expect(Puppet[:log_format]).to eq('json')
    end

    # Enum settings are validated when the value is read, so a bad value has to
    # surface rather than quietly degrade to output no collector can parse.
    it "rejects a value outside the allowed set" do
      Puppet[:log_format] = 'yaml'

      expect { Puppet[:log_format] }.
        to raise_error(Puppet::Settings::ValidationError, /Invalid value 'yaml' for parameter log_format/)
    end
  end

  describe 'the console destination' do
    it "writes human readable output by default" do
      Puppet[:log_format] = 'plain'
      Puppet[:color] = false

      output = capture_stdout do
        console.new.handle(log_message)
      end

      expect(output).to eq("Notice: a hitchhiker: don't panic\n")
    end

    it "writes one self-describing JSON object per message when structured output is requested" do
      Puppet[:log_format] = 'json'
      # A caller asking for machine-readable output has opted out of colour;
      # this asserts the colour codes are genuinely absent, not just disabled.
      Puppet[:color] = true

      output = capture_stdout do
        console.new.handle(log_message)
      end

      expect(output.lines.size).to eq(1)

      parsed = JSON.parse(output)
      expect(parsed['level']).to eq('notice')
      expect(parsed['message']).to eq("don't panic")
      expect(parsed['source']).to eq('a hitchhiker')
      expect(Time.parse(parsed['time'])).to be >= (Time.now - 10)
    end

    it "never wraps a colour escape inside structured output" do
      Puppet[:log_format] = 'json'
      Puppet[:color] = true

      output = capture_stdout do
        console.new.handle(log_message)
      end

      expect(output).to_not match(/\e\[/)
    end

    it "keeps routing structured output by severity" do
      Puppet[:log_format] = 'json'

      err_output = capture_stderr do
        console.new.handle(log_message(:level => :err))
      end

      expect(JSON.parse(err_output)['level']).to eq('err')
    end

    it "keeps the tags it was given" do
      Puppet[:log_format] = 'json'

      output = capture_stdout do
        console.new.handle(log_message(:tags => ['file', 'resource']))
      end

      expect(JSON.parse(output)['tags']).to eq(['file', 'resource'])
    end
  end

  describe 'the file destination' do
    it "writes human readable output by default" do
      Puppet[:log_format] = 'plain'
      path = tmpfile('plain.log')

      dest = file_dest.new(path)
      dest.handle(log_message)
      dest.close

      expect(File.read(path)).to match(/a hitchhiker \(notice\): don't panic$/)
    end

    it "writes newline delimited JSON when structured output is requested" do
      Puppet[:log_format] = 'json'
      path = tmpfile('structured.log')

      dest = file_dest.new(path)
      dest.handle(log_message)
      dest.handle(log_message(:message => 'still panicking'))
      dest.close

      lines = File.readlines(path).map { |line| line.chomp }
      expect(lines.size).to eq(2)

      # Each line must parse on its own. That independence is the entire point
      # of newline delimited JSON and it is what a collector does as it tails the
      # file; a truncated trailing write is lost, not the whole document.
      parsed = lines.map { |line| JSON.parse(line) }

      expect(parsed.map { |entry| entry['message'] }).
        to eq(["don't panic", "still panicking"])
    end

    it "carries the structured fields a collector filters on" do
      Puppet[:log_format] = 'json'
      path = tmpfile('fields.log')

      dest = file_dest.new(path)
      dest.handle(log_message)
      dest.close

      parsed = JSON.parse(File.read(path))
      expect(parsed['level']).to eq('notice')
      expect(parsed['source']).to eq('a hitchhiker')
      expect(parsed['tags']).to eq(['notice'])
      expect(parsed).to have_key('time')
    end

    # Operators with existing JSON log consumers must not have their pipeline
    # broken by the introduction of the new setting.
    it "leaves the historical JSON-array format for a .json logfile untouched" do
      Puppet[:log_format] = 'plain'
      path = File.join(tmpdir('array'), 'puppet.log.json')

      dest = file_dest.new(path)
      dest.handle(log_message)
      dest.close

      contents = File.read(path)
      expect(contents).to match(/\A\[/)
      expect(contents).to match(/"message":"don't panic"/)
    end
  end

  describe 'log file permissions', :if => Puppet.features.posix? do
    it "does not create a world readable log file" do
      Puppet[:log_format] = 'plain'
      path = File.join(tmpdir('mode_file'), 'puppet.log')

      file_dest.new(path).close

      # Without an explicit mode the file inherits the process umask, which on a
      # stock configuration means 0644. Puppet logs record node names, managed
      # resource contents and, at debug level, applied parameter values, so no
      # access for group or other is the requirement.
      expect(File.stat(path).mode & 0077).to eq(0)
    end

    it "does not create a world traversable log directory" do
      Puppet[:log_format] = 'plain'
      root = tmpdir('mode_dir')
      nested = File.join(root, 'nested', 'log')
      path = File.join(nested, 'puppet.log')

      file_dest.new(path).close

      expect(File.stat(nested).mode & 0077).to eq(0)
    end
  end
end
