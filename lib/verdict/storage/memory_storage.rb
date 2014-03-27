module Verdict
  module Storage
    class MemoryStorage
      attr_reader :assignments, :start_timestamps

      def initialize
        @assignments = {}
        @start_timestamps = {}
      end

      def store_assignment(assignment)
        @assignments[assignment.experiment.handle] ||= {}
        @assignments[assignment.experiment.handle][assignment.subject_identifier] = assignment.returning
        true
      end

      def retrieve_assignment(experiment, subject_identifier)
        experiment_store = @assignments[experiment.handle] || {}
        experiment_store[subject_identifier]
      end

      def remove_assignment(experiment, subject_identifier)
        @assignments[experiment.handle] ||= {}
        @assignments[experiment.handle].delete(subject_identifier)
      end

      def clear_experiment(experiment)
        @assignments.delete(experiment.handle)
      end

      def retrieve_start_timestamp(experiment)
        @start_timestamps[experiment.handle]
      end

      def store_start_timestamp(experiment, timestamp)
        @start_timestamps[experiment.handle] = timestamp
      end
    end
  end
end
