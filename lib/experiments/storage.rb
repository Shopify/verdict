module Experiments::Storage

  class DummyStorage

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
      @assignments[assignment.experiment.handle] ||= {}
      @assignments[assignment.experiment.handle].delete(subject_identifier)
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

  class RedisStorage

    attr_accessor :redis, :key_prefix

    def initialize(redis = nil, options = {})
      @redis = redis
      @key_prefix = options[:key_prefix] || 'experiments/'
    end

    def retrieve_assignment(experiment, subject_identifier)
      if value = redis.hget(generate_experiment_key(experiment), subject_identifier)
        experiment.subject_assignment(subject_identifier, experiment.group(JSON.parse(value)['group']))
      end
    rescue ::Redis::BaseError => e
      raise Experiments::StorageError, "Redis error: #{e.message}"
    end

    def store_assignment(assignment)
      hash = { group: assignment.handle, created_at: Time.now.utc }
      redis.hset(generate_experiment_key(assignment.experiment), assignment.subject_identifier, JSON.dump(hash))
    rescue ::Redis::BaseError => e
      raise Experiments::StorageError, "Redis error: #{e.message}"
    end

    def remove_assignment(experiment, subject_identifier)
      redis.hdel(generate_experiment_key(experiment), subject_identifier)
    end

    def clear_experiment(experiment)
      redis.del(generate_experiment_key(experiment))
      redis.del(generate_experiment_start_timestamp_key(experiment))
    end

    def retrieve_start_timestamp(experiment)
      if started_at = redis.get(generate_experiment_start_timestamp_key(experiment))
        DateTime.parse(started_at)
      end
    end

    def store_start_timestamp(experiment, timestamp)
      redis.setnx(generate_experiment_start_timestamp_key(experiment), timestamp.to_s)
    end


    private

    def generate_experiment_key(experiment)
      "#{@key_prefix}#{experiment.handle}"
    end

    def generate_experiment_start_timestamp_key(experiment)
      "#{@key_prefix}#{experiment.handle}/started_at"
    end
  end
end
