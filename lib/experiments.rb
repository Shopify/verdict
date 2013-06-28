require 'logger'

module Experiments
  extend self

  attr_accessor :logger, :directory, :default_experiment_class

  def [](handle)
    Experiments.repository[handle.to_s]
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
  class EmptySubjectIdentifier < Experiments::Error; end

  class ExperimentHandleNotUnique < Experiments::Error
    attr_reader :handle

    def initialize(handle)
      @handle = handle
      super("Another experiment with handle #{handle.inspect} is already defined!")
    end
  end
end

require "experiments/version"
require "experiments/railtie" if defined?(Rails)

require "experiments/metadata"
require "experiments/experiment"
require "experiments/group"
require "experiments/assignment"
require "experiments/segmenter"
require "experiments/storage"

Experiments.default_experiment_class = Experiments::Experiment
Experiments.logger ||= Logger.new("/dev/null")
Experiments.directory = nil
