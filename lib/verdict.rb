require 'logger'
require 'digest/md5'

module Verdict
  extend self

  attr_accessor :default_logger, :directory

  def [](handle)
    Verdict.repository[handle.to_s]
  end

  def repository
    discovery if @repository.nil?
    @repository
  end

  def discovery
    @repository = {}
    Dir[File.join(Verdict.directory, '**', '*.rb')].each { |f| load f } if @directory
  end

  def clear_repository_cache
    @repository = nil
  end

  class Error < StandardError; end
  class SegmentationError < Verdict::Error; end
  class InvalidSubject < Verdict::Error; end
  class EmptySubjectIdentifier < Verdict::Error; end
  class StorageError < Verdict::Error; end

  class ExperimentHandleNotUnique < Verdict::Error
    attr_reader :handle

    def initialize(handle)
      @handle = handle
      super("Another experiment with handle #{handle.inspect} is already defined!")
    end
  end
end

require "verdict/version"
require "verdict/railtie" if defined?(Rails::Railtie)

require "verdict/metadata"
require "verdict/experiment"
require "verdict/group"
require "verdict/assignment"
require "verdict/conversion"
require "verdict/segmenters"
require "verdict/storage"
require "verdict/event_logger"

Verdict.default_logger ||= Logger.new("/dev/null")
Verdict.directory = nil
