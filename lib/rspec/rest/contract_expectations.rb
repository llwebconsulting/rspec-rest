# frozen_string_literal: true

require_relative "contract_matcher"

module RSpec
  module Rest
    module ContractExpectations
      def expect_json_contract(name)
        contract_name = name.to_sym
        definition = self.class.rest_contract_definition(contract_name)
        return ContractMatcher.new(name: contract_name, definition: definition, context: self) unless definition.nil?

        available = self.class.send(:rest_contracts).keys.map(&:inspect).sort
        message = "Unknown contract #{contract_name.inspect}. Available contracts: [#{available.join(', ')}]"
        UnknownContractMatcher.new(message)
      end
    end
  end
end
