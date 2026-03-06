# frozen_string_literal: true

module RSpec
  module Rest
    module ErrorExpectations
      def expect_error(status:, message: nil, includes: nil, field: nil, key: "error")
        with_request_dump_on_failure do
          expect(rest_response.status).to eq(status)
          error_value = extract_error_value(key)
          expect_error_message!(error_value, message) if message
          expect_error_includes!(error_value, includes) if includes
          expect_error_field!(error_value, field) if field
          error_value
        end
      end

      private

      def extract_error_value(key)
        payload = rest_response.json
        error_value = payload[key]
        return error_value unless error_value.nil?

        raise ::RSpec::Expectations::ExpectationNotMetError,
              "Expected JSON response to include #{key.inspect} key."
      end

      def expect_error_message!(error_value, message)
        if error_value.is_a?(Array)
          expect(error_value).to include(message)
        else
          expect(error_value).to eq(message)
        end
      end

      def expect_error_includes!(error_value, includes)
        Array(includes).each do |expected_fragment|
          expect(error_text(error_value)).to include(expected_fragment.to_s)
        end
      end

      def expect_error_field!(error_value, field)
        expect(error_text(error_value)).to include(field.to_s)
      end

      def error_text(error_value)
        error_value.is_a?(Array) ? error_value.join(" ") : error_value.to_s
      end
    end
  end
end
