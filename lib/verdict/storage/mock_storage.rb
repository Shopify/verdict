module Verdict
  module Storage
    class MockStorage < BaseStorage
      protected

      def get(scope, key)
        nil
      end

      def set(scope, key, value)
        false
      end

      def remove(scope, key)
      end
    end
  end
end
