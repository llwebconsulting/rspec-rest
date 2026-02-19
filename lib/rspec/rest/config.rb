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

      attr_accessor :app, :base_path, :base_headers, :default_format, :redact_headers

      def initialize(app: nil, base_path: nil, base_headers: nil, default_format: nil, redact_headers: nil)
        @app = app
        @base_path = base_path || ""
        @base_headers = (base_headers || {}).dup
        @default_format = default_format
        @redact_headers = (redact_headers || DEFAULT_REDACT_HEADERS).dup
      end
    end
  end
end
