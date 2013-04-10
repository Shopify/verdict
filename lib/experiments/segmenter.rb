require 'digest/md5'

module Experiments::Segmenter

  class Base

    attr_reader :experiment, :segments

    def initialize(experiment)
      @experiment = experiment
      @segments = {}
    end

    def verify!
    end

    def segment(identifier, subject, context)
      raise NotImplementedError
    end
  end

  class StaticPercentage < Base
    def initialize(experiment)
      super
      @total_percentage_segmented = 0
    end

    def verify!
      raise SegmentationError, "Should segment exactly 100% of the cases, but segments add up to #{@total_percentage_segmented}%." if @total_percentage_segmented != 100
    end

    def percentage(n, label)
      n = n.to_i
      @segments[label] = @total_percentage_segmented ... (@total_percentage_segmented + n)
      @total_percentage_segmented += n
    end

    def half(label)
      percentage(50, label)
    end

    def rest(label)
      percentage(100 - @total_percentage_segmented, label)
    end

    def segment(identifier, subject, context)
      percentile = Digest::MD5.hexdigest("#{@experiment.name}#{identifier}").to_i(16) % 100
      segment_label, _ = segments.find { |_, percentile_range| percentile_range.include?(percentile) }
      raise "Could not get segment for subject #{identifier.inspect}!" unless segment_label
      segment_label
    end

  end

  class SegmentationError < Experiments::Error; end
end
