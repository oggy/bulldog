require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

PLUGIN_ROOT = File.dirname(__FILE__)

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "bulldog"
    gem.summary = "A heavy-duty paperclip.  File attachments for ActiveRecord."
    gem.description = File.read("#{PLUGIN_ROOT}/DESCRIPTION.txt")
    gem.email = "george.ogata@gmail.com"
    gem.homepage = "http://github.com/oggy/bulldog"
    gem.authors = ["George Ogata"]
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "rspec_outlines"
    gem.add_development_dependency "mocha"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Bulldog #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Run all specs."
task :spec => ['check_dependencies', 'spec:unit', 'spec:integration']

namespace :spec do
  Spec::Rake::SpecTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
    t.libs << 'lib' << 'spec'
  end

  Spec::Rake::SpecTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
    t.libs << 'lib' << 'spec'
    t.spec_opts = ['--options', "\"#{PLUGIN_ROOT}/spec/spec.opts\""]
  end
end

desc "Run all specs in spec directory with RCov"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_opts = ['--options', "\"#{PLUGIN_ROOT}/spec/spec.opts\""]
  t.rcov = true
  t.rcov_opts = lambda do
    IO.readlines(File.dirname(__FILE__) + "/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
  end
end

task :default => :spec
