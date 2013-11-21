require "bundler/setup"
require "minitest/autorun"
require "minitest/pride"
require "mocha/setup"
require "experiments"
require "redis"

REDIS_HOST = ENV['REDIS_HOST'].nil? ? '127.0.0.1' : ENV['REDIS_HOST']
REDIS_PORT = (ENV['REDIS_PORT'].nil? ? '6379' : ENV['REDIS_PORT']).to_i
