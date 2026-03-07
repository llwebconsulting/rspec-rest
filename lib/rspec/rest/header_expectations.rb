# frozen_string_literal: true

module RSpec
  module Rest
    module HeaderExpectations
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
