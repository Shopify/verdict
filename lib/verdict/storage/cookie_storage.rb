# frozen_string_literal: true

module Verdict
  module Storage
    # CookieStorage, unlike other Verdict storage classes, is distributed and stored on the client.
    # Because cookies are opaque to users, we obsfucate information about the test such as the
    # human readable names for the experiment or assignment group. This means this class assumes
    # that `name` will be an obsfucated value, or one that we comfortable being "public".
    class CookieStorage < BaseStorage
      DEFAULT_COOKIE_LIFESPAN_SECONDS = 15778476 # 6 months

      attr_accessor :cookies
      attr_reader :cookie_lifespan

      def initialize(cookies: {}, cookie_lifespan: DEFAULT_COOKIE_LIFESPAN_SECONDS)
        @cookies = cookies
        @cookie_lifespan = cookie_lifespan
      end

      def store_assignment(assignment)
        hash = { group: assignment.group.name, created_at: assignment.created_at.strftime('%FT%TZ') }
        set("verdict_#{assignment.experiment.name}", nil, JSON.dump(hash))
      end

      def retrieve_assignment(experiment, subject)
        if (value = get("verdict_#{experiment.name}", nil))
          hash = parse_cookie_value(value)
          group = experiment.groups.values.find { |g| g.name == hash['group'] }

          if group.nil?
            experiment.remove_subject_assignment(subject)
            return nil
          end

          experiment.subject_assignment(subject, group, Time.xmlschema(hash['created_at']))
        end
      end

      def remove_assignment(experiment, _subject)
        remove("verdict_#{experiment.name}", nil)
      end

      def retrieve_start_timestamp(_experiment)
        nil
      end

      def store_start_timestamp(_experiment, _timestamp)
        true
      end

      protected

      def get(scope, _key)
        cookies[scope]
      end

      def set(scope, _key, value)
        cookies[scope] = {
          value: value,
          expires: Time.now.utc.advance(seconds: cookie_lifespan),
        }
      end

      def remove(scope, _key)
        cookies.delete(scope)
      end

      private

      def parse_cookie_value(value)
        value = value[:value] if value.is_a?(Hash)

        JSON.parse(value)
      rescue
        {}
      end
    end
  end
end
