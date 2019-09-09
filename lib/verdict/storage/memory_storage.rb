module Verdict
  module Storage
    class MemoryStorage < BaseStorage
      attr_reader :storage

      def initialize
        @storage = {}
      end

      protected

      def get(scope, key)
        @storage[scope] ||= {}
        @storage[scope][key]
      end

      def set(scope, key, value)
        @storage[scope] ||= {}
        @storage[scope][key] = value
      end

      def remove(scope, key)
        @storage[scope] ||= {}
        @storage[scope].delete(key)
      end
    end
  end
end
