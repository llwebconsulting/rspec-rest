# frozen_string_literal: true

require_relative "formatters/request_dump"
require_relative "formatters/request_recorder"
require_relative "error_expectations"
require_relative "contract_expectations"
require_relative "header_expectations"
require_relative "json_item_expectations"
require_relative "json_selector"
require_relative "json_type_helpers"
require_relative "pagination_expectations"

module RSpec
  module Rest
    module Expectations
      include ContractExpectations
      include ErrorExpectations
      include HeaderExpectations
      include JsonItemExpectations
      include JsonTypeHelpers
      include PaginationExpectations

      def expect_status(code)
        with_request_dump_on_failure do
          expect(rest_response.status).to eq(code)
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

      def expect_json_at(selector, expected = nil, &block)
        with_request_dump_on_failure do
          selected = JsonSelector.extract(rest_response.json, selector)

          if block
            instance_exec(selected, &block)
            next selected
          end

          next selected if expected.nil?

          if expected.respond_to?(:matches?)
            expect(selected).to expected
          else
            expect(selected).to eq(expected)
          end

          selected
        end
      end

      private

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
