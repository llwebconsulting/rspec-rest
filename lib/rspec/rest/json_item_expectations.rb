# frozen_string_literal: true

module RSpec
  module Rest
    module JsonItemExpectations
      def expect_json_item(index, expected = nil, &block)
        with_request_dump_on_failure do
          payload = json_array_payload
          item = payload.fetch(index)
          assert_json_value(item, expected, &block)
        rescue IndexError
          raise ::RSpec::Expectations::ExpectationNotMetError,
                "Index #{index.inspect} is out of bounds for JSON array of size #{payload.size}."
        end
      end

      def expect_json_first(expected = nil, &)
        expect_json_item(0, expected, &)
      end

      def expect_json_last(expected = nil, &block)
        with_request_dump_on_failure do
          payload = json_array_payload
          if payload.empty?
            raise ::RSpec::Expectations::ExpectationNotMetError,
                  "Cannot select last item from an empty JSON array."
          end

          assert_json_value(payload.last, expected, &block)
        end
      end

      private

      def json_array_payload
        payload = rest_response.json
        return payload if payload.is_a?(Array)

        raise ::RSpec::Expectations::ExpectationNotMetError,
              "Expected JSON payload to be an Array, got #{payload.class}."
      end

      def assert_json_value(value, expected = nil, &block)
        if block
          instance_exec(value, &block)
          return value
        end

        return value if expected.nil?

        if expected.respond_to?(:matches?)
          expect(value).to expected
        else
          expect(value).to eq(expected)
        end

        value
      end
    end
  end
end
