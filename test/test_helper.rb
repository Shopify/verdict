require "rails/all"
require 'minitest/autorun'
require "mocha"
require File.join(File.dirname(__FILE__), "..", "lib", "experiments")

Rails.logger = Logger.new("/dev/null")
