# frozen_string_literal: true

require_relative "contract_matcher"

module RSpec
  module Rest
    module ContractExpectations
      def contract(name = nil, &)
        if block_given?
          raise ArgumentError,
                "contract(:name) lookup does not accept a block in examples. " \
                "Define contracts at the example group level with `contract(:name) { ... }`."
        end

        contract_matcher_for(name, lookup_name: :contract)
      end

      def expect_json_contract(name)
        Deprecation.warn(
          key: :expect_json_contract,
          message: "`expect_json_contract` is deprecated and will be removed in 1.0. " \
                   "Use `contract(:name)` instead."
        )

        contract_matcher_for(name, lookup_name: :expect_json_contract)
      end

      private

      def contract_matcher_for(name, lookup_name:)
        contract_name = normalize_contract_name(name)
        return unknown_contract_matcher(name_error_message(name, lookup_name: lookup_name)) if contract_name.nil?

        definition = self.class.rest_contract_definition(contract_name)
        return ContractMatcher.new(name: contract_name, definition: definition, context: self) unless definition.nil?

        available = self.class.send(:rest_contracts).keys.map(&:inspect).sort
        message = "Unknown contract #{contract_name.inspect}. Available contracts: [#{available.join(', ')}]"
        unknown_contract_matcher(message)
      end

      def normalize_contract_name(name)
        return nil if name.nil? || !name.respond_to?(:to_sym)

        name.to_sym
      end

      def unknown_contract_matcher(message)
        UnknownContractMatcher.new(message)
      end

      def name_error_message(name, lookup_name:)
        lookup_hint = lookup_name == :expect_json_contract ? "expect_json_contract" : "contract lookup"
        "Invalid contract name #{name.inspect} (#{name.class}). " \
          "#{lookup_hint} requires a contract name that responds to #to_sym."
      end
    end
  end
end
