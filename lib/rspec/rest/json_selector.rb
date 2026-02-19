# frozen_string_literal: true

module RSpec
  module Rest
    class JsonSelector
      TOKEN_PATTERN = /
        (?:
          \.([a-zA-Z_][a-zA-Z0-9_]*)
        )|
        (?:
          \[(\d+)\]
        )
      /x

      class << self
        def extract(json, selector)
          tokens = parse(selector)
          current = json

          tokens.each do |token|
            current = dig(current, token, selector)
          end

          current
        end

        private

        def parse(selector)
          selector_str = selector.to_s
          unless selector_str.start_with?("$")
            raise InvalidJsonSelectorError, "Invalid selector #{selector.inspect}. Selector must start with '$'."
          end

          remaining = selector_str[1..]
          tokens = []

          until remaining.empty?
            match = TOKEN_PATTERN.match(remaining)
            if match.nil? || match.begin(0) != 0
              raise InvalidJsonSelectorError,
                    "Invalid selector #{selector.inspect}. Supported forms include '$.a.b' and '$.items[0].id'."
            end

            tokens << if match[1]
                        [:key, match[1]]
                      else
                        [:index, match[2].to_i]
                      end

            remaining = remaining[match[0].length..]
          end

          tokens
        end

        def dig(value, token, selector)
          type, key = token

          case type
          when :key
            unless value.is_a?(Hash) && value.key?(key)
              raise MissingJsonPathError, "Selector #{selector.inspect} did not match path segment #{key.inspect}."
            end

            value[key]
          when :index
            unless value.is_a?(Array) && key < value.length
              raise MissingJsonPathError, "Selector #{selector.inspect} did not match array index #{key}."
            end

            value[key]
          end
        end
      end
    end
  end
end
