# frozen_string_literal: true

require_relative "contract_matcher"
require_relative "contract_overrides_builder"
require_relative "contract_with_matcher"

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

      def contract_with(name, overrides = nil, **keyword_overrides)
        overrides_builder = ContractOverridesBuilder.new(context: self)
        resolved_overrides = overrides_builder.normalize!(overrides, keyword_overrides)
        contract_name = normalize_contract_name(name)
        return unknown_contract_matcher(name_error_message(name, lookup_name: :contract_with)) if contract_name.nil?

        definition = self.class.rest_contract_definition(contract_name)
        if definition.nil?
          available = self.class.send(:rest_contracts).keys.map(&:inspect).sort
          message = "Unknown contract #{contract_name.inspect}. Available contracts: [#{available.join(', ')}]"
          return unknown_contract_matcher(message)
        end

        definition_for_matcher = definition

        if resolved_overrides.any?
          base_contract_value = instance_exec(&definition)
          key_tree = overrides_builder.key_tree_for(base_contract_value)
          if key_tree.nil?
            return unknown_contract_matcher(
              "Contract #{contract_name.inspect} does not declare hash keys, so overrides cannot be applied."
            )
          end

          validation_error = overrides_builder.validate_keys(key_tree, resolved_overrides)
          return unknown_contract_matcher(validation_error) unless validation_error.nil?

          # Reuse the already-evaluated contract value inside the matcher so the
          # contract definition is executed at most once per `contract_with` call.
          definition_for_matcher = proc { base_contract_value }
        end

        ContractWithMatcher.new(
          name: contract_name,
          contract_matcher: ContractMatcher.new(name: contract_name, definition: definition_for_matcher, context: self),
          overrides_matcher: overrides_builder.build_matcher(resolved_overrides)
        )
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
        lookup_hint = case lookup_name
                      when :expect_json_contract
                        "expect_json_contract"
                      when :contract_with
                        "contract_with(:name, ...)"
                      else
                        "contract(:name)"
                      end
        "Invalid contract name #{name.inspect} (#{name.class}). " \
          "#{lookup_hint} requires a contract name that responds to #to_sym."
      end
    end
  end
end
