# frozen_string_literal: true

module RSpec
  module Rest
    class ContractWithMatcher
      def initialize(name:, contract_matcher:, overrides_matcher:)
        @name = name
        @contract_matcher = contract_matcher
        @overrides_matcher = overrides_matcher
      end

      def matches?(actual)
        @contract_matched = @contract_matcher.matches?(actual)
        return false unless @contract_matched

        @overrides_matcher.matches?(actual)
      end

      def failure_message
        return @contract_matcher.failure_message unless @contract_matched

        "Contract #{@name.inspect} override assertion failed: #{@overrides_matcher.failure_message}"
      end

      def failure_message_when_negated
        "Expected value not to match contract #{@name.inspect} with overrides"
      end

      def description
        "match contract #{@name.inspect} with overrides"
      end
    end
  end
end
