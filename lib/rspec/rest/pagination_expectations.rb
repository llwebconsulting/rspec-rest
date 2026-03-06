# frozen_string_literal: true

module RSpec
  module Rest
    module PaginationExpectations
      def expect_page_size(size, selector: "$")
        with_request_dump_on_failure do
          collection = extract_collection(selector)
          expect(collection.size).to eq(size)
          collection
        end
      end

      def expect_max_page_size(max, selector: "$")
        with_request_dump_on_failure do
          collection = extract_collection(selector)
          expect(collection.size).to be <= max
          collection
        end
      end

      def expect_ids_in_order(ids, selector: "$[*].id")
        with_request_dump_on_failure do
          actual_ids = extract_id_list(selector)
          expect(actual_ids).to eq(ids)
          actual_ids
        end
      end

      private

      def extract_collection(selector)
        payload = rest_response.json
        selected = selector == "$" ? payload : JsonSelector.extract(payload, selector)

        unless selected.is_a?(Array)
          raise ::RSpec::Expectations::ExpectationNotMetError,
                "Expected selector #{selector.inspect} to resolve to an Array, got #{selected.class}."
        end

        selected
      end

      def extract_id_list(selector)
        wildcard_match = /\A\$\[\*\]\.([a-zA-Z_][a-zA-Z0-9_]*)\z/.match(selector.to_s)
        return JsonSelector.extract(rest_response.json, selector) unless wildcard_match

        key = wildcard_match[1]
        extract_collection("$").map.with_index do |item, index|
          unless item.is_a?(Hash) && item.key?(key)
            raise MissingJsonPathError,
                  "Selector #{selector.inspect} did not match element #{index} for key #{key.inspect}."
          end

          item[key]
        end
      end
    end
  end
end
