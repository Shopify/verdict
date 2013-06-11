require 'logger'

module Experiments
  extend self

  attr_accessor :logger, :directory, :default_experiment_class

  def [](name)
    Experiments.repository[name.to_s]
  end

  def define(*args, &block)
    Experiments.default_experiment_class.define(*args, &block)
  end

  def repository
    if @repository.nil?
      @repository = {}
      discovery
    end

    @repository
  end

  def discovery
    Dir[File.join(Experiments.directory, '**', '*.rb')].each { |f| require f } if @directory
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
require "experiments/group"
require "experiments/assignment"
require "experiments/segmenter"
require "experiments/storage"

Experiments.default_experiment_class = Experiments::Experiment
Experiments.logger ||= Logger.new("/dev/null")
Experiments.directory = nil
