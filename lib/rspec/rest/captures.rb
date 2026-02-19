# frozen_string_literal: true

require_relative "errors"
require_relative "json_selector"

module RSpec
  module Rest
    module Captures
      def capture(name, selector)
        captures[name.to_sym] = JsonSelector.extract(rest_response.json, selector)
      end

      def get(name)
        key = name.to_sym
        return captures[key] if captures.key?(key)

        raise MissingCaptureError, "No captured value found for #{key.inspect} in this example."
      end

      private

      def captures
        @captures ||= {}
      end
    end
  end
end
