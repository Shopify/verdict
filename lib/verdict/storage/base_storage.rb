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

      # Retrieves the start timestamp of the experiment
      def retrieve_ended(experiment)
        !!get(experiment.handle.to_s, 'ended')
      end

      # Stores the timestamp on which the experiment was started
      def store_ended(experiment)
        set(experiment.handle.to_s, 'ended', true)
      end

      # Retrieves a key in a given scope from storage.
      # - The scope and key are both provided as string.
      # - Should return a string value if the key is found in the scope, nil otherwise.
      # - Should raise Verdict::StorageError if anything goes wrong.
      def get(scope, key)
        raise NotImplementedError
      end

      # Retrieves a key in a given scope from storage.
      # - The scope, key, and value are all provided as string.
      # - Should return true if the item was successfully stored.
      # - Should raise Verdict::StorageError if anything goes wrong.
      def set(scope, key, value)
        raise NotImplementedError
      end

      # Retrieves a key in a given scope from storage.
      # - The scope and key are both provided as string.
      # - Should return true if the item was successfully removed from storage.
      # - Should raise Verdict::StorageError if anything goes wrong.
      def remove(scope, key)
        raise NotImplementedError
      end
    end
  end
end
