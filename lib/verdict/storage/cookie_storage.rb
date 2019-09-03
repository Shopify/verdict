# frozen_string_literal: true

module Verdict
  module Storage
    # CookieStorage, unlike other Verdict storage classes, is distributed and stored on the client.
    # Because cookies are opaque to users, we obsfucate information about the test such as the
    # human readable names for the experiment or assignment group. This means this class assumes
    # that `name` will be an obsfucated value, or one that we comfortable being "public".
    class CookieStorage < BaseStorage
      DEFAULT_COOKIE_LIFESPAN_SECONDS = 15778476 # 6 months
      KEY = :assignment

      attr_accessor :cookies
      attr_reader :cookie_lifespan

      def initialize(cookie_lifespan: DEFAULT_COOKIE_LIFESPAN_SECONDS)
        @cookies = nil
        @cookie_lifespan = cookie_lifespan
      end

      def store_assignment(assignment)
        data = {
          group: digest_of(assignment.group.to_s),
          created_at: assignment.created_at.strftime('%FT%TZ')
        }

        set(assignment.experiment.handle.to_s, KEY, JSON.dump(data))
      end

      def retrieve_assignment(experiment, subject)
        if (value = get(experiment.handle.to_s, KEY))
          data = parse_cookie_value(value)
          group = find_group_by_digest(experiment, data['group'])

          if group.nil?
            experiment.remove_subject_assignment(subject)
            return nil
          end

          experiment.subject_assignment(subject, group, Time.xmlschema(data['created_at']))
        end
      end

      def remove_assignment(experiment, _subject)
        remove(experiment.handle.to_s, KEY)
      end

      def retrieve_start_timestamp(_experiment)
        nil
      end

      def store_start_timestamp(_experiment, _timestamp)
        raise NotImplementedError
      end

      protected

      def get(scope, key)
        ensure_cookies_is_set
        cookies[scope_key(scope, key)]
      end

      def set(scope, key, value)
        ensure_cookies_is_set
        cookies[scope_key(scope, key)] = {
          value: value,
          expires: Time.now.utc.advance(seconds: cookie_lifespan),
        }
      end

      def remove(scope, key)
        ensure_cookies_is_set
        cookies.delete(scope_key(scope, key))
      end

      private

      def ensure_cookies_is_set
        raise Verdict::StorageError, 'cookies must be an instance of ActionDispatch::Cookies::CookieJar' if cookies.nil?
      end

      def digest_of(value)
        Digest::MD5.hexdigest(value)
      end

      def find_group_by_digest(experiment, digest)
        experiment.groups.values.find do |group|
          digest_of(group.to_s) == digest
        end
      end

      def parse_cookie_value(value)
        value = value[:value] if value.is_a?(Hash)

        JSON.parse(value)
      rescue
        {}
      end

      def scope_key(scope, key)
        "#{digest_of(scope)}_#{key}"
      end
    end
  end
end
