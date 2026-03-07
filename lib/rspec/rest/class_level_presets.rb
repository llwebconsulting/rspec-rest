# frozen_string_literal: true

module RSpec
  module Rest
    module ClassLevelPresets
      DEFAULT_PRESETS = {
        headers: {},
        query: {}
      }.freeze

      def with_headers(value)
        current_preset_scope[:headers].merge!(value)
      end

      def with_query(value)
        current_preset_scope[:query] ||= {}
        current_preset_scope[:query].merge!(value)
      end

      def with_auth(token)
        with_headers("Authorization" => "Bearer #{token}")
      end

      private

      def blank_presets
        deep_dup_presets(DEFAULT_PRESETS)
      end

      def rest_root_presets
        @rest_root_presets ||= blank_presets
      end

      def current_preset_scope
        stack = @rest_preset_stack || []
        return stack.last unless stack.empty?

        rest_root_presets
      end

      def current_request_presets
        presets = inherited_root_presets
        merge_presets!(presets, rest_root_presets)
        (@rest_preset_stack || []).each do |scope|
          merge_presets!(presets, scope)
        end
        presets
      end

      def inherited_root_presets
        return blank_presets unless superclass.respond_to?(:rest_root_presets, true)

        deep_dup_presets(superclass.send(:rest_root_presets))
      end

      def merge_presets!(base, override)
        base[:headers].merge!(override[:headers] || {})
        if override[:query] && !override[:query].empty?
          base[:query] ||= {}
          base[:query].merge!(override[:query])
        end
        base
      end

      def deep_dup(value)
        case value
        when Hash
          value.transform_values do |v|
            deep_dup(v)
          end
        when Array
          value.map { |v| deep_dup(v) }
        else
          begin
            value.dup
          rescue TypeError
            value
          end
        end
      end

      def deep_dup_presets(presets)
        {
          headers: deep_dup(presets[:headers] || {}),
          query: deep_dup(presets[:query] || {})
        }
      end
    end
  end
end
