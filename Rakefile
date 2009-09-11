require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

PLUGIN_ROOT = File.dirname(__FILE__)

desc 'Generate documentation for the bulldog plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Bulldog'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Run all specs."
task :spec => ['spec:unit', 'spec:integration']

namespace :spec do
  Spec::Rake::SpecTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
    t.libs << 'lib' << 'spec'
    t.spec_opts = ['--options', "\"#{PLUGIN_ROOT}/spec/spec.opts\""]
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
