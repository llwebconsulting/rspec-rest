# frozen_string_literal: true

require_relative "config"
require_relative "captures"
require_relative "class_level_contracts"
require_relative "class_level_presets"
require_relative "errors"
require_relative "expectations"
require_relative "json_selector"
require_relative "path_composer"
require_relative "request_builders"
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
            default_format: config.default_format,
            redact_headers: config.redact_headers,
            base_url: config.base_url
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

        def redact_headers(value)
          @config.redact_headers = value.dup
        end

        def base_url(value)
          @config.base_url = value
        end

        def to_config
          @config
        end
      end

      module RouteNamingSupport
        private

        def build_example_name(method:, path:, resource_path:, description:)
          route = compose_route_for_example(resource_path: resource_path, endpoint_path: path)
          base = "#{method.to_s.upcase} #{route}"
          normalized_description = description.to_s.strip
          return base if normalized_description.empty?

          "#{base} - #{normalized_description}"
        end

        def compose_route_for_example(resource_path:, endpoint_path:)
          PathComposer.compose(
            base_path: rest_config.base_path,
            resource_path: resource_path,
            endpoint_path: endpoint_path
          )
        end

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

      module DescriptionArgumentSupport
        private

        def warn_on_deprecated_positional_description(_method)
          Deprecation.warn(
            key: :verb_positional_description,
            message: "Positional request descriptions (for example: get(path, description)) are deprecated and " \
                     "will be removed in 1.0. Use keyword descriptions " \
                     "(for example: get(path, description: \"...\")). " \
                     "This avoids RuboCop Rails/HttpPositionalArguments false-positives."
          )
        end

        def resolve_description_options(method:, positional_description:, keyword_description:)
          if !positional_description.nil? && !keyword_description.nil?
            raise ArgumentError,
                  "#{method}(...) received both positional and keyword descriptions. " \
                  "Use only `description:`."
          end

          {
            description: keyword_description.nil? ? positional_description : keyword_description,
            using_positional_description: !positional_description.nil? && keyword_description.nil?
          }
        end
      end

      module PathArgumentSupport
        private

        def warn_on_deprecated_positional_path(_method)
          Deprecation.warn(
            key: :verb_positional_path,
            message: "Positional request paths (for example: get(\"/users\")) are deprecated and will be " \
                     "removed in 1.0. Use keyword paths instead (for example: get(path: \"/users\")). " \
                     "This avoids RuboCop Rails/HttpPositionalArguments false-positives."
          )
        end

        def resolve_path_options(method:, positional_path:, keyword_path:)
          if !positional_path.nil? && !keyword_path.nil?
            raise ArgumentError,
                  "#{method}(...) received both positional and keyword paths. Use only `path:`."
          end

          effective_path = keyword_path.nil? ? positional_path : keyword_path
          if effective_path.nil?
            raise ArgumentError,
                  "#{method}(...) requires a request path. Pass it as `path:` (preferred) " \
                  "or as the first positional argument."
          end

          {
            path: effective_path,
            using_positional_path: !positional_path.nil? && keyword_path.nil?
          }
        end
      end

      module ClassMethods
        include ClassLevelContracts
        include ClassLevelPresets
        include RouteNamingSupport
        include DescriptionArgumentSupport
        include PathArgumentSupport

        def api(&)
          builder = ApiConfigBuilder.new(rest_config)
          builder.instance_eval(&)
          @rest_config = builder.to_config
        end

        def resource(path, &)
          @rest_resource_stack ||= []
          @rest_preset_stack ||= []
          @rest_resource_stack << path
          @rest_preset_stack << blank_presets
          class_eval(&)
        ensure
          @rest_preset_stack.pop
          @rest_resource_stack.pop
        end

        HTTP_METHODS.each do |method|
          define_method(method) do |positional_path = nil, positional_description = nil, path: nil,
                                    description: nil, &block|
            path_options, description_options = resolve_verb_options(
              method, positional_path, path, positional_description, description
            )
            resource_path = current_resource_path
            request_presets = deep_dup_presets(current_request_presets)
            example_name = build_example_name(
              method: method,
              path: path_options[:path],
              resource_path: resource_path,
              description: description_options[:description]
            )
            it(example_name) do
              start_rest_request(
                method: method,
                path: path_options[:path],
                resource_path: resource_path,
                presets: request_presets
              )
              instance_eval(&block) if block
              self.class.send(:emit_verb_deprecation_warnings, method, path_options, description_options)
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
            default_format: parent.default_format,
            redact_headers: parent.redact_headers,
            base_url: parent.base_url
          )
        end

        private

        def emit_verb_deprecation_warnings(method, path_options, description_options)
          emit_positional_path_warning(method, path_options)
          emit_positional_description_warning(method, description_options)
        end

        def emit_positional_path_warning(method, path_options)
          return unless path_options[:using_positional_path]

          send(:warn_on_deprecated_positional_path, method)
        end

        def emit_positional_description_warning(method, description_options)
          return unless description_options[:using_positional_description]

          send(:warn_on_deprecated_positional_description, method)
        end

        def resolve_verb_path_options(method, positional_path, path)
          resolve_path_options(
            method: method,
            positional_path: positional_path,
            keyword_path: path
          )
        end

        def resolve_verb_description_options(method, positional_description, description)
          resolve_description_options(
            method: method,
            positional_description: positional_description,
            keyword_description: description
          )
        end

        def resolve_verb_options(method, positional_path, path, positional_description, description)
          [
            resolve_verb_path_options(method, positional_path, path),
            resolve_verb_description_options(method, positional_description, description)
          ]
        end
      end

      module InstanceMethods
        include Captures
        include Expectations
        include RequestBuilders

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

        private

        def start_rest_request(method:, path:, resource_path:, presets: nil)
          effective_presets = presets || ClassLevelPresets::DEFAULT_PRESETS
          preset_headers = (effective_presets[:headers] || {}).dup
          preset_query = (effective_presets[:query] || {}).dup

          @rest_request_state = {
            method: method,
            path: path,
            resource_path: resource_path,
            headers: preset_headers,
            query: preset_query.empty? ? nil : preset_query,
            json: nil,
            multipart: false,
            params: nil,
            path_params: {}
          }
          @rest_response = nil
          @rest_request_executed = false
        end

        def execute_rest_request_if_pending
          ensure_request_context!
          return if @rest_request_executed

          @rest_request_executed = true
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
          if rest_request_state[:multipart] && !rest_request_state[:json].nil?
            raise ArgumentError, "Cannot use json(...) with multipart! requests. Use file(...) and params."
          end

          @rest_response = rest_session.request(
            method: rest_request_state[:method],
            path: request_path,
            resource_path: request_resource_path,
            headers: rest_request_state[:headers],
            query: rest_request_state[:query],
            json: rest_request_state[:json],
            params: rest_request_state[:params]
          )
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
