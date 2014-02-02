module Verdict
  module Storage
    class MockStorage
      # Should store the assignments to allow quick lookups.
      # - Assignments should be unique on the combination of
      #   `assignment.experiment.handle` and `assignment.subject_identifier`.
      # - The main property to store is `group.handle`
      # - Should return true if stored successfully.
      def store_assignment(assignment)
        false
      end

      # Should do a fast lookup of an assignment of the subject for the given experiment.
      # - Should return nil if not found in store
      # - Should return an Assignment instance otherwise.
      def retrieve_assignment(experiment, subject_identifier)
        nil
      end

      # Should remove the subject from storage, so it will be reassigned later.
      def remove_assignment(experiment, subject_identifier)
      end

      # Should clear out the storage used for this experiment
      def clear_experiment(experiment)
      end

      # Retrieves the start timestamp of the experiment
      def retrieve_start_timestamp(experiment)
        nil
      end

      # Stores the timestamp on which the experiment was started
      def store_start_timestamp(experiment, timestamp)
      end
    end
  end
end
