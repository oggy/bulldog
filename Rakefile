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

Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib' << 'spec'
  t.spec_opts = ['--options', "\"#{PLUGIN_ROOT}/spec/spec.opts\""]
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
