unless RUBY_ENGINE == 'rbx'
  require 'simplecov'
  SimpleCov.start do
    add_filter "/vendor/"
    add_filter "/test/"
  end
end

require "bundler/setup"
require "minitest/autorun"
require "minitest/pride"
require "mocha/setup"
require "timecop"
require "verdict"
require "redis"
require "rubystats"

REDIS_HOST = ENV['REDIS_HOST'].nil? ? '127.0.0.1' : ENV['REDIS_HOST']
REDIS_PORT = (ENV['REDIS_PORT'].nil? ? '6379' : ENV['REDIS_PORT']).to_i
