module Verdict
  module Storage
    class RedisStorage < BaseStorage
      PAGE_SIZE = 50

      attr_accessor :redis, :key_prefix

      def initialize(redis = nil, options = {})
        @redis = redis
        @key_prefix = options[:key_prefix] || 'experiments/'
      end

      def get(scope, key)
        redis.hget(scope_key(scope), key)
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def set(scope, key, value)
        redis.hset(scope_key(scope), key, value)
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def remove(scope, key)
        redis.hdel(scope_key(scope), key)
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def clear(scope)
        scrub(scope)
        redis.del(scope_key(scope))
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      private

      def scope_key(scope)
        "#{@key_prefix}#{scope}"
      end

      def scrub(scope, cursor: 0)
        cursor, results = redis.hscan(scope_key(scope), cursor, count: PAGE_SIZE)
        results.map(&:first).each do |key|
          remove(scope, key)
        end
        scrub(scope, cursor: cursor) unless cursor.to_i.zero?
      end
    end
  end
end
