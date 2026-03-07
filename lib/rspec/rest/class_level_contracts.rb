# frozen_string_literal: true

module RSpec
  module Rest
    module ClassLevelContracts
      def contract(name, &definition)
        raise ArgumentError, "contract requires a block definition" unless block_given?

        rest_contracts_local[name.to_sym] = definition
      end

      def rest_contract_definition(name)
        rest_contracts[name.to_sym]
      end

      private

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
