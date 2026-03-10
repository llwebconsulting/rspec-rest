# frozen_string_literal: true

require "json"
require_relative "../config"
require_relative "helpers"

module RSpec
  module Rest
    module Formatters
      class RequestRecorder
        include Helpers

        AUTH_TOKEN_ENV_VAR = "API_AUTH_TOKEN"
        AUTH_HEADER_KEYS = %w[
          authorization
          proxy-authorization
          x-api-key
          x-auth-token
        ].freeze
        AUTH_SCHEME_HEADER_KEYS = %w[
          authorization
          proxy-authorization
        ].freeze

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
                 .map { |key, value| format_header_option(key, redacted_value(key, value)) }
                 .join(" ")
        end

        def formatted_body
          body = @last_request[:body]
          return nil if body.nil?
          return nil if body.respond_to?(:empty?) && body.empty?

          value = serialize_body(body)
          "-d #{shell_escape(value)}"
        end

        def serialize_body(body)
          return body.to_s unless body.is_a?(Hash) || body.is_a?(Array)

          JSON.dump(body)
        rescue TypeError
          JSON.dump(sanitize_for_json(body))
        end

        def redacted_value(key, value)
          return value unless @redacted_headers.include?(key.to_s.downcase)
          return auth_header_placeholder(key, value) if auth_header?(key)

          "[REDACTED]"
        end

        def auth_header?(key)
          AUTH_HEADER_KEYS.include?(key.to_s.downcase)
        end

        def auth_header_placeholder(key, value)
          value_string = value.to_s
          if AUTH_SCHEME_HEADER_KEYS.include?(key.to_s.downcase)
            scheme_match = value_string.match(/\A([A-Za-z][A-Za-z0-9._-]*)\s+/)
            return "#{scheme_match[1]} $#{AUTH_TOKEN_ENV_VAR}" if scheme_match
          end

          "$#{AUTH_TOKEN_ENV_VAR}"
        end

        def format_header_option(key, value)
          header = "#{key}: #{value}"
          return %(-H #{shell_escape_with_env_expansion(header)}) if value.to_s.include?("$#{AUTH_TOKEN_ENV_VAR}")

          %(-H #{shell_escape(header)})
        end

        def shell_escape(value)
          "'#{value.to_s.gsub("'", %q('"'"'))}'"
        end

        def shell_escape_with_env_expansion(value)
          escaped = value.to_s.gsub("\\", "\\\\").gsub('"', '\"').gsub("`", "\\`")
          "\"#{escaped}\""
        end
      end
    end
  end
end
