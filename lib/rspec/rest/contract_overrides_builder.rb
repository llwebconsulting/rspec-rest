# frozen_string_literal: true

module RSpec
  module Rest
    class ContractOverridesBuilder
      def initialize(context:)
        @context = context
      end

      def normalize!(overrides, keyword_overrides)
        unless keyword_overrides.empty?
          raise ArgumentError, "contract_with received both positional Hash and keyword overrides" unless overrides.nil?

          return keyword_overrides
        end

        return {} if overrides.nil?
        return overrides if overrides.is_a?(Hash)

        raise ArgumentError,
              "contract_with requires overrides to be a Hash or keyword arguments, got #{overrides.class}"
      end

      def key_tree_for(contract_value)
        hash = extract_contract_hash(contract_value)
        return nil if hash.nil?

        hash.each_with_object({}) do |(key, nested), memo|
          memo[key.to_s] = key_tree_for(nested)
        end
      end

      def validate_keys(key_tree, overrides, path = [])
        overrides.each do |key, value|
          key_name = key.to_s
          unless key_tree.key?(key_name)
            available_keys = key_tree.keys.sort
            location = path.empty? ? "contract root" : "$.#{path.join('.')}"
            return "Unknown override key #{key_name.inspect} at #{location}. " \
                   "Available keys: [#{available_keys.map(&:inspect).join(', ')}]"
          end

          next unless value.is_a?(Hash)

          nested_tree = key_tree[key_name]
          if nested_tree.nil?
            location = (path + [key_name]).join(".")
            return "Override key #{key_name.inspect} at $.#{location} does not support nested overrides."
          end

          nested_error = validate_keys(nested_tree, value, path + [key_name])
          return nested_error unless nested_error.nil?
        end

        nil
      end

      def build_matcher(overrides)
        @context.hash_including(
          overrides.each_with_object({}) do |(key, value), memo|
            memo[key.to_s] = value.is_a?(Hash) ? build_matcher(value) : value
          end
        )
      end

      private

      def extract_contract_hash(value)
        return value if value.is_a?(Hash)

        return nil unless value.respond_to?(:matcher_name) && value.respond_to?(:expecteds)

        matcher_name = value.matcher_name
        return nil unless matcher_name == :a_hash_including

        expecteds = value.expecteds
        return nil unless expecteds.is_a?(Array) && expecteds.first.is_a?(Hash)

        expecteds.first
      end
    end
  end
end
