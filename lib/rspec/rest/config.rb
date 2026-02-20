# frozen_string_literal: true

module RSpec
  module Rest
    class Config
      DEFAULT_REDACT_HEADERS = %w[
        Authorization
        Proxy-Authorization
        Cookie
        Set-Cookie
        X-Api-Key
        X-Auth-Token
      ].freeze

      attr_accessor :app, :base_path, :base_headers, :default_format, :redact_headers, :base_url

      def initialize(**options)
        @app = options[:app]
        @base_path = options[:base_path] || ""
        @base_headers = (options[:base_headers] || {}).dup
        @default_format = options[:default_format]
        @redact_headers = (options[:redact_headers] || DEFAULT_REDACT_HEADERS).dup
        @base_url = options[:base_url] || "http://example.org"
      end
    end
  end
end
