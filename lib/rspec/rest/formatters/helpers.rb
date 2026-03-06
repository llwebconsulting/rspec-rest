# frozen_string_literal: true

module RSpec
  module Rest
    module Formatters
      module Helpers
        private

        def sanitize_for_json(value)
          case value
          when Hash
            value.transform_values { |inner| sanitize_for_json(inner) }
          when Array
            value.map { |inner| sanitize_for_json(inner) }
          else
            value.respond_to?(:to_str) ? value.to_str : value.to_s
          end
        end

        def normalize_redacted_headers(headers)
          headers.map { |header| header.to_s.downcase }
        end
      end
    end
  end
end
