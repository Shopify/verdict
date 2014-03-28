module Verdict
  module Segmenters
    class RandomPercentageSegmenter < FixedPercentageSegmenter

      attr_accessor :random

      def initialize(*args)
        super
        @random = Random.new
      end

      def assign(identifier, subject, context)
        percentile = @random.rand(100)
        groups.values.find { |group| group.percentile_range.include?(percentile) }
      end
    end
  end
end
