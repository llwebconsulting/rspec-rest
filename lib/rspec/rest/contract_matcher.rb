# frozen_string_literal: true

module RSpec
  module Rest
    class ContractMatcher
      def initialize(name:, definition:, context:)
        @name = name
        @definition = definition
        @context = context
      end

      def matches?(actual)
        @actual = actual
        matcher.matches?(actual)
      end

      def failure_message
        "Contract #{@name.inspect} failed: #{matcher.failure_message}"
      end

      def failure_message_when_negated
        "Contract #{@name.inspect} failed: #{matcher.failure_message_when_negated}"
      end

      def description
        "match contract #{@name.inspect}"
      end

      private

      def matcher
        @matcher ||= begin
          value = @context.instance_exec(&@definition)
          value.respond_to?(:matches?) ? value : @context.eq(value)
        end
      end
    end
  end
end
