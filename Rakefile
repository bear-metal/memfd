require 'rubygems' unless defined?(Gem)
require 'rake' unless defined?(Rake)

require 'rake/extensiontask'
require 'rake/testtask'

Rake::ExtensionTask.new('memfd') do |ext|
  ext.name = 'memfd_ext'
  ext.ext_dir = 'ext/memfd'
  ext.lib_dir = "lib/memfd"
  CLEAN.include 'lib/**/memfd_ext.*'
end

desc 'Run memfd tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = "test/**/test_*.rb"
  t.verbose = true
  t.warning = true
end

namespace :debug do
  desc "Run the test suite under gdb"
  task :gdb do
    system "gdb --args ruby rake"
  end
end

task :bench do
  ruby 'bench/perf.rb'
end

task :bench => :compile
task :test => :compile
task :default => :test