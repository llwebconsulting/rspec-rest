# frozen_string_literal: true

module RSpec
  module Rest
    module ClassLevelPresets
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
        { headers: {}, query: {} }
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

      def deep_dup_presets(presets)
        {
          headers: (presets[:headers] || {}).dup,
          query: (presets[:query] || {}).dup
        }
      end
    end
  end
end
