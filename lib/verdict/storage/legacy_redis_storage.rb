module Verdict
  module Storage
    class LegacyRedisStorage
      attr_accessor :redis, :key_prefix

      def initialize(redis = nil, options = {})
        @redis = redis
        @key_prefix = options[:key_prefix] || 'experiments/'
      end

      def retrieve_assignment(experiment, subject_identifier)
        if value = redis.hget(generate_experiment_key(experiment), subject_identifier)
          hash = JSON.parse(value)
          experiment.subject_assignment(
            subject_identifier,
            experiment.group(hash['group']),
            DateTime.parse(hash['created_at']).to_time
          )
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def store_assignment(assignment)
        hash = { group: assignment.handle, created_at: assignment.created_at }
        redis.hset(generate_experiment_key(assignment.experiment), assignment.subject_identifier, JSON.dump(hash))
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def remove_assignment(experiment, subject_identifier)
        redis.hdel(generate_experiment_key(experiment), subject_identifier)
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def retrieve_start_timestamp(experiment)
        if started_at = redis.get(generate_experiment_start_timestamp_key(experiment))
          Experiments::ExperimentStartDate.store(experiment.handle.to_s, started_at.to_time)
          DateTime.parse(started_at).to_time
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def store_start_timestamp(experiment, timestamp)
        Experiments::ExperimentStartDate.store(experiment.handle.to_s, timestamp)
        redis.setnx(generate_experiment_start_timestamp_key(experiment), timestamp.to_s)
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
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
end
