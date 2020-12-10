module Verdict
  module Storage
    class RedisStorage < BaseStorage
      PAGE_SIZE = 50

      attr_accessor :redis, :key_prefix

      def initialize(redis = nil, options = {})
        if !redis.nil? && !redis.respond_to?(:with)
          @redis = ConnectionPoolLike.new(redis)
        else
          @redis = redis
        end

        @key_prefix = options[:key_prefix] || 'experiments/'
      end

      protected

      class ConnectionPoolLike
        def initialize(redis)
          @redis = redis
        end

        def with
          yield @redis
        end
      end

      def get(scope, key)
        redis.with do |conn|
          conn.hget(scope_key(scope), key)
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def set(scope, key, value)
        redis.with do |conn|
          conn.hset(scope_key(scope), key, value)
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def remove(scope, key)
        redis.with do |conn|
          conn.hdel(scope_key(scope), key)
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      def clear(scope, options)
        scrub(scope)
        redis.with do |conn|
          conn.del(scope_key(scope))
        end
      rescue ::Redis::BaseError => e
        raise Verdict::StorageError, "Redis error: #{e.message}"
      end

      private

      def scope_key(scope)
        "#{@key_prefix}#{scope}"
      end

      def scrub(scope, cursor: 0)
        loop do
          cursor, results = redis.with do |conn|
            conn.hscan(scope_key(scope), cursor, count: PAGE_SIZE)
          end

          results.map(&:first).each do |key|
            remove(scope, key)
          end

          break if cursor.to_i.zero?
        end
      end
    end
  end
end
