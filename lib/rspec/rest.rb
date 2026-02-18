# frozen_string_literal: true

require_relative "rest/version"
require_relative "rest/errors"
require_relative "rest/config"
require_relative "rest/response"
require_relative "rest/session"
require_relative "rest/dsl"

module RSpec
  module Rest
    def self.included(base)
      base.include(DSL)
    end
  end
end
