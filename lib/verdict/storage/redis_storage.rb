module Verdict
  module Storage
    class RedisStorage < BaseStorage
      attr_accessor :redis, :key_prefix

      def initialize(redis = nil, options = {})
        @redis = redis
        @key_prefix = options[:key_prefix] || 'experiments/'
      end

      def get(scope, key)
        redis.hget("#{@key_prefix}#{scope}", key)
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def set(scope, key, value)
        redis.hset("#{@key_prefix}#{scope}", key, value)
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def remove(scope, key)
        redis.hdel("#{@key_prefix}#{scope}", key)
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      private

      def generate_scope_key(scope)
        "#{@key_prefix}#{scope}"
      end
    end
  end
end
