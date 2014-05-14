module Verdict
  module Segmenters
    class StoredPercentageSegmenter < BaseSegmenter

      def initialize(experiment)
        super
      end

      def register_group(handle, options = {})
        group = Group.new(self, handle, @total_percentage_segmented ... (@total_percentage_segmented + n))
        @total_percentage_segmented += n
        return group
      end

      def set_percentile_ranges
        groups.keys
      end

      def assign(identifier, subject, context)
        percentile = Digest::MD5.hexdigest("#{@experiment.handle}#{identifier}#{self.class.salt}").to_i(16) % 100
        groups.values.find { |group| group.percentile_range.include?(percentile) }
      end

      class Group < Verdict::Group

        attr_reader :segmenter, :options
        attr_accessor :percentile_range

        def initialize(segmenter, handle, options = {})
          super(segmenter.experiment, handle)
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

      class << self
        attr_accessor :salt
      end
    end
  end
end
