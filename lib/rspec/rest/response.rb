# frozen_string_literal: true

require "json"

module RSpec
  module Rest
    class Response
      attr_reader :raw_response

      def initialize(raw_response)
        @raw_response = raw_response
      end

      def status
        raw_response.status
      end

      def headers
        raw_response.headers
      end

      def body
        raw_response.body.to_s
      end

      def json
        @json ||= JSON.parse(body)
      rescue JSON::ParserError => e
        snippet = body[0, 200]
        raise InvalidJsonError, "Failed to parse JSON response: #{e.message}. Body snippet: #{snippet.inspect}"
      end
    end
  end
end
