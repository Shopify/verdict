module Verdict
  module Storage
    class BaseStorage
      # Should store the assignments to allow quick lookups.
      # - Assignments should be unique on the combination of
      #   `assignment.experiment.handle` and `assignment.subject_identifier`.
      # - The main property to store is `group.handle`
      # - Should return true if stored successfully.
      def store_assignment(assignment)
        hash = { group: assignment.handle, created_at: assignment.created_at.strftime('%FT%TZ') }
        set(assignment.experiment.handle.to_s, "assignment_#{assignment.subject_identifier}", JSON.dump(hash))
      end

      # Should do a fast lookup of an assignment of the subject for the given experiment.
      # - Should return nil if not found in store
      # - Should return an Assignment instance otherwise.
      def retrieve_assignment(experiment, subject_identifier)
        if value = get(experiment.handle.to_s, "assignment_#{subject_identifier}")
          hash = JSON.parse(value)
          experiment.subject_assignment(
            subject_identifier,
            experiment.group(hash['group']),
            Time.xmlschema(hash['created_at'])
          )
        end
      end

      # Should remove the subject from storage, so it will be reassigned later.
      def remove_assignment(experiment, subject_identifier)
        remove(experiment.handle.to_s, "assignment_#{subject_identifier}")
      end

      # Retrieves the start timestamp of the experiment
      def retrieve_start_timestamp(experiment)
        if timestamp = get(experiment.handle.to_s, 'started_at')
          Time.parse(timestamp)
        end
      end

      # Stores the timestamp on which the experiment was started
      def store_start_timestamp(experiment, timestamp)
        set(experiment.handle.to_s, 'started_at', timestamp.utc.strftime('%FT%TZ'))
      end


      def get(scope, key)
        raise NotImplementedError
      end

      def set(scope, key, value)
        raise NotImplementedError
      end

      def remove(scope, key)
        raise NotImplementedError
      end
    end
  end
end
