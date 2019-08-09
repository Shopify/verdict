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

      def cleanup(scope)
        temp_scope = move_to_temp(scope)
        clear(temp_scope)
        redis.del(scope_key(temp_scope))
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      private

      def scope_key(scope)
        "#{@key_prefix}#{scope}"
      end

      def move_to_temp(scope)
        "temp:#{SecureRandom.uuid}".tap do |temp_scope|
          redis.rename(scope_key(scope), scope_key(temp_scope))
        end
      end

      def clear(scope, cursor: 0)
        cursor, results = redis.hscan(scope_key(scope), cursor, count: PAGE_SIZE)
        results.map(&:first).each do |key|
          remove(scope, key)
        end
        clear(scope, cursor: cursor) unless cursor.to_i.zero?
      end
    end
  end
end
