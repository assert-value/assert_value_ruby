require 'rake'
require 'rake/testtask'
begin
  require 'rdoc/task'
rescue LoadError
  # RDoc is not installed
end
begin
  require 'rspec/core/rake_task'
rescue LoadError
  # RSpec gem is not installed
end
require 'bundler/setup'

Bundler::GemHelper.install_tasks

desc 'Test assert_value.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

if defined?(RSpec)
  desc "Run the specs."
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "test/**/*_spec.rb"
  end
end

if defined?(RSpec) and RUBY_VERSION > '1.9.3'
  desc 'Default: run specs.'
  task :default => :spec
else
  desc 'Default: run unit tests.'
  task :default => :test
end

if defined?(Rake::RDocTask)
  desc 'Generate documentation for assert_value.'
  Rake::RDocTask.new(:rdoc) do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'assert_value'
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
end
