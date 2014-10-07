module Verdict
  module Segmenters
    class ExperimentEndedSegementer < BaseSegmenter
      def initialize(segementer)
        super
        @groups = segementer.groups
      end
      def assign(identifier, subject, context)
        nil
      end
    end
  end
end
