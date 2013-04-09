require 'logger'

module Experiments
  extend self

  attr_accessor :logger

  class Error < StandardError; end
end

require "experiments/version"
require "experiments/railtie" if defined?(Rails)

require "experiments/experiment"
require "experiments/segmenter"
require "experiments/subject_store"

Experiments.logger ||= Logger.new("/dev/null")
