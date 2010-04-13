gem 'ritual'
require 'ritual'

require 'rake/rdoctask'
rdoc_task do |t|
  t.rdoc_dir = 'rdoc'
  t.title = "Bulldog #{version}"
  t.rdoc_files.include 'README*', 'lib/**/*.rb'
end

desc "Run all specs."
task :spec => ['spec:unit', 'spec:integration']

namespace :spec do
  spec_task :unit do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
    t.libs << 'lib' << 'spec'
  end

  spec_task :integration do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
    t.libs << 'lib' << 'spec'
  end
end

task :default => :spec
