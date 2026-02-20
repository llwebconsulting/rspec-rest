# frozen_string_literal: true

require_relative "formatters/request_dump"
require_relative "formatters/request_recorder"

module RSpec
  module Rest
    module Expectations
      def expect_status(code)
        with_request_dump_on_failure do
          expect(rest_response.status).to eq(code)
        end
      end

      def expect_header(key, value_or_regex)
        with_request_dump_on_failure do
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
      end

      def expect_json(expected = nil, &block)
        with_request_dump_on_failure do
          parsed = rest_response.json

          if block
            instance_exec(parsed, &block)
            next parsed
          end

          next parsed if expected.nil?

          if expected.respond_to?(:matches?)
            expect(parsed).to expected
          else
            expect(parsed).to eq(expected)
          end

          parsed
        end
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

      def with_request_dump_on_failure
        yield
      rescue ::RSpec::Expectations::ExpectationNotMetError => e
        message = "#{e.message}\n\n#{request_dump}\n\nReproduce with:\n#{request_curl}"
        new_exception = e.exception(message)
        new_exception.set_backtrace(e.backtrace)
        raise new_exception
      end

      def request_dump
        Formatters::RequestDump.new(
          last_request: safe_last_request,
          response: safe_rest_response,
          redacted_headers: redacted_headers_for_dump
        ).format
      end

      def safe_last_request
        rest_session.last_request
      rescue StandardError
        nil
      end

      def safe_rest_response
        rest_response
      rescue MissingRequestContextError, StandardError
        nil
      end

      def redacted_headers_for_dump
        self.class.rest_config.redact_headers
      rescue StandardError
        nil
      end

      def request_curl
        Formatters::RequestRecorder.new(
          last_request: safe_last_request,
          redacted_headers: redacted_headers_for_dump
        ).to_curl
      end
    end
  end
end
