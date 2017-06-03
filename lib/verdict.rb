require 'logger'
require 'digest/md5'

module Verdict
  extend self

  attr_accessor :default_logger

  class Error < StandardError; end
  class SegmentationError < Verdict::Error; end
  class InvalidSubject < Verdict::Error; end
  class EmptySubjectIdentifier < Verdict::Error; end
  class StorageError < Verdict::Error; end
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
