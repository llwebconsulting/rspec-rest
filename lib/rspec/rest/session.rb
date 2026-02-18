# frozen_string_literal: true

require "json"
require "rack/test"
require "rack/utils"

module RSpec
  module Rest
    class Session
      attr_reader :config, :last_request

      def initialize(config)
        @config = config
        validate_config!
        @rack_session = Rack::Test::Session.new(Rack::MockSession.new(config.app))
        @last_request = nil
      end

      def request(method:, path:, **options)
        resource_path = options[:resource_path]
        headers = options[:headers]
        query = options[:query]
        json = options[:json]
        params = options[:params]

        request_path = build_path(config.base_path, resource_path, path)
        request_path = append_query(request_path, query)

        request_headers = build_headers(headers, include_json_content_type: !json.nil?)
        rack_env_headers = build_rack_env_headers(request_headers)
        request_payload = build_payload(json: json, params: params)

        @last_request = {
          method: method.to_s.upcase,
          path: request_path,
          headers: request_headers,
          body: request_payload
        }

        @rack_session.public_send(method.to_sym, request_path, request_payload, rack_env_headers)
        response
      end

      def response
        Response.new(@rack_session.last_response)
      end

      private

      def validate_config!
        return unless config.app.nil?

        raise MissingAppError, "Config#app is required to initialize RSpec::Rest::Session"
      end

      def build_headers(request_headers, include_json_content_type:)
        headers = config.base_headers.dup

        if config.default_format == :json
          headers["Accept"] ||= "application/json"
        end

        headers.merge!(request_headers || {})
        if include_json_content_type
          headers["Content-Type"] ||= "application/json"
        end

        headers
      end

      def build_payload(json:, params:)
        return JSON.dump(json) unless json.nil?

        params || {}
      end

      def build_rack_env_headers(headers)
        headers.transform_keys { |key| normalize_header_key(key) }
      end

      def normalize_header_key(key)
        key_str = key.to_s
        return key_str if key_str.start_with?("HTTP_", "CONTENT_TYPE", "CONTENT_LENGTH", "rack.")
        return "CONTENT_TYPE" if key_str.casecmp("Content-Type").zero?
        return "CONTENT_LENGTH" if key_str.casecmp("Content-Length").zero?

        "HTTP_#{key_str.tr('-', '_').upcase}"
      end

      def append_query(path, query)
        return path if query.nil? || query.empty?

        "#{path}?#{Rack::Utils.build_query(query)}"
      end

      def build_path(base_path, resource_path, endpoint_path)
        segments = [base_path, resource_path, endpoint_path].compact.map(&:to_s)
        normalized = segments.map { |segment| segment.gsub(%r{\A/+|/+\z}, "") }.reject(&:empty?)
        "/#{normalized.join('/')}"
      end
    end
  end
end
