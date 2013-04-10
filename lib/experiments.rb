require 'logger'

module Experiments
  extend self

  attr_accessor :logger, :repository

  def [](name)
    Experiments.repository[name.to_s]
  end

  class Error < StandardError; end
  class SegmentationError < Experiments::Error; end

  class ExperimentNameNotUnique < Experiments::Error
    attr_reader :name

    def initialize(name)
      @name = name
      super("Experiment #{name.inspect} is already defined!")
    end
  end
end

require "experiments/version"
require "experiments/railtie" if defined?(Rails)

require "experiments/experiment"
require "experiments/segmenter"
require "experiments/subject_store"

Experiments.logger ||= Logger.new("/dev/null")
Experiments.repository = {}
