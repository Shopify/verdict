require "bundler/gem_tasks"

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.test_files = Dir['test/**/*_test.rb']
  t.ruby_opts << '-rubygems -rminitest/pride'
  t.libs << 'test'
  t.verbose = true
end

task default: :test
