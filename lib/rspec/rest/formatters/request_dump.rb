# frozen_string_literal: true

require "json"

module RSpec
  module Rest
    module Formatters
      class RequestDump
        def initialize(last_request:, response:)
          @last_request = last_request || {}
          @response = response
        end

        def format
          [
            "Request:",
            request_line,
            "Headers:",
            formatted_headers(@last_request[:headers]),
            "Body:",
            formatted_body(@last_request[:body]),
            "",
            "Response:",
            "Status: #{response_status}",
            "Headers:",
            formatted_headers(response_headers),
            "Body:",
            formatted_body(response_body)
          ].join("\n")
        end

        private

        def request_line
          method = @last_request[:method] || "UNKNOWN"
          path = @last_request[:path] || "(unknown path)"
          "#{method} #{path}"
        end

        def response_status
          @response&.status || "(unknown status)"
        end

        def response_headers
          @response&.headers || {}
        end

        def response_body
          @response&.body
        end

        def formatted_headers(headers)
          return "(none)" if headers.nil? || headers.empty?

          headers.sort_by { |key, _| key.to_s.downcase }
                 .map { |key, value| "#{key}: #{value}" }
                 .join("\n")
        end

        def formatted_body(body)
          return "(empty)" if body.nil? || (body.respond_to?(:empty?) && body.empty?)

          if body.is_a?(Hash) || body.is_a?(Array)
            return JSON.pretty_generate(body)
          end

          body_str = body.to_s
          parsed = parse_json(body_str)
          return JSON.pretty_generate(parsed) unless parsed.nil?

          body_str
        end

        def parse_json(value)
          JSON.parse(value)
        rescue JSON::ParserError
          nil
        end
      end
    end
  end
end
