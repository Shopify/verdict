module Verdict
  module Segmenters
    class FixedPercentageSegmenter < BaseSegmenter

      def initialize(experiment)
        super
        @total_percentage_segmented = 0
      end

      def verify!
        raise Verdict::SegmentationError, "Should segment exactly 100% of the cases, but segments add up to #{@total_percentage_segmented}%." if @total_percentage_segmented != 100
      end

      def register_group(handle, size)
        percentage = size.kind_of?(Hash) && size[:percentage] ? size[:percentage] : size
        n = case percentage
          when :rest; 100 - @total_percentage_segmented
          when :half; 50
          when Integer; percentage
          else Integer(percentage)
        end

        group = Group.new(experiment, handle, @total_percentage_segmented ... (@total_percentage_segmented + n))
        @total_percentage_segmented += n
        return group
      end

      def assign(identifier, subject, context)
        percentile = Digest::MD5.hexdigest("#{@experiment.handle}#{identifier}").to_i(16) % 100
        groups.values.find { |group| group.percentile_range.include?(percentile) }
      end

      class Group < Verdict::Group

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

        def as_json(options = {})
          super(options).merge(percentage: percentage_size)
        end
      end
    end
  end
end
