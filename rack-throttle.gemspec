#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rack-throttle'
  gem.homepage           = 'https://github.com/dryruby/rack-throttle'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'HTTP request rate limiter for Rack applications.'
  gem.description        = 'Rack middleware for rate-limiting incoming HTTP requests.'

  gem.authors            = ['Arto Bendiken']
  gem.email              = 'arto@bendiken.net'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w()
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.8.2'
  gem.requirements               = []

  gem.add_runtime_dependency     'bundler',   '>= 1.0.0'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'timecop'

  gem.add_runtime_dependency     'rack',      '>= 1.0.0'

  gem.post_install_message       = <<-POST
rack-throttle is no longer under active development. Please consider
using https://github.com/kickstarter/rack-attack instead as it is
more feature rich & well supported.
  POST
end
