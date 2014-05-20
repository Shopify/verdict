module Verdict
  module Storage
    class MockStorage < BaseStorage
      def set(scope, key, value)
        false
      end

      def get(scope, key)
        nil
      end

      def remove(scope, key)
      end
    end
  end
end
