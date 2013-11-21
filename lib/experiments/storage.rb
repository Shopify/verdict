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
  end

  class MemoryStorage
    def initialize
      @store = {}
    end

    def store_assignment(assignment)
      @store[assignment.experiment.handle] ||= {}
      @store[assignment.experiment.handle][assignment.subject_identifier] = assignment.returning
      true
    end

    def retrieve_assignment(experiment, subject_identifier)
      experiment_store = @store[experiment.handle] || {}
      experiment_store[subject_identifier]
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
      if !redis.hset(generate_experiment_key(assignment.experiment), assignment.subject_identifier, JSON.dump(hash))
        raise Experiments::StorageError, "Assignment of subject #{assignment.subject_identifier} for experiment #{assignment.experiment.handle} already exists!"
      end
    rescue ::Redis::BaseError => e
      raise Experiments::StorageError, "Redis error: #{e.message}"
    end

    private

    def generate_experiment_key(experiment)
      "#{@key_prefix}#{experiment.handle}"
    end
  end
end
