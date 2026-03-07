# frozen_string_literal: true

module RSpec
  module Rest
    module ClassLevelContracts
      def contract(name, &definition)
        raise ArgumentError, "contract requires a block definition" unless block_given?

        rest_contracts_local[normalize_contract_name!(name)] = definition
      end

      def rest_contract_definition(name)
        rest_contracts[name.to_sym]
      end

      private

      def normalize_contract_name!(name)
        raise ArgumentError, "contract name cannot be nil" if name.nil?
        return name.to_sym if name.respond_to?(:to_sym)

        raise ArgumentError,
              "contract name must respond to #to_sym, got #{name.inspect} (#{name.class})"
      end

      def rest_contracts_local
        @rest_contracts_local ||= {}
      end

      def rest_contracts
        inherited = if superclass.respond_to?(:rest_contracts, true)
                      superclass.send(:rest_contracts)
                    else
                      {}
                    end
        inherited.merge(rest_contracts_local)
      end
    end
  end
end
