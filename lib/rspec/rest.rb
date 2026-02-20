# frozen_string_literal: true

require_relative "rest/version"
require_relative "rest/errors"
require_relative "rest/config"
require_relative "rest/response"
require_relative "rest/session"
require_relative "rest/json_selector"
require_relative "rest/formatters/request_recorder"
require_relative "rest/dsl"

module RSpec
  module Rest
    def self.included(base)
      base.include(DSL)
    end
  end
end
