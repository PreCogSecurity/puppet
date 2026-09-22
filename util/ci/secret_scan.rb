#!/usr/bin/env ruby
# encoding: utf-8
#
# secret_scan.rb - lightweight secret scanner for CI.
#
# Scans the repository tree for high-signal credential patterns (cloud access
# keys, private key material, API tokens) and exits non-zero when a match is
# found so that CI can gate merges on secret hygiene.
#
# Design goals:
#   * Pure Ruby stdlib - runs anywhere Ruby runs, no gem installs.
#   * Conservative patterns - high signal, low false-positive rate. The
#     scanner deliberately does NOT flag generic `password = "..."` lines,
#     which are ubiquitous and legitimate in configuration-management code.
#   * Deterministic - walks the working tree so it also catches files that
#     would be committed for the first time.
#
# Usage:
#   ruby util/ci/secret_scan.rb
#
# Exit codes:
#   0 - no secrets found
#   1 - one or more potential secrets found (CI failure)
#
# Excluded paths:
#   .git, spec/, acceptance/, lib/puppet/vendor/, yardoc/, man/, docs/,
#   benchmarks/ - test fixtures, vendored third-party code, and generated
#   documentation are out of scope for repository secret hygiene.

require 'find'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

EXCLUDED_DIRS = %w[
  .git
  spec
  acceptance
  vendor
  yardoc
  man
  docs
  benchmarks
].freeze

# High-signal patterns. Each entry is [name, Regexp].
PATTERNS = [
  ['AWS Access Key ID',      /AKIA[0-9A-Z]{16}/],
  ['AWS Secret Access Key',  /(?i)aws[_-]?secret[_-]?access[_-]?key\s*[:=]\s*["'][A-Za-z0-9\/+=]{40}["']/],
  ['Private key block',      /-----BEGIN (?:RSA|EC|DSA|OPENSSH|PGP|ENCRYPTED) PRIVATE KEY-----/],
  ['GitHub token',           /\bgh[pousr]_[A-Za-z0-9]{36,}\b/],
  ['GitHub fine-grained PAT',/\bgithub_pat_[A-Za-z0-9_]{22,}\b/],
  ['Slack token',            /\bxox[baprs]-[A-Za-z0-9-]{10,}\b/],
  ['Stripe live key',        /\bsk_live_[A-Za-z0-9]{24,}\b/],
  ['Generic high-entropy secret', /(?i)\b(?:api[_-]?key|secret|token)\s*[:=]\s*["'][A-Za-z0-9\/+=_-]{32,}["']/],
].freeze

def excluded?(path)
  parts = path.split(File::SEPARATOR)
  parts.any? { |part| EXCLUDED_DIRS.include?(part) }
end

def text_file?(path)
  return false unless File.file?(path)
  return false if File.size(path) > 2 * 1024 * 1024 # skip large/binary blobs

  head = File.open(path, 'rb') { |f| f.read(4096) }
  return false if head.empty?
  return false if head.include?("\x00") # binary

  # Must be decodable as UTF-8 (with a lenient fallback for legacy encodings).
  head.force_encoding('UTF-8')
  head.valid_encoding? || head.force_encoding('ISO-8859-1').valid_encoding?
rescue SystemCallError
  false
end

def scan
  findings = []

  Find.find(ROOT) do |path|
    next if path == ROOT
    if File.directory?(path)
      Find.prune if excluded?(path)
      next
    end
    next unless text_file?(path)

    relative = path.sub(%r{\A#{Regexp.escape(ROOT)}#{File::SEPARATOR}}, '')
    line_no = 0
    File.open(path, 'r:UTF-8') do |fh|
      fh.each_line do |line|
        line_no += 1
        PATTERNS.each do |name, regex|
          if line =~ regex
            findings << "#{relative}:#{line_no} [#{name}]"
          end
        end
      end
    end
  end

  findings
end

findings = scan

if findings.empty?
  puts 'secret_scan: OK - no potential secrets found.'
  exit 0
else
  puts 'secret_scan: FAIL - potential secrets found:'
  findings.each { |f| puts "  #{f}" }
  puts "\nRemove the flagged material or move it to a secure secret store before committing."
  exit 1
end