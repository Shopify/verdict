require 'logger'

module Experiments
  extend self

  attr_accessor :default_logger, :directory

  def [](handle)
    Experiments.repository[handle.to_s]
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
  class InvalidSubject < Experiments::Error; end
  class EmptySubjectIdentifier < Experiments::Error; end
  class StorageError < Experiments::Error; end

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
require "experiments/conversion"
require "experiments/segmenter"
require "experiments/storage"
require "experiments/event_logger"

Experiments.default_logger ||= Logger.new("/dev/null")
Experiments.directory = nil
