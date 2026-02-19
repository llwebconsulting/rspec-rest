# frozen_string_literal: true

require_relative "config"
require_relative "captures"
require_relative "errors"
require_relative "expectations"
require_relative "json_selector"
require_relative "session"
module RSpec
  module Rest
    module DSL
      HTTP_METHODS = ::RSpec::Rest::Session::SUPPORTED_HTTP_METHODS

      class ApiConfigBuilder
        def initialize(config)
          @config = Config.new(
            app: config.app,
            base_path: config.base_path,
            base_headers: config.base_headers,
            default_format: config.default_format
          )
        end

        def app(value)
          @config.app = value
        end

        def base_path(value)
          @config.base_path = value
        end

        def base_headers(value)
          @config.base_headers = value.dup
        end

        def default_format(value)
          @config.default_format = value
        end

        def to_config
          @config
        end
      end

      module ClassMethods
        def api(&)
          builder = ApiConfigBuilder.new(rest_config)
          builder.instance_eval(&)
          @rest_config = builder.to_config
        end

        def resource(path, &)
          @rest_resource_stack ||= []
          @rest_resource_stack << path
          class_eval(&)
        ensure
          @rest_resource_stack.pop
        end

        HTTP_METHODS.each do |method|
          define_method(method) do |path, &block|
            resource_path = current_resource_path
            it("#{method.to_s.upcase} #{path}") do
              start_rest_request(method: method, path: path, resource_path: resource_path)
              instance_eval(&block) if block
              execute_rest_request_if_pending
            end
          end
        end

        def rest_config
          return @rest_config if instance_variable_defined?(:@rest_config)

          parent = superclass.respond_to?(:rest_config) ? superclass.rest_config : Config.new
          Config.new(
            app: parent.app,
            base_path: parent.base_path,
            base_headers: parent.base_headers,
            default_format: parent.default_format
          )
        end

        private

        def current_resource_path
          stack = @rest_resource_stack || []
          return nil if stack.empty?

          first_had_leading_slash = stack.first.to_s.start_with?("/")
          normalized_segments = stack.map do |segment|
            segment.to_s.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
          end.reject(&:empty?)

          path = normalized_segments.join("/")
          first_had_leading_slash && !path.empty? ? "/#{path}" : path
        end
      end

      module InstanceMethods
        include Captures
        include Expectations

        def rest_session
          @rest_session ||= Session.new(self.class.rest_config)
        end

        def rest_response
          ensure_request_context!
          execute_rest_request_if_pending
          @rest_response
        end

        def last_request
          ensure_request_context!
          execute_rest_request_if_pending
          rest_session.last_request
        end

        def header(key, value)
          rest_request_state[:headers][key] = value
        end

        def headers(value)
          rest_request_state[:headers].merge!(value)
        end

        def query(value)
          rest_request_state[:query] ||= {}
          rest_request_state[:query].merge!(value)
        end

        def json(value)
          rest_request_state[:json] = value
        end

        def path_params(value)
          rest_request_state[:path_params].merge!(value.transform_keys(&:to_s))
        end

        private

        def start_rest_request(method:, path:, resource_path:)
          @rest_request_state = {
            method: method,
            path: path,
            resource_path: resource_path,
            headers: {},
            query: nil,
            json: nil,
            path_params: {}
          }
          @rest_response = nil
          @rest_request_executed = false
        end

        def execute_rest_request_if_pending
          ensure_request_context!
          return if @rest_request_executed

          execute_rest_request
        end

        def execute_rest_request
          request_path = apply_path_params(
            rest_request_state[:path],
            rest_request_state[:path_params]
          )
          request_resource_path = apply_path_params(
            rest_request_state[:resource_path],
            rest_request_state[:path_params]
          )

          @rest_response = rest_session.request(
            method: rest_request_state[:method],
            path: request_path,
            resource_path: request_resource_path,
            headers: rest_request_state[:headers],
            query: rest_request_state[:query],
            json: rest_request_state[:json]
          )
          @rest_request_executed = true
        end

        def rest_request_state
          unless defined?(@rest_request_state) && @rest_request_state
            raise MissingRequestContextError,
                  "REST request context is not initialized. Call this inside a verb block (get/post/put/patch/delete)."
          end

          @rest_request_state
        end

        def ensure_request_context!
          return if defined?(@rest_request_state) && @rest_request_state

          raise MissingRequestContextError,
                "No active REST request context. Call this inside a verb block (get/post/put/patch/delete)."
        end

        def apply_path_params(path, params)
          rendered = params.reduce(path.to_s) do |current, (key, value)|
            current.gsub("{#{key}}", value.to_s)
          end

          # Detect any placeholders that were not replaced and provide a clear error
          missing_placeholders = rendered.scan(/\{([^}]+)\}/).flatten.uniq
          unless missing_placeholders.empty?
            raise ArgumentError,
                  "Missing path params for placeholders: #{missing_placeholders.join(', ')} in path '#{path}'"
          end

          rendered
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
        base.include(InstanceMethods)
      end
    end
  end
end
