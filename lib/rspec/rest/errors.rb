# frozen_string_literal: true

module RSpec
  module Rest
    class Error < StandardError; end

    class MissingAppError < Error; end

    class InvalidJsonError < Error; end

    class UnsupportedHttpMethodError < Error; end

    class MissingRequestContextError < Error; end

    class InvalidJsonSelectorError < Error; end

    class MissingJsonPathError < Error; end

    class MissingCaptureError < Error; end
  end
end
