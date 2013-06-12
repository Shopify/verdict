require 'digest/md5'

module Experiments::Segmenter

  class Base

    attr_reader :experiment, :groups

    def initialize(experiment)
      @experiment = experiment
      @groups = {}
    end

    def verify!
    end

    def group(identifier, subject, context)
      raise NotImplementedError
    end
  end

  class StaticPercentage < Base

    class Group < Experiments::Group

      attr_reader :percentile_range

      def initialize(experiment, handle, percentile_range)
        super(experiment, handle)
        @percentile_range = percentile_range
      end

      def percentage_size
        percentile_range.end - percentile_range.begin
      end

      def to_s
        "#{handle} (#{percentage_size}%)"
      end
    end

    def initialize(experiment)
      super
      @total_percentage_segmented = 0
    end

    def verify!
      raise Experiments::SegmentationError, "Should segment exactly 100% of the cases, but segments add up to #{@total_percentage_segmented}%." if @total_percentage_segmented != 100
    end

    def group(handle, size, &block)
      percentage = size.kind_of?(Hash) && size[:percentage] ? size[:percentage] : size
      n = case percentage
        when :rest; 100 - @total_percentage_segmented
        when :half; 50
        when Integer; percentage
        else Integer(percentage)
      end

      group = Group.new(experiment, handle, @total_percentage_segmented ... (@total_percentage_segmented + n))
      @groups[group.handle] = group
      @total_percentage_segmented += n
      block.call(group) if block_given?
      return group
    end

    def assign(identifier, subject, context)
      percentile = Digest::MD5.hexdigest("#{@experiment.handle}#{identifier}").to_i(16) % 100
      _, group = groups.find { |_, group| group.percentile_range.include?(percentile) }
      raise Experiments::SegmentationError, "Could not get segment for subject #{identifier.inspect}!" unless group
      group
    end
  end
end
