# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'bulldog/version'

Gem::Specification.new do |s|
  s.name        = "bulldog"
  s.date        = Date.today.strftime('%Y-%m-%d')
  s.version     = Bulldog::VERSION.join('.')
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["George Ogata"]
  s.email       = ["george.ogata@gmail.com"]
  s.homepage    = "http://github.com/oggy/bulldog"
  s.summary     = "A heavy-duty paperclip.  File attachments for ActiveRecord."
  s.description = <<-EOS.gsub(/^ *\|/, '')
    |Provides file attachments for ActiveRecord objects. Designed for high-volume use.
  EOS

  s.files = Dir['CHANGELOG', 'LICENSE', 'README.*', 'Rakefile', '{doc,lib,rails,spec}/**/*']
  s.test_files = Dir["spec/**/*"]
  s.extra_rdoc_files = Dir['LICENSE', 'README.*']

  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = 'lib'
  s.rubygems_version = "1.3.5"

  s.required_rubygems_version = ">= 1.3.6"
  s.add_development_dependency 'rspec', '1.3.0'
  s.add_development_dependency 'rspec_outlines', '0.0.1'
  s.add_development_dependency 'mocha', '0.9.8'
end
