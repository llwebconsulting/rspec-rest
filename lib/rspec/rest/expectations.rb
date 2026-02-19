# frozen_string_literal: true

module RSpec
  module Rest
    module Expectations
      def expect_status(code)
        expect(rest_response.status).to eq(code)
      end

      def expect_header(key, value_or_regex)
        actual = header_value_for(key)
        available_keys = rest_response.headers.keys.map(&:to_s).sort.join(", ")
        message = "Expected response header #{key.inspect} to be present. " \
                  "Available headers: [#{available_keys}]"
        raise ::RSpec::Expectations::ExpectationNotMetError, message if actual.nil?

        if value_or_regex.is_a?(Regexp)
          expect(actual).to match(value_or_regex)
        else
          expect(actual).to eq(value_or_regex)
        end
      end

      def expect_json(expected = nil, &block)
        parsed = rest_response.json

        if block
          instance_exec(parsed, &block)
          return parsed
        end

        return parsed if expected.nil?

        if expected.respond_to?(:matches?)
          expect(parsed).to expected
        else
          expect(parsed).to eq(expected)
        end

        parsed
      end

      def integer
        be_a(Integer)
      end

      def string
        be_a(String)
      end

      def boolean
        satisfy("be boolean") { |value| [true, false].include?(value) }
      end

      def array_of(matcher)
        all(matcher)
      end

      def hash_including(*)
        a_hash_including(*)
      end

      private

      def header_value_for(key)
        headers = rest_response.headers
        return headers[key] if headers.key?(key)

        key_str = key.to_s
        pair = headers.find do |header_key, _|
          header_key.to_s.casecmp(key_str).zero?
        end
        pair&.last
      end
    end
  end
end
