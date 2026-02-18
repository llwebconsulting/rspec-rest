# frozen_string_literal: true

module RSpec
  module Rest
    class Config
      attr_accessor :app, :base_path, :base_headers, :default_format

      def initialize(app: nil, base_path: nil, base_headers: nil, default_format: nil)
        @app = app
        @base_path = base_path || ""
        @base_headers = (base_headers || {}).dup
        @default_format = default_format
      end
    end
  end
end
