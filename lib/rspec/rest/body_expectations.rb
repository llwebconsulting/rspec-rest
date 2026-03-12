# frozen_string_literal: true

module RSpec
  module Rest
    module BodyExpectations
      def expect_body_includes(fragment)
        with_request_dump_on_failure do
          case fragment
          when String
            expect(rest_response.body).to include(fragment)
          else
            raise ArgumentError, "expect_body_includes requires a String fragment, got #{fragment.class}"
          end
        end
      end

      def expect_body_matches(pattern)
        with_request_dump_on_failure do
          case pattern
          when String, Regexp
            expect(rest_response.body).to match(pattern)
          else
            raise ArgumentError, "expect_body_matches requires a String or Regexp pattern, got #{pattern.class}"
          end
        end
      end
    end
  end
end
