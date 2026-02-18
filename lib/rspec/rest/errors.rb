# frozen_string_literal: true

module RSpec
  module Rest
    class Error < StandardError; end

    class MissingAppError < Error; end

    class InvalidJsonError < Error; end
  end
end
