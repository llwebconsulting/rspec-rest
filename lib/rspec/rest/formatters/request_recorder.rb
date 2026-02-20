# frozen_string_literal: true

require "json"
require_relative "../config"

module RSpec
  module Rest
    module Formatters
      class RequestRecorder
        def initialize(last_request:, redacted_headers: nil)
          @last_request = last_request || {}
          @redacted_headers = normalize_redacted_headers(redacted_headers || Config::DEFAULT_REDACT_HEADERS)
        end

        def to_curl
          [
            "curl",
            "-X #{method}",
            shell_escape(url),
            formatted_headers,
            formatted_body
          ].compact.join(" ")
        end

        private

        def method
          (@last_request[:method] || "GET").to_s.upcase
        end

        def url
          @last_request[:url] || @last_request[:path] || "http://example.org/"
        end

        def formatted_headers
          headers = @last_request[:headers]
          return nil if headers.nil? || headers.empty?

          headers.sort_by { |key, _| key.to_s.downcase }
                 .map { |key, value| %(-H #{shell_escape("#{key}: #{redacted_value(key, value)}")}) }
                 .join(" ")
        end

        def formatted_body
          body = @last_request[:body]
          return nil if body.nil?
          return nil if body.respond_to?(:empty?) && body.empty?

          value = body.is_a?(Hash) || body.is_a?(Array) ? JSON.dump(body) : body.to_s
          "-d #{shell_escape(value)}"
        end

        def redacted_value(key, value)
          return value unless @redacted_headers.include?(key.to_s.downcase)

          "[REDACTED]"
        end

        def normalize_redacted_headers(headers)
          headers.map { |header| header.to_s.downcase }
        end

        def shell_escape(value)
          "'#{value.to_s.gsub("'", %q('"'"'))}'"
        end
      end
    end
  end
end
