require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'bundler/setup'
begin
  require 'rspec/core/rake_task'
rescue LoadError
  # RSpec gem is not installed
end

Bundler::GemHelper.install_tasks

desc 'Default: run unit tests.'
task :default => :test

desc 'Test assert_value.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

if defined?(RSpec)
  desc "Run the specs."
  RSpec::Core::RakeTask.new do |t|
    t.pattern = "test/**/*_spec.rb"
  end
end

desc 'Generate documentation for assert_value.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'assert_value'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
