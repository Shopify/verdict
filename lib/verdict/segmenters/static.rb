module Verdict
  module Segmenters
    class StaticSegmenter < BaseSegmenter

      def register_group(handle, subject_identifiers)
        Group.new(experiment, handle, subject_identifiers)
      end

      def assign(identifier, subject, context)
        groups.values.find { |group| group.subject_identifiers.include?(identifier) }
      end

      class Group < Verdict::Group
        attr_reader :subject_identifiers

        def initialize(experiment, handle, subject_identifiers)
          super(experiment, handle)
          @subject_identifiers = subject_identifiers
        end

        def as_json(options = {})
          super(options).merge(subject_identifiers: subject_identifiers)
        end
      end
    end
  end
end
