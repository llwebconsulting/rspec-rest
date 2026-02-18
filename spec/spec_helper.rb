# frozen_string_literal: true

require "rack"
require "json"
require "rspec/rest"
require_relative "support/rack_app"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
