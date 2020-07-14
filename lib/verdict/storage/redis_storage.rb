module Verdict
  module Storage
    class RedisStorage < BaseStorage
      PAGE_SIZE = 50

      attr_accessor :redis, :key_prefix

      def initialize(redis = nil, options = {})
        @redis = redis
        redis.extend(ConnectionPoolLike) if !redis.nil? && !redis.respond_to?(:with)

        @key_prefix = options[:key_prefix] || 'experiments/'
      end

      protected

      module ConnectionPoolLike
        def with
          yield self
        end
      end

      def get(scope, key)
        redis.with do |r|
          r.hget(scope_key(scope), key)
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def set(scope, key, value)
        redis.with do |r|
          r.hset(scope_key(scope), key, value)
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def remove(scope, key)
        redis.with do |r|
          r.hdel(scope_key(scope), key)
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def clear(scope, options)
        scrub(scope)
        redis.with do |r|
          r.del(scope_key(scope))
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      private

      def scope_key(scope)
        "#{@key_prefix}#{scope}"
      end

      def scrub(scope, cursor: 0)
        cursor, results = redis.with do |r|
          r.hscan(scope_key(scope), cursor, count: PAGE_SIZE)
        end

        results.map(&:first).each do |key|
          remove(scope, key)
        end

        scrub(scope, cursor: cursor) unless cursor.to_i.zero?
      end
    end
  end
end
