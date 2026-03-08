# frozen_string_literal: true

module RSpec
  module Rest
    module PathComposer
      module_function

      def compose(base_path:, resource_path:, endpoint_path:)
        segments = [base_path, resource_path, endpoint_path].compact.map(&:to_s)
        normalized = segments.map { |segment| segment.gsub(%r{\A/+|/+\z}, "") }.reject(&:empty?)
        "/#{normalized.join('/')}"
      end
    end
  end
end
